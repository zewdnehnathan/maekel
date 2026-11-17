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
  signAccessToken,
} from '@maekel/shared';
import { z } from 'zod';

const port = envInt('IDENTITY_PORT', 3001);
const mockOtp = env('MOCK_OTP_CODE', '123456');
const pool = createPool(databaseUrl('maekel_identity'));

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
    `CREATE TABLE IF NOT EXISTS refresh_tokens (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      token_hash TEXT NOT NULL UNIQUE,
      expires_at TIMESTAMPTZ NOT NULL,
      revoked_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
  ]);

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
      `SELECT id, phone_e164 FROM users WHERE phone_e164 = $1`,
      [phone],
    );
    if (user.rowCount === 0) {
      const userId = crypto.randomUUID();
      await pool.query(
        `INSERT INTO users (id, phone_e164) VALUES ($1, $2)`,
        [userId, phone],
      );
      const defaultRoles = [
        'ride_passenger',
        'food_customer',
        'market_buyer',
        'market_seller',
        // Demo MVP: every new account can open the thin ops queue.
        'market_moderator',
      ];
      for (const role of defaultRoles) {
        await pool.query(
          `INSERT INTO role_grants (user_id, role) VALUES ($1, $2)
           ON CONFLICT DO NOTHING`,
          [userId, role],
        );
      }
      user = await pool.query(
        `SELECT id, phone_e164 FROM users WHERE id = $1`,
        [userId],
      );
    }

    const userId = user.rows[0].id as string;
    // Demo MVP: ensure market seller + thin ops roles exist for returning users.
    for (const role of ['market_seller', 'market_moderator']) {
      await pool.query(
        `INSERT INTO role_grants (user_id, role) VALUES ($1, $2)
         ON CONFLICT DO NOTHING`,
        [userId, role],
      );
    }
    const rolesRes = await pool.query(
      `SELECT role FROM role_grants WHERE user_id = $1`,
      [userId],
    );
    const roles = rolesRes.rows.map((r) => r.role as string);
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
      accessToken,
      refreshToken: refresh,
      tokenType: 'Bearer',
      expiresIn: envInt('JWT_ACCESS_TTL_SEC', 3600),
    };
  });

  app.get('/v1/me', async (req) => {
    const user = requireAuth(req);
    const rolesRes = await pool.query(
      `SELECT role FROM role_grants WHERE user_id = $1`,
      [user.sub],
    );
    return {
      userId: user.sub,
      phone: user.phone,
      roles: rolesRes.rows.map((r) => r.role),
    };
  });

  app.post('/v1/admin/roles/grant', async (req) => {
    requireAuth(req);
    const body = z
      .object({ userId: z.string().uuid(), role: z.string().min(2) })
      .parse(req.body ?? {});
    await pool.query(
      `INSERT INTO role_grants (user_id, role) VALUES ($1, $2)
       ON CONFLICT DO NOTHING`,
      [body.userId, body.role],
    );
    return { ok: true };
  });

  await listen(app, port);
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
