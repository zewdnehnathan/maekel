import {
  AppError,
  createPool,
  createService,
  databaseUrl,
  env,
  envInt,
  listen,
  migrate,
  requireAuth,
  requireRole,
  signAccessToken,
} from '@maekel/shared';
import { z } from 'zod';

const port = envInt('IDENTITY_PORT', 3001);
const mockOtp = env('MOCK_OTP_CODE', '828694');
const pool = createPool(databaseUrl('maekel_identity'));

/** Comma-separated E.164 phones that bootstrap as real admins. */
const adminPhones = parseAdminPhones(
  (process.env.ADMIN_PHONES ?? '').trim() || '+251999999999',
);

const defaultUserRoles = [
  'ride_passenger',
  'food_customer',
  'market_buyer',
  'market_seller',
  'events_attendee',
  'events_organizer',
] as const;

const staffRoles = [
  'platform_admin',
  'market_moderator',
  'market_ops',
  'food_ops',
  'food_merchant',
  'food_delivery_merchant',
  'food_rider',
  'ride_ops',
  'events_ops',
] as const;
const grantableRoles = [
  'platform_admin',
  'market_moderator',
  'market_ops',
  'food_ops',
  'food_merchant',
  'food_delivery_merchant',
  'food_rider',
  'ride_ops',
  'events_ops',
] as const;

async function boot() {
  await migrate(pool, [
    `CREATE TABLE IF NOT EXISTS users (
      id UUID PRIMARY KEY,
      phone_e164 TEXT NOT NULL UNIQUE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
    `CREATE TABLE IF NOT EXISTS otp_challenges (
      id UUID PRIMARY KEY,
      phone_e164 TEXT NOT NULL,
      code TEXT NOT NULL,
      expires_at TIMESTAMPTZ NOT NULL,
      consumed_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
    `CREATE TABLE IF NOT EXISTS role_grants (
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      role TEXT NOT NULL,
      PRIMARY KEY (user_id, role)
    )`,
    `ALTER TABLE users ADD COLUMN IF NOT EXISTS account_status TEXT NOT NULL DEFAULT 'active'`,
    `ALTER TABLE users ADD COLUMN IF NOT EXISTS warn_message TEXT`,
    `ALTER TABLE users ADD COLUMN IF NOT EXISTS moderation_note TEXT`,
    `ALTER TABLE users ADD COLUMN IF NOT EXISTS moderated_at TIMESTAMPTZ`,
    `CREATE TABLE IF NOT EXISTS refresh_tokens (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      token_hash TEXT NOT NULL UNIQUE,
      expires_at TIMESTAMPTZ NOT NULL,
      revoked_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
  ]);

  await reconcileStaffRoles();

  const app = await createService({ name: 'identity-service', port });

  app.post('/v1/auth/otp/request', async (req) => {
    const body = z
      .object({ phone: z.string().min(9) })
      .parse(req.body ?? {});
    const phone = normalizePhone(body.phone);
    const id = crypto.randomUUID();
    await pool.query(
      `INSERT INTO otp_challenges (id, phone_e164, code, expires_at)
       VALUES ($1, $2, $3, NOW() + INTERVAL '10 minutes')`,
      [id, phone, mockOtp],
    );
    return {
      ok: true,
      phone,
      // Dev only — remove when real SMS is wired.
      debugCode: mockOtp,
    };
  });

  app.post('/v1/auth/otp/verify', async (req) => {
    const body = z
      .object({
        phone: z.string().min(9),
        code: z.string().min(4),
      })
      .parse(req.body ?? {});
    const phone = normalizePhone(body.phone);

    const challenge = await pool.query(
      `SELECT id FROM otp_challenges
       WHERE phone_e164 = $1
         AND code = $2
         AND consumed_at IS NULL
         AND expires_at > NOW()
       ORDER BY created_at DESC
       LIMIT 1`,
      [phone, body.code],
    );
    if (challenge.rowCount === 0) {
      throw new AppError('Invalid or expired OTP', 401, 'invalid_otp');
    }

    await pool.query(
      `UPDATE otp_challenges SET consumed_at = NOW() WHERE id = $1`,
      [challenge.rows[0].id],
    );

    let user = await pool.query(
      `SELECT id, phone_e164, account_status, warn_message
       FROM users WHERE phone_e164 = $1`,
      [phone],
    );
    if (user.rowCount === 0) {
      const userId = crypto.randomUUID();
      await pool.query(
        `INSERT INTO users (id, phone_e164) VALUES ($1, $2)`,
        [userId, phone],
      );
      for (const role of defaultUserRoles) {
        await grantRole(userId, role);
      }
      user = await pool.query(
        `SELECT id, phone_e164, account_status, warn_message
         FROM users WHERE id = $1`,
        [userId],
      );
    }

    const userId = user.rows[0].id as string;
    const accountStatus = (user.rows[0].account_status as string) || 'active';
    if (accountStatus === 'suspended') {
      throw new AppError(
        'This account is suspended. Contact Food support.',
        403,
        'account_suspended',
      );
    }

    // Returning users created before market_seller / events roles existed.
    await grantRole(userId, 'market_seller');
    await grantRole(userId, 'events_attendee');
    await grantRole(userId, 'events_organizer');
    await applyBootstrapAdminRoles(userId, phone);

    const roles = await listRoles(userId);
    const accessToken = signAccessToken({
      sub: userId,
      phone,
      roles,
    });
    const refresh = crypto.randomUUID();
    await pool.query(
      `INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at)
       VALUES ($1, $2, $3, NOW() + INTERVAL '30 days')`,
      [crypto.randomUUID(), userId, refresh],
    );

    return {
      userId,
      phone,
      roles,
      accountStatus,
      warnMessage: (user.rows[0].warn_message as string | null) ?? null,
      accessToken,
      refreshToken: refresh,
      tokenType: 'Bearer',
      expiresIn: envInt('JWT_ACCESS_TTL_SEC', 3600),
    };
  });

  app.get('/v1/me', async (req) => {
    const user = requireAuth(req);
    const roles = await listRoles(user.sub);
    const profile = await pool.query(
      `SELECT account_status, warn_message FROM users WHERE id = $1`,
      [user.sub],
    );
    const accountStatus =
      (profile.rows[0]?.account_status as string | undefined) ?? 'active';
    if (accountStatus === 'suspended') {
      throw new AppError(
        'This account is suspended. Contact Food support.',
        403,
        'account_suspended',
      );
    }
    return {
      userId: user.sub,
      phone: user.phone,
      roles,
      accountStatus,
      warnMessage: (profile.rows[0]?.warn_message as string | null) ?? null,
      isPlatformAdmin: roles.includes('platform_admin'),
      isMarketModerator: isMarketModerator(roles),
    };
  });

  /** Internal/ops moderation — food_ops or platform_admin. */
  app.post('/v1/admin/users/moderate', async (req) => {
    const actor = requireAuth(req);
    requireRole(actor, ['platform_admin', 'food_ops']);
    const body = z
      .object({
        userId: z.string().uuid().optional(),
        phone: z.string().min(9).optional(),
        action: z.enum(['warn', 'suspend', 'clear']),
        message: z.string().max(280).optional(),
        note: z.string().max(500).optional(),
      })
      .refine((v) => Boolean(v.userId || v.phone), {
        message: 'userId or phone required',
      })
      .parse(req.body ?? {});

    const target = await resolveUser({
      userId: body.userId,
      phone: body.phone,
    });

    if (body.action === 'suspend') {
      await pool.query(
        `UPDATE users
         SET account_status = 'suspended',
             warn_message = NULL,
             moderation_note = $2,
             moderated_at = NOW()
         WHERE id = $1`,
        [target.id, body.note ?? body.message ?? 'Suspended by ops'],
      );
    } else if (body.action === 'warn') {
      await pool.query(
        `UPDATE users
         SET account_status = 'warned',
             warn_message = $2,
             moderation_note = $3,
             moderated_at = NOW()
         WHERE id = $1`,
        [
          target.id,
          body.message ??
            'Warning: a delivery no-show was reported on your account.',
          body.note ?? null,
        ],
      );
    } else {
      await pool.query(
        `UPDATE users
         SET account_status = 'active',
             warn_message = NULL,
             moderation_note = $2,
             moderated_at = NOW()
         WHERE id = $1`,
        [target.id, body.note ?? 'Cleared by ops'],
      );
    }

    const updated = await pool.query(
      `SELECT id, phone_e164, account_status, warn_message FROM users WHERE id = $1`,
      [target.id],
    );
    return {
      ok: true,
      userId: updated.rows[0].id,
      phone: updated.rows[0].phone_e164,
      accountStatus: updated.rows[0].account_status,
      warnMessage: updated.rows[0].warn_message,
    };
  });

  app.get('/v1/admin/staff', async (req) => {
    const user = requireAuth(req);
    requireRole(user, 'platform_admin');
    const res = await pool.query(
      `SELECT u.id, u.phone_e164, array_agg(rg.role ORDER BY rg.role) AS roles
       FROM users u
       JOIN role_grants rg ON rg.user_id = u.id
       WHERE rg.role = ANY($1::text[])
       GROUP BY u.id, u.phone_e164
       ORDER BY u.phone_e164`,
      [staffRoles],
    );
    return {
      items: res.rows.map((r) => ({
        userId: r.id,
        phone: r.phone_e164,
        roles: r.roles as string[],
      })),
      bootstrapPhones: adminPhones,
    };
  });

  app.post('/v1/admin/roles/grant', async (req) => {
    const actor = requireAuth(req);
    requireRole(actor, 'platform_admin');
    const body = z
      .object({
        role: z.enum(grantableRoles),
        userId: z.string().uuid().optional(),
        phone: z.string().min(9).optional(),
      })
      .refine((v) => Boolean(v.userId || v.phone), {
        message: 'userId or phone required',
      })
      .parse(req.body ?? {});

    const target = await resolveUser({
      userId: body.userId,
      phone: body.phone,
    });
    await grantRole(target.id, body.role);
    // Platform admins can always moderate Market.
    if (body.role === 'platform_admin') {
      await grantRole(target.id, 'market_moderator');
    }
    return {
      ok: true,
      userId: target.id,
      phone: target.phone_e164,
      roles: await listRoles(target.id),
    };
  });

  app.post('/v1/admin/roles/revoke', async (req) => {
    const actor = requireAuth(req);
    requireRole(actor, 'platform_admin');
    const body = z
      .object({
        role: z.enum(grantableRoles),
        userId: z.string().uuid().optional(),
        phone: z.string().min(9).optional(),
      })
      .refine((v) => Boolean(v.userId || v.phone), {
        message: 'userId or phone required',
      })
      .parse(req.body ?? {});

    const target = await resolveUser({
      userId: body.userId,
      phone: body.phone,
    });

    if (target.id === actor.sub && body.role === 'platform_admin') {
      throw new AppError(
        'Cannot revoke your own platform_admin role',
        400,
        'cannot_self_demote',
      );
    }

    await pool.query(
      `DELETE FROM role_grants WHERE user_id = $1 AND role = $2`,
      [target.id, body.role],
    );
    return {
      ok: true,
      userId: target.id,
      phone: target.phone_e164,
      roles: await listRoles(target.id),
    };
  });

  await listen(app, port);
  if (adminPhones.length === 0) {
    console.warn(
      '[identity] ADMIN_PHONES is empty — no bootstrap admins. Set ADMIN_PHONES=+2519… to create the first platform admin.',
    );
  } else {
    console.log(
      `[identity] Bootstrap admin phones: ${adminPhones.join(', ')}`,
    );
  }
}

function parseAdminPhones(raw: string): string[] {
  return raw
    .split(',')
    .map((p) => p.trim())
    .filter(Boolean)
    .map((p) => {
      try {
        return normalizePhone(p);
      } catch {
        console.warn(`[identity] Ignoring invalid ADMIN_PHONES entry: ${p}`);
        return '';
      }
    })
    .filter(Boolean);
}

function isMarketModerator(roles: string[]): boolean {
  return roles.some((r) =>
    ['market_moderator', 'market_ops', 'platform_admin'].includes(r),
  );
}

async function listRoles(userId: string): Promise<string[]> {
  const rolesRes = await pool.query(
    `SELECT role FROM role_grants WHERE user_id = $1 ORDER BY role`,
    [userId],
  );
  return rolesRes.rows.map((r) => r.role as string);
}

async function grantRole(userId: string, role: string): Promise<void> {
  await pool.query(
    `INSERT INTO role_grants (user_id, role) VALUES ($1, $2)
     ON CONFLICT DO NOTHING`,
    [userId, role],
  );
}

async function applyBootstrapAdminRoles(
  userId: string,
  phone: string,
): Promise<void> {
  if (!adminPhones.includes(phone)) return;
  await grantRole(userId, 'platform_admin');
  await grantRole(userId, 'market_moderator');
  await grantRole(userId, 'food_ops');
  await grantRole(userId, 'food_merchant');
  await grantRole(userId, 'food_delivery_merchant');
  await grantRole(userId, 'food_rider');
  await grantRole(userId, 'ride_ops');
  await grantRole(userId, 'events_ops');
}

/**
 * On boot:
 * - only strip platform_admin from non-bootstrap phones (keep Staff grants)
 * - ensure bootstrap phones keep their admin / food staff bootstrap set
 *
 * Previously this deleted ALL staffRoles (food_merchant, food_rider, …) for
 * everyone except ADMIN_PHONES on every Render restart — wiping QA grants.
 */
async function reconcileStaffRoles(): Promise<void> {
  if (adminPhones.length === 0) {
    await pool.query(
      `DELETE FROM role_grants WHERE role = 'platform_admin'`,
    );
    return;
  }

  await pool.query(
    `DELETE FROM role_grants rg
     USING users u
     WHERE rg.user_id = u.id
       AND rg.role = 'platform_admin'
       AND NOT (u.phone_e164 = ANY($1::text[]))`,
    [adminPhones],
  );

  for (const phone of adminPhones) {
    const user = await pool.query(
      `SELECT id FROM users WHERE phone_e164 = $1`,
      [phone],
    );
    if (!user.rowCount) continue;
    const userId = user.rows[0].id as string;
    await grantRole(userId, 'platform_admin');
    await grantRole(userId, 'market_moderator');
    await grantRole(userId, 'food_ops');
    await grantRole(userId, 'food_merchant');
    await grantRole(userId, 'food_delivery_merchant');
    await grantRole(userId, 'food_rider');
    await grantRole(userId, 'ride_ops');
    await grantRole(userId, 'events_ops');
  }
}

async function resolveUser(input: {
  userId?: string;
  phone?: string;
}): Promise<{ id: string; phone_e164: string }> {
  if (input.userId) {
    const res = await pool.query(
      `SELECT id, phone_e164 FROM users WHERE id = $1`,
      [input.userId],
    );
    if (!res.rowCount) throw new AppError('User not found', 404, 'not_found');
    return res.rows[0] as { id: string; phone_e164: string };
  }
  const phone = normalizePhone(input.phone!);
  const res = await pool.query(
    `SELECT id, phone_e164 FROM users WHERE phone_e164 = $1`,
    [phone],
  );
  if (!res.rowCount) {
    throw new AppError(
      'User not found — they must sign in with OTP once first',
      404,
      'not_found',
    );
  }
  return res.rows[0] as { id: string; phone_e164: string };
}

function normalizePhone(raw: string): string {
  const digits = raw.replace(/\D/g, '');
  if (raw.startsWith('+') && digits.length >= 10) return `+${digits}`;
  if (digits.startsWith('251') && digits.length >= 12) return `+${digits}`;
  if (digits.length === 9) return `+251${digits}`;
  if (digits.length === 10 && digits.startsWith('0')) {
    return `+251${digits.slice(1)}`;
  }
  throw new AppError('Invalid Ethiopian phone', 400, 'invalid_phone');
}

boot().catch((err) => {
  console.error(err);
  process.exit(1);
});
