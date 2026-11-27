import type { FastifyInstance } from 'fastify';
import type { Pool } from 'pg';
import {
  AppError,
  createPool,
  databaseUrl,
  requireAuth,
  requireRole,
} from '@maekel/shared';
import { z } from 'zod';

const opsStaff = ['food_ops', 'platform_admin'] as const;
const deliveryOwnerStaff = [
  'food_delivery_merchant',
  'food_ops',
  'platform_admin',
] as const;

type MerchantMapper = (row: Record<string, unknown>) => unknown;
type OrderMapper = (row: Record<string, unknown>) => unknown;

function toE164(rawPhone: string): string {
  const digits = rawPhone.replace(/\D/g, '');
  if (rawPhone.startsWith('+')) return rawPhone;
  if (digits.length === 9) return `+251${digits}`;
  if (digits.length === 12 && digits.startsWith('251')) return `+${digits}`;
  return rawPhone;
}

async function withIdentityPool<T>(
  fn: (identityPool: Pool) => Promise<T>,
): Promise<T> {
  const identityPool = createPool(databaseUrl('maekel_identity'));
  try {
    return await fn(identityPool);
  } finally {
    await identityPool.end().catch(() => undefined);
  }
}

export async function resolveUserByPhone(
  rawPhone: string,
): Promise<{ id: string; phone: string }> {
  const e164 = toE164(rawPhone.trim());
  return withIdentityPool(async (identityPool) => {
    const res = await identityPool.query(
      `SELECT id, phone_e164 FROM users WHERE phone_e164 = $1`,
      [e164],
    );
    if (!res.rowCount) {
      throw new AppError(
        `No user registered with ${e164}. They must OTP once first.`,
        404,
        'user_not_found',
      );
    }
    return {
      id: res.rows[0].id as string,
      phone: res.rows[0].phone_e164 as string,
    };
  });
}

export async function grantIdentityRole(
  userId: string,
  role: string,
): Promise<void> {
  await withIdentityPool(async (identityPool) => {
    await identityPool.query(
      `INSERT INTO role_grants (user_id, role) VALUES ($1, $2)
       ON CONFLICT DO NOTHING`,
      [userId, role],
    );
  });
}

export async function phoneForUserId(userId: string): Promise<string | null> {
  return withIdentityPool(async (identityPool) => {
    const res = await identityPool.query(
      `SELECT phone_e164 FROM users WHERE id = $1`,
      [userId],
    );
    if (!res.rowCount) return null;
    return res.rows[0].phone_e164 as string;
  });
}

function mapApplication(row: Record<string, unknown>) {
  return {
    id: row.id,
    kind: row.kind,
    applicantUserId: row.applicant_user_id,
    applicantPhone: row.applicant_phone,
    title: row.title,
    subcity: row.subcity,
    licenseMediaId: row.license_media_id,
    status: row.status,
    reviewNote: row.review_note,
    reviewedBy: row.reviewed_by,
    createdAt: row.created_at,
    reviewedAt: row.reviewed_at,
  };
}

function mapOrg(row: Record<string, unknown>) {
  return {
    id: row.id,
    name: row.name,
    ownerUserId: row.owner_user_id,
    ownerPhone: row.owner_phone,
    licenseMediaId: row.license_media_id,
    isActive: row.is_active,
    createdAt: row.created_at,
  };
}

function mapReport(row: Record<string, unknown>) {
  return {
    id: row.id,
    orderId: row.order_id,
    customerId: row.customer_id,
    reporterUserId: row.reporter_user_id,
    reporterKind: row.reporter_kind,
    reason: row.reason,
    note: row.note,
    status: row.status,
    reviewNote: row.review_note,
    reviewedBy: row.reviewed_by,
    createdAt: row.created_at,
    reviewedAt: row.reviewed_at,
  };
}

async function moderateIdentityUser(input: {
  userId: string;
  action: 'warn' | 'suspend' | 'clear';
  message?: string;
  note?: string;
}): Promise<void> {
  await withIdentityPool(async (identityPool) => {
    if (input.action === 'suspend') {
      await identityPool.query(
        `UPDATE users
         SET account_status = 'suspended',
             warn_message = NULL,
             moderation_note = $2,
             moderated_at = NOW()
         WHERE id = $1`,
        [input.userId, input.note ?? 'Suspended via food report'],
      );
      return;
    }
    if (input.action === 'warn') {
      await identityPool.query(
        `UPDATE users
         SET account_status = 'warned',
             warn_message = $2,
             moderation_note = $3,
             moderated_at = NOW()
         WHERE id = $1`,
        [
          input.userId,
          input.message ??
            'Warning: a delivery no-show was reported on your account.',
          input.note ?? null,
        ],
      );
      return;
    }
    await identityPool.query(
      `UPDATE users
       SET account_status = 'active',
           warn_message = NULL,
           moderation_note = $2,
           moderated_at = NOW()
       WHERE id = $1`,
      [input.userId, input.note ?? 'Cleared'],
    );
  });
}

export function registerPartnerRoutes(
  app: FastifyInstance,
  pool: Pool,
  deps: {
    mapMerchant: MerchantMapper;
    mapOrder: OrderMapper;
    publicApiBase: string;
    extensionForMime: (mime: string) => string;
  },
): void {
  const { mapMerchant, mapOrder, publicApiBase, extensionForMime } = deps;

  // ── Applications (restaurant + delivery org) ─────────────────────────
  app.post('/v1/food/applications/media', async (req) => {
    requireAuth(req);
    const file = await req.file();
    if (!file) throw new AppError('No file uploaded', 400, 'validation_error');
    const mime = file.mimetype || '';
    if (!mime.startsWith('image/')) {
      throw new AppError('Only image uploads are allowed', 400, 'invalid_media');
    }
    const bytes = await file.toBuffer();
    if (file.file.truncated) {
      throw new AppError('File too large (max 8MB)', 413, 'file_too_large');
    }
    const filename = `${crypto.randomUUID()}${extensionForMime(mime)}`;
    await pool.query(
      `INSERT INTO media_objects (id, content_type, bytes, byte_len)
       VALUES ($1,$2,$3,$4)`,
      [filename, mime, bytes, bytes.length],
    );
    return {
      id: filename,
      url: `${publicApiBase}/v1/food/media/files/${filename}`,
      contentType: mime,
    };
  });

  app.post('/v1/food/applications', async (req) => {
    const user = requireAuth(req);
    const body = z
      .object({
        kind: z.enum(['restaurant', 'delivery_org']),
        title: z.string().min(2).max(80),
        subcity: z.string().min(1).default('Bole'),
        licenseMediaId: z.string().min(1).optional(),
      })
      .parse(req.body ?? {});

    const pending = await pool.query(
      `SELECT id FROM merchant_applications
       WHERE applicant_user_id = $1 AND kind = $2 AND status = 'pending'`,
      [user.sub, body.kind],
    );
    if (pending.rowCount) {
      throw new AppError(
        'You already have a pending application of this type',
        409,
        'pending_exists',
      );
    }

    const phone = (await phoneForUserId(user.sub)) ?? user.phone;
    const id = crypto.randomUUID();
    await pool.query(
      `INSERT INTO merchant_applications (
        id, kind, applicant_user_id, applicant_phone, title, subcity,
        license_media_id, status
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,'pending')`,
      [
        id,
        body.kind,
        user.sub,
        phone,
        body.title,
        body.subcity,
        body.licenseMediaId ?? null,
      ],
    );
    const res = await pool.query(
      `SELECT * FROM merchant_applications WHERE id = $1`,
      [id],
    );
    return mapApplication(res.rows[0]);
  });

  app.get('/v1/food/applications/mine', async (req) => {
    const user = requireAuth(req);
    const res = await pool.query(
      `SELECT * FROM merchant_applications
       WHERE applicant_user_id = $1
       ORDER BY created_at DESC`,
      [user.sub],
    );
    return { items: res.rows.map(mapApplication) };
  });

  app.get('/v1/food/ops/applications', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const q = z
      .object({
        status: z
          .enum(['pending', 'approved', 'rejected', 'all'])
          .default('pending'),
      })
      .parse(req.query ?? {});
    const res =
      q.status === 'all'
        ? await pool.query(
            `SELECT * FROM merchant_applications ORDER BY created_at DESC LIMIT 100`,
          )
        : await pool.query(
            `SELECT * FROM merchant_applications WHERE status = $1
             ORDER BY created_at ASC LIMIT 100`,
            [q.status],
          );
    return { items: res.rows.map(mapApplication) };
  });

  app.post('/v1/food/ops/applications/:id/reject', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const { id } = req.params as { id: string };
    const body = z
      .object({ note: z.string().default('Rejected by ops') })
      .parse(req.body ?? {});
    const res = await pool.query(
      `UPDATE merchant_applications
       SET status = 'rejected', review_note = $2, reviewed_by = $3, reviewed_at = NOW()
       WHERE id = $1 AND status = 'pending'
       RETURNING *`,
      [id, body.note, user.sub],
    );
    if (!res.rowCount) throw new AppError('Not found', 404, 'not_found');
    return mapApplication(res.rows[0]);
  });

  app.post('/v1/food/ops/applications/:id/approve', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const { id } = req.params as { id: string };
    const body = z
      .object({ note: z.string().optional() })
      .parse(req.body ?? {});

    const appRes = await pool.query(
      `SELECT * FROM merchant_applications WHERE id = $1`,
      [id],
    );
    if (!appRes.rowCount) throw new AppError('Not found', 404, 'not_found');
    const application = appRes.rows[0] as Record<string, unknown>;
    if (application.status !== 'pending') {
      throw new AppError('Already reviewed', 400, 'bad_status');
    }

    const applicantId = application.applicant_user_id as string;
    const phone = application.applicant_phone as string;
    const title = application.title as string;
    const subcity = (application.subcity as string) || 'Bole';
    const licenseMediaId = application.license_media_id as string | null;
    const kind = application.kind as string;

    if (kind === 'restaurant') {
      const taken = await pool.query(
        `SELECT id FROM merchants WHERE owner_user_id = $1`,
        [applicantId],
      );
      if (taken.rowCount) {
        throw new AppError(
          'Applicant already owns a restaurant',
          409,
          'already_owner',
        );
      }
      const merchantId = `m-${title
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .slice(0, 20)}-${crypto.randomUUID().slice(0, 6)}`;
      await pool.query(
        `INSERT INTO merchants (
          id, name, kind, subcity, is_open, eta_minutes, delivery_fee_etb,
          min_order_etb, rating, cover_url, hours_label, owner_user_id,
          owner_phone, coverage_subcities, self_delivery
        ) VALUES ($1,$2,'restaurant',$3,TRUE,35,70,150,4.0,$4,'10:00 – 22:00',$5,$6,$7,FALSE)`,
        [
          merchantId,
          title,
          subcity,
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=900',
          applicantId,
          phone,
          JSON.stringify([subcity]),
        ],
      );
      await grantIdentityRole(applicantId, 'food_merchant');
    } else if (kind === 'delivery_org') {
      const taken = await pool.query(
        `SELECT id FROM delivery_orgs WHERE owner_user_id = $1`,
        [applicantId],
      );
      if (taken.rowCount) {
        throw new AppError(
          'Applicant already owns a delivery org',
          409,
          'already_owner',
        );
      }
      const orgId = `d-${title
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .slice(0, 20)}-${crypto.randomUUID().slice(0, 6)}`;
      await pool.query(
        `INSERT INTO delivery_orgs (
          id, name, owner_user_id, owner_phone, license_media_id, is_active
        ) VALUES ($1,$2,$3,$4,$5,TRUE)`,
        [orgId, title, applicantId, phone, licenseMediaId],
      );
      await grantIdentityRole(applicantId, 'food_delivery_merchant');
    } else {
      throw new AppError('Unknown application kind', 400, 'validation_error');
    }

    const updated = await pool.query(
      `UPDATE merchant_applications
       SET status = 'approved', review_note = $2, reviewed_by = $3, reviewed_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [id, body.note ?? 'Approved', user.sub],
    );
    return {
      application: mapApplication(updated.rows[0]),
      roleRefreshHint: 'Applicant must log out and OTP again to refresh roles',
    };
  });

  // ── Delivery org console ─────────────────────────────────────────────
  async function requireDeliveryOrg(userId: string, roles: string[]) {
    if (roles.some((r) => opsStaff.includes(r as (typeof opsStaff)[number]))) {
      const any = await pool.query(
        `SELECT * FROM delivery_orgs ORDER BY created_at DESC LIMIT 1`,
      );
      if (!any.rowCount) {
        throw new AppError('No delivery org', 404, 'no_org');
      }
      return mapOrg(any.rows[0]);
    }
    const res = await pool.query(
      `SELECT * FROM delivery_orgs WHERE owner_user_id = $1 LIMIT 1`,
      [userId],
    );
    if (!res.rowCount) {
      throw new AppError(
        'No delivery org linked to this account',
        403,
        'no_org',
      );
    }
    return mapOrg(res.rows[0]);
  }

  app.get('/v1/food/delivery/org', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...deliveryOwnerStaff]);
    return requireDeliveryOrg(user.sub, user.roles);
  });

  app.get('/v1/food/delivery/members', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...deliveryOwnerStaff]);
    const org = (await requireDeliveryOrg(user.sub, user.roles)) as {
      id: string;
    };
    const res = await pool.query(
      `SELECT org_id, rider_user_id, phone, created_at
       FROM delivery_org_members WHERE org_id = $1 ORDER BY created_at`,
      [org.id],
    );
    return {
      items: res.rows.map((r) => ({
        orgId: r.org_id,
        riderUserId: r.rider_user_id,
        phone: r.phone,
        createdAt: r.created_at,
      })),
    };
  });

  app.post('/v1/food/delivery/members', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...deliveryOwnerStaff]);
    const org = (await requireDeliveryOrg(user.sub, user.roles)) as {
      id: string;
    };
    const body = z.object({ phone: z.string().min(9) }).parse(req.body ?? {});
    const rider = await resolveUserByPhone(body.phone);
    await grantIdentityRole(rider.id, 'food_rider');
    await pool.query(
      `INSERT INTO delivery_org_members (org_id, rider_user_id, phone)
       VALUES ($1,$2,$3)
       ON CONFLICT (org_id, rider_user_id) DO UPDATE SET phone = EXCLUDED.phone`,
      [org.id, rider.id, rider.phone],
    );
    return { ok: true, riderUserId: rider.id, phone: rider.phone };
  });

  app.delete('/v1/food/delivery/members/:riderUserId', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...deliveryOwnerStaff]);
    const org = (await requireDeliveryOrg(user.sub, user.roles)) as {
      id: string;
    };
    const { riderUserId } = req.params as { riderUserId: string };
    await pool.query(
      `DELETE FROM delivery_org_members WHERE org_id = $1 AND rider_user_id = $2`,
      [org.id, riderUserId],
    );
    return { ok: true };
  });

  app.get('/v1/food/delivery/active-orders', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...deliveryOwnerStaff]);
    const org = (await requireDeliveryOrg(user.sub, user.roles)) as {
      id: string;
    };
    const res = await pool.query(
      `SELECT o.* FROM orders o
       JOIN delivery_org_members m ON m.rider_user_id = o.rider_id
       WHERE m.org_id = $1
         AND o.status IN ('ready','pickedUp','onTheWay')
       ORDER BY o.created_at DESC`,
      [org.id],
    );
    return { items: res.rows.map((r) => mapOrder(r)) };
  });

  /** Fleet orders that can be reported for customer no-show. */
  app.get('/v1/food/delivery/reportable-orders', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...deliveryOwnerStaff]);
    const org = (await requireDeliveryOrg(user.sub, user.roles)) as {
      id: string;
    };
    const res = await pool.query(
      `SELECT o.* FROM orders o
       JOIN delivery_org_members m ON m.rider_user_id = o.rider_id
       WHERE m.org_id = $1
         AND (
           o.status IN ('pickedUp','onTheWay')
           OR (o.status IN ('delivered','cancelled')
               AND o.created_at > NOW() - INTERVAL '48 hours')
         )
       ORDER BY o.created_at DESC
       LIMIT 50`,
      [org.id],
    );
    return { items: res.rows.map((r) => mapOrder(r)) };
  });

  app.post('/v1/food/reports', async (req) => {
    const user = requireAuth(req);
    const body = z
      .object({
        orderId: z.string().uuid(),
        reason: z
          .enum(['customer_no_show', 'refused_order', 'other'])
          .default('customer_no_show'),
        note: z.string().max(500).optional(),
      })
      .parse(req.body ?? {});

    const orderRes = await pool.query(`SELECT * FROM orders WHERE id = $1`, [
      body.orderId,
    ]);
    if (!orderRes.rowCount) throw new AppError('Order not found', 404, 'not_found');
    const order = orderRes.rows[0] as Record<string, unknown>;
    const customerId = order.customer_id as string;
    const riderId = order.rider_id as string | null;
    const status = order.status as string;

    if (!['pickedUp', 'onTheWay', 'delivered', 'cancelled'].includes(status)) {
      throw new AppError(
        'Order is not in a reportable delivery stage',
        400,
        'bad_status',
      );
    }

    let reporterKind: string | null = null;
    if (riderId === user.sub) {
      reporterKind = 'rider';
    } else if (
      user.roles.some((r) =>
        ['food_delivery_merchant', 'food_ops', 'platform_admin'].includes(r),
      )
    ) {
      const org = await pool.query(
        `SELECT o.id FROM delivery_orgs o
         JOIN delivery_org_members m ON m.org_id = o.id
         WHERE o.owner_user_id = $1 AND m.rider_user_id = $2`,
        [user.sub, riderId],
      );
      const opsBypass = user.roles.some((r) =>
        ['food_ops', 'platform_admin'].includes(r),
      );
      if (org.rowCount || opsBypass) reporterKind = 'delivery_merchant';
    }

    if (!reporterKind) {
      throw new AppError(
        'Only the assigned rider or their delivery merchant can report',
        403,
        'forbidden',
      );
    }

    const dup = await pool.query(
      `SELECT id FROM customer_reports
       WHERE order_id = $1 AND reporter_user_id = $2 AND status = 'pending'`,
      [body.orderId, user.sub],
    );
    if (dup.rowCount) {
      throw new AppError('Report already pending for this order', 409, 'duplicate');
    }

    const id = crypto.randomUUID();
    await pool.query(
      `INSERT INTO customer_reports (
        id, order_id, customer_id, reporter_user_id, reporter_kind, reason, note, status
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,'pending')`,
      [
        id,
        body.orderId,
        customerId,
        user.sub,
        reporterKind,
        body.reason,
        body.note ?? null,
      ],
    );
    const res = await pool.query(`SELECT * FROM customer_reports WHERE id = $1`, [
      id,
    ]);
    return mapReport(res.rows[0]);
  });

  app.get('/v1/food/ops/reports', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const q = z
      .object({
        status: z
          .enum(['pending', 'warned', 'suspended', 'ignored', 'all'])
          .default('pending'),
      })
      .parse(req.query ?? {});
    const res =
      q.status === 'all'
        ? await pool.query(
            `SELECT * FROM customer_reports ORDER BY created_at DESC LIMIT 100`,
          )
        : await pool.query(
            `SELECT * FROM customer_reports WHERE status = $1
             ORDER BY created_at ASC LIMIT 100`,
            [q.status],
          );
    return { items: res.rows.map(mapReport) };
  });

  app.post('/v1/food/ops/reports/:id/review', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const { id } = req.params as { id: string };
    const body = z
      .object({
        action: z.enum(['warn', 'suspend', 'ignore']),
        message: z.string().max(280).optional(),
        note: z.string().max(500).optional(),
      })
      .parse(req.body ?? {});

    const reportRes = await pool.query(
      `SELECT * FROM customer_reports WHERE id = $1`,
      [id],
    );
    if (!reportRes.rowCount) throw new AppError('Not found', 404, 'not_found');
    const report = reportRes.rows[0] as Record<string, unknown>;
    if (report.status !== 'pending') {
      throw new AppError('Already reviewed', 400, 'bad_status');
    }

    const customerId = report.customer_id as string;
    let newStatus = 'ignored';
    if (body.action === 'warn' || body.action === 'suspend') {
      await moderateIdentityUser({
        userId: customerId,
        action: body.action,
        message:
          body.message ??
          (body.action === 'warn'
            ? 'Warning: you were reported for not being available at delivery.'
            : undefined),
        note: body.note ?? `Food report ${id}`,
      });
      newStatus = body.action === 'warn' ? 'warned' : 'suspended';
    }

    const updated = await pool.query(
      `UPDATE customer_reports
       SET status = $2, review_note = $3, reviewed_by = $4, reviewed_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [id, newStatus, body.note ?? body.action, user.sub],
    );
    return mapReport(updated.rows[0]);
  });

  // ── Restaurant self-delivery riders ──────────────────────────────────
  app.patch('/v1/food/merchant/self-delivery', async (req) => {
    const user = requireAuth(req);
    const body = z
      .object({ enabled: z.boolean() })
      .parse(req.body ?? {});
    const owned = await pool.query(
      `SELECT * FROM merchants WHERE owner_user_id = $1 LIMIT 1`,
      [user.sub],
    );
    if (!owned.rowCount) {
      throw new AppError('No restaurant linked', 403, 'no_merchant');
    }
    const res = await pool.query(
      `UPDATE merchants SET self_delivery = $2
       WHERE id = $1 RETURNING *`,
      [owned.rows[0].id, body.enabled],
    );
    return mapMerchant(res.rows[0]);
  });

  app.get('/v1/food/merchant/riders', async (req) => {
    const user = requireAuth(req);
    const owned = await pool.query(
      `SELECT id FROM merchants WHERE owner_user_id = $1 LIMIT 1`,
      [user.sub],
    );
    if (!owned.rowCount) {
      throw new AppError('No restaurant linked', 403, 'no_merchant');
    }
    const merchantId = owned.rows[0].id as string;
    const res = await pool.query(
      `SELECT merchant_id, rider_user_id, phone, created_at
       FROM merchant_riders WHERE merchant_id = $1 ORDER BY created_at`,
      [merchantId],
    );
    return {
      items: res.rows.map((r) => ({
        merchantId: r.merchant_id,
        riderUserId: r.rider_user_id,
        phone: r.phone,
        createdAt: r.created_at,
      })),
    };
  });

  app.post('/v1/food/merchant/riders', async (req) => {
    const user = requireAuth(req);
    const owned = await pool.query(
      `SELECT id FROM merchants WHERE owner_user_id = $1 LIMIT 1`,
      [user.sub],
    );
    if (!owned.rowCount) {
      throw new AppError('No restaurant linked', 403, 'no_merchant');
    }
    const merchantId = owned.rows[0].id as string;
    const body = z.object({ phone: z.string().min(9) }).parse(req.body ?? {});
    const rider = await resolveUserByPhone(body.phone);
    await grantIdentityRole(rider.id, 'food_rider');
    await pool.query(
      `INSERT INTO merchant_riders (merchant_id, rider_user_id, phone)
       VALUES ($1,$2,$3)
       ON CONFLICT (merchant_id, rider_user_id) DO UPDATE SET phone = EXCLUDED.phone`,
      [merchantId, rider.id, rider.phone],
    );
    return { ok: true, riderUserId: rider.id, phone: rider.phone };
  });

  app.delete('/v1/food/merchant/riders/:riderUserId', async (req) => {
    const user = requireAuth(req);
    const owned = await pool.query(
      `SELECT id FROM merchants WHERE owner_user_id = $1 LIMIT 1`,
      [user.sub],
    );
    if (!owned.rowCount) {
      throw new AppError('No restaurant linked', 403, 'no_merchant');
    }
    const { riderUserId } = req.params as { riderUserId: string };
    await pool.query(
      `DELETE FROM merchant_riders WHERE merchant_id = $1 AND rider_user_id = $2`,
      [owned.rows[0].id, riderUserId],
    );
    return { ok: true };
  });
}

/** Ready jobs visible to this rider given self-delivery rules. */
export async function listAvailableJobsForRider(
  pool: Pool,
  riderUserId: string,
): Promise<Record<string, unknown>[]> {
  const res = await pool.query(
    `SELECT o.*
     FROM orders o
     JOIN merchants m ON m.id = o.merchant_id
     WHERE o.status = 'ready'
       AND o.rider_id IS NULL
       AND (
         (m.self_delivery = TRUE AND EXISTS (
           SELECT 1 FROM merchant_riders mr
           WHERE mr.merchant_id = m.id AND mr.rider_user_id = $1
         ))
         OR
         (m.self_delivery = FALSE)
       )
     ORDER BY o.created_at ASC`,
    [riderUserId],
  );
  return res.rows as Record<string, unknown>[];
}

export async function assertRiderCanClaim(
  pool: Pool,
  orderId: string,
  riderUserId: string,
): Promise<void> {
  const res = await pool.query(
    `SELECT m.self_delivery, m.id AS merchant_id
     FROM orders o
     JOIN merchants m ON m.id = o.merchant_id
     WHERE o.id = $1`,
    [orderId],
  );
  if (!res.rowCount) throw new AppError('Not found', 404, 'not_found');
  if (res.rows[0].self_delivery) {
    const ok = await pool.query(
      `SELECT 1 FROM merchant_riders
       WHERE merchant_id = $1 AND rider_user_id = $2`,
      [res.rows[0].merchant_id, riderUserId],
    );
    if (!ok.rowCount) {
      throw new AppError(
        'This restaurant uses self-delivery only',
        403,
        'self_delivery_only',
      );
    }
  }
}
