import multipart from '@fastify/multipart';
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
} from '@maekel/shared';
import { z } from 'zod';

const port = envInt('MARKET_PORT', 3002);
const chatUrl = env('CHAT_URL', 'http://127.0.0.1:3005');
const publicApiBase = env(
  'PUBLIC_API_BASE',
  env('RENDER_EXTERNAL_URL', 'http://127.0.0.1:8080'),
).replace(/\/$/, '');
const maxActiveFreeAds = envInt('MARKET_MAX_ACTIVE_ADS', 5);
const phoneRevealDailyLimit = envInt('MARKET_PHONE_REVEAL_DAILY_LIMIT', 10);
const pool = createPool(databaseUrl('maekel_market'));

async function boot() {
  await migrate(pool, [
    `CREATE TABLE IF NOT EXISTS categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      icon_name TEXT NOT NULL
    )`,
    `CREATE TABLE IF NOT EXISTS sellers (
      id UUID PRIMARY KEY,
      name TEXT NOT NULL,
      phone_e164 TEXT NOT NULL,
      location_label TEXT NOT NULL,
      show_phone BOOLEAN NOT NULL DEFAULT TRUE,
      suspended BOOLEAN NOT NULL DEFAULT FALSE
    )`,
    `ALTER TABLE sellers ADD COLUMN IF NOT EXISTS suspended BOOLEAN NOT NULL DEFAULT FALSE`,
    `CREATE TABLE IF NOT EXISTS ads (
      id UUID PRIMARY KEY,
      seller_id UUID NOT NULL,
      category_id TEXT NOT NULL REFERENCES categories(id),
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      price_etb INT NOT NULL,
      condition TEXT NOT NULL,
      location_label TEXT NOT NULL,
      subcity TEXT NOT NULL,
      photo_urls TEXT[] NOT NULL DEFAULT '{}',
      status TEXT NOT NULL,
      reject_reason TEXT,
      attributes JSONB NOT NULL DEFAULT '{}',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
    `ALTER TABLE ads ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`,
    `CREATE TABLE IF NOT EXISTS favorites (
      user_id UUID NOT NULL,
      ad_id UUID NOT NULL REFERENCES ads(id) ON DELETE CASCADE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      PRIMARY KEY (user_id, ad_id)
    )`,
    `CREATE TABLE IF NOT EXISTS reports (
      id UUID PRIMARY KEY,
      ad_id UUID NOT NULL REFERENCES ads(id) ON DELETE CASCADE,
      reporter_id UUID NOT NULL,
      reason TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'open',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
    `ALTER TABLE reports ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'open'`,
    `CREATE TABLE IF NOT EXISTS ad_threads (
      ad_id UUID NOT NULL REFERENCES ads(id) ON DELETE CASCADE,
      buyer_id UUID NOT NULL,
      thread_id UUID NOT NULL,
      PRIMARY KEY (ad_id, buyer_id)
    )`,
    `CREATE TABLE IF NOT EXISTS seller_notifications (
      id UUID PRIMARY KEY,
      seller_id UUID NOT NULL,
      ad_id UUID,
      kind TEXT NOT NULL,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      read_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
    `CREATE TABLE IF NOT EXISTS phone_reveal_events (
      id UUID PRIMARY KEY,
      viewer_id UUID NOT NULL,
      ad_id UUID NOT NULL REFERENCES ads(id) ON DELETE CASCADE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
    `CREATE TABLE IF NOT EXISTS market_config (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )`,
    // Survive Render ephemeral disk: store ad photos in Neon BYTEA.
    `CREATE TABLE IF NOT EXISTS media_objects (
      id TEXT PRIMARY KEY,
      content_type TEXT NOT NULL,
      bytes BYTEA NOT NULL,
      byte_len INT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
  ]);

  await pool.query(
    `INSERT INTO market_config (key, value) VALUES ('max_active_free_ads', $1)
     ON CONFLICT (key) DO NOTHING`,
    [String(maxActiveFreeAds)],
  );

  await seed();

  const app = await createService({
    name: 'market-service',
    port,
    bodyLimit: 12 * 1024 * 1024,
  });

  await app.register(multipart, {
    limits: {
      fileSize: 8 * 1024 * 1024,
      files: 1,
    },
  });

  app.get('/v1/market/categories', async () => {
    const res = await pool.query(`SELECT * FROM categories ORDER BY name`);
    return {
      items: res.rows.map((r) => ({
        id: r.id,
        name: r.name,
        iconName: r.icon_name,
      })),
    };
  });

  app.get('/v1/market/sellers', async () => {
    const res = await pool.query(
      `SELECT * FROM sellers WHERE suspended = FALSE ORDER BY name`,
    );
    return { items: res.rows.map(mapSeller) };
  });

  app.get('/v1/market/sellers/:id', async (req) => {
    const { id } = req.params as { id: string };
    const res = await pool.query(`SELECT * FROM sellers WHERE id = $1`, [id]);
    if (!res.rowCount) throw new AppError('Seller not found', 404, 'not_found');
    return mapSeller(res.rows[0]);
  });

  app.get('/v1/market/me/seller', async (req) => {
    const user = requireAuth(req);
    const seller = await ensureSeller(user.sub, user.phone);
    return mapSeller(seller);
  });

  app.patch('/v1/market/me/seller', async (req) => {
    const user = requireAuth(req);
    const body = z
      .object({
        showPhone: z.boolean().optional(),
        name: z.string().min(2).max(80).optional(),
        locationLabel: z.string().min(2).max(120).optional(),
      })
      .parse(req.body ?? {});
    await ensureSeller(user.sub, user.phone);
    await pool.query(
      `UPDATE sellers SET
        show_phone = COALESCE($2, show_phone),
        name = COALESCE($3, name),
        location_label = COALESCE($4, location_label)
       WHERE id = $1`,
      [
        user.sub,
        body.showPhone ?? null,
        body.name ?? null,
        body.locationLabel ?? null,
      ],
    );
    const res = await pool.query(`SELECT * FROM sellers WHERE id = $1`, [
      user.sub,
    ]);
    return mapSeller(res.rows[0]);
  });

  app.get('/v1/market/me/notifications', async (req) => {
    const user = requireAuth(req);
    const res = await pool.query(
      `SELECT * FROM seller_notifications
       WHERE seller_id = $1
       ORDER BY created_at DESC
       LIMIT 50`,
      [user.sub],
    );
    return {
      items: res.rows.map((r) => ({
        id: r.id,
        adId: r.ad_id,
        kind: r.kind,
        title: r.title,
        body: r.body,
        readAt: r.read_at,
        createdAt: r.created_at,
      })),
    };
  });

  app.post('/v1/market/me/notifications/:id/read', async (req) => {
    const user = requireAuth(req);
    const { id } = req.params as { id: string };
    await pool.query(
      `UPDATE seller_notifications SET read_at = NOW()
       WHERE id = $1 AND seller_id = $2 AND read_at IS NULL`,
      [id, user.sub],
    );
    return { ok: true };
  });

  app.get('/v1/market/config', async () => {
    const res = await pool.query(`SELECT key, value FROM market_config`);
    const config: Record<string, string> = {};
    for (const row of res.rows) {
      config[row.key as string] = row.value as string;
    }
    return {
      maxActiveFreeAds: Number(config.max_active_free_ads ?? maxActiveFreeAds),
      phoneRevealDailyLimit,
    };
  });

  app.get('/v1/market/subcities', async () => {
    return {
      items: [
        'Bole',
        'Kirkos',
        'Yeka',
        'Lideta',
        'Nifas Silk',
        'Addis Ketema',
        'Arada',
        'Gulele',
      ],
    };
  });

  app.get('/v1/market/ads', async (req) => {
    const q = z
      .object({
        query: z.string().optional(),
        categoryId: z.string().optional(),
        subcity: z.string().optional(),
        condition: z.string().optional(),
        sort: z.enum(['newest', 'priceLow', 'priceHigh']).optional(),
      })
      .parse(req.query ?? {});

    const clauses = [
      `a.status = 'approved'`,
      `COALESCE(s.suspended, FALSE) = FALSE`,
    ];
    const params: unknown[] = [];
    const add = (sql: string, value: unknown) => {
      params.push(value);
      clauses.push(sql.replace('?', `$${params.length}`));
    };
    if (q.categoryId) add(`a.category_id = ?`, q.categoryId);
    if (q.subcity) add(`a.subcity = ?`, q.subcity);
    if (q.condition) add(`a.condition = ?`, q.condition);
    if (q.query) {
      params.push(`%${q.query.toLowerCase()}%`);
      clauses.push(
        `(LOWER(a.title) LIKE $${params.length} OR LOWER(a.description) LIKE $${params.length})`,
      );
    }
    const order =
      q.sort === 'priceLow'
        ? 'a.price_etb ASC'
        : q.sort === 'priceHigh'
          ? 'a.price_etb DESC'
          : 'a.created_at DESC';
    const res = await pool.query(
      `SELECT a.* FROM ads a
       LEFT JOIN sellers s ON s.id = a.seller_id
       WHERE ${clauses.join(' AND ')} ORDER BY ${order}`,
      params,
    );
    return { items: res.rows.map(mapAd) };
  });

  app.get('/v1/market/ads/:id', async (req) => {
    const { id } = req.params as { id: string };
    const res = await pool.query(`SELECT * FROM ads WHERE id = $1`, [id]);
    if (!res.rowCount) throw new AppError('Ad not found', 404, 'not_found');
    return mapAd(res.rows[0]);
  });

  app.post('/v1/market/media', async (req) => {
    requireAuth(req);
    const file = await req.file();
    if (!file) {
      throw new AppError('No file uploaded', 400, 'validation_error');
    }
    const mime = file.mimetype || '';
    if (!mime.startsWith('image/')) {
      throw new AppError('Only image uploads are allowed', 400, 'invalid_media');
    }
    const bytes = await file.toBuffer();
    if (file.file.truncated) {
      throw new AppError('File too large (max 8MB)', 413, 'file_too_large');
    }
    const ext = extensionForMime(mime);
    const id = crypto.randomUUID();
    const filename = `${id}${ext}`;
    await pool.query(
      `INSERT INTO media_objects (id, content_type, bytes, byte_len)
       VALUES ($1,$2,$3,$4)`,
      [filename, mime, bytes, bytes.length],
    );
    return {
      id: filename,
      url: `${publicApiBase}/v1/market/media/files/${filename}`,
      contentType: mime,
    };
  });

  app.get('/v1/market/media/files/:filename', async (req, reply) => {
    const { filename } = req.params as { filename: string };
    if (!/^[a-f0-9-]+\.(jpe?g|png|webp|gif)$/i.test(filename)) {
      throw new AppError('Invalid media path', 400, 'validation_error');
    }
    const res = await pool.query(
      `SELECT content_type, bytes FROM media_objects WHERE id = $1`,
      [filename],
    );
    if (!res.rowCount) {
      throw new AppError('Media not found', 404, 'not_found');
    }
    const row = res.rows[0] as { content_type: string; bytes: Buffer };
    reply.header('Cache-Control', 'public, max-age=86400');
    return reply.type(row.content_type).send(row.bytes);
  });

  app.post('/v1/market/ads', async (req) => {
    const user = requireAuth(req);
    const body = z
      .object({
        categoryId: z.string(),
        title: z.string().min(6),
        description: z.string().min(20),
        priceEtb: z.number().int().positive(),
        condition: z.enum(['brandNew', 'used', 'refurbished']),
        subcity: z.string().min(2),
        photoUrls: z.array(z.string().url()).min(1).max(8),
        attributes: z.record(z.string(), z.string()).default({}),
      })
      .parse(req.body ?? {});

    const seller = await ensureSeller(user.sub, user.phone);
    if (seller.suspended) {
      throw new AppError('Seller account suspended', 403, 'seller_suspended');
    }

    const limit = await getMaxActiveAds();
    const active = await pool.query(
      `SELECT COUNT(*)::int AS c FROM ads
       WHERE seller_id = $1 AND status IN ('approved', 'pending')`,
      [user.sub],
    );
    if ((active.rows[0].c as number) >= limit) {
      throw new AppError(
        `Active ad limit reached (${limit}). Mark sold or delete an ad first.`,
        400,
        'ad_limit',
      );
    }

    const id = crypto.randomUUID();
    await pool.query(
      `INSERT INTO ads (
        id, seller_id, category_id, title, description, price_etb, condition,
        location_label, subcity, photo_urls, status, attributes
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,'Addis Ababa',$8,$9,'pending',$10)`,
      [
        id,
        user.sub,
        body.categoryId,
        body.title,
        body.description,
        body.priceEtb,
        body.condition,
        body.subcity,
        body.photoUrls,
        JSON.stringify(body.attributes),
      ],
    );

    await notifySeller({
      sellerId: user.sub,
      adId: id,
      kind: 'moderation_submitted',
      title: 'Ad submitted',
      body: `"${body.title}" is pending review.`,
    });

    const res = await pool.query(`SELECT * FROM ads WHERE id = $1`, [id]);
    return mapAd(res.rows[0]);
  });

  app.patch('/v1/market/ads/:id', async (req) => {
    const user = requireAuth(req);
    const { id } = req.params as { id: string };
    const body = z
      .object({
        categoryId: z.string().optional(),
        title: z.string().min(6).optional(),
        description: z.string().min(20).optional(),
        priceEtb: z.number().int().positive().optional(),
        condition: z.enum(['brandNew', 'used', 'refurbished']).optional(),
        subcity: z.string().min(2).optional(),
        photoUrls: z.array(z.string().url()).min(1).max(8).optional(),
        attributes: z.record(z.string(), z.string()).optional(),
      })
      .parse(req.body ?? {});

    const existing = await pool.query(`SELECT * FROM ads WHERE id = $1`, [id]);
    if (!existing.rowCount) throw new AppError('Ad not found', 404, 'not_found');
    if (existing.rows[0].seller_id !== user.sub) {
      throw new AppError('Forbidden', 403, 'forbidden');
    }
    if (existing.rows[0].status === 'sold') {
      throw new AppError('Sold ads cannot be edited', 400, 'sold_locked');
    }

    const material =
      body.title !== undefined ||
      body.description !== undefined ||
      body.priceEtb !== undefined ||
      body.photoUrls !== undefined ||
      body.categoryId !== undefined;

    await pool.query(
      `UPDATE ads SET
        category_id = COALESCE($2, category_id),
        title = COALESCE($3, title),
        description = COALESCE($4, description),
        price_etb = COALESCE($5, price_etb),
        condition = COALESCE($6, condition),
        subcity = COALESCE($7, subcity),
        photo_urls = COALESCE($8, photo_urls),
        attributes = COALESCE($9::jsonb, attributes),
        status = CASE WHEN $10 THEN 'pending' ELSE status END,
        reject_reason = CASE WHEN $10 THEN NULL ELSE reject_reason END,
        updated_at = NOW()
       WHERE id = $1`,
      [
        id,
        body.categoryId ?? null,
        body.title ?? null,
        body.description ?? null,
        body.priceEtb ?? null,
        body.condition ?? null,
        body.subcity ?? null,
        body.photoUrls ?? null,
        body.attributes ? JSON.stringify(body.attributes) : null,
        material,
      ],
    );

    if (material) {
      await notifySeller({
        sellerId: user.sub,
        adId: id,
        kind: 'moderation_resubmitted',
        title: 'Ad re-submitted',
        body: 'Your edit is pending moderation again.',
      });
    }

    const res = await pool.query(`SELECT * FROM ads WHERE id = $1`, [id]);
    return mapAd(res.rows[0]);
  });

  app.get('/v1/market/my-ads', async (req) => {
    const user = requireAuth(req);
    const res = await pool.query(
      `SELECT * FROM ads WHERE seller_id = $1 ORDER BY created_at DESC`,
      [user.sub],
    );
    return { items: res.rows.map(mapAd) };
  });

  app.patch('/v1/market/ads/:id/status', async (req) => {
    const user = requireAuth(req);
    const { id } = req.params as { id: string };
    const body = z
      .object({
        status: z.enum(['approved', 'rejected', 'sold', 'pending']),
        rejectReason: z.string().optional(),
      })
      .parse(req.body ?? {});

    const owned = await pool.query(`SELECT * FROM ads WHERE id = $1`, [id]);
    if (!owned.rowCount) throw new AppError('Ad not found', 404, 'not_found');
    const ad = owned.rows[0];
    const isOwner = ad.seller_id === user.sub;
    const isModerator = user.roles.some((r) =>
      ['market_moderator', 'market_ops', 'platform_admin'].includes(r),
    );

    if (body.status === 'sold' || body.status === 'pending') {
      if (!isOwner) throw new AppError('Forbidden', 403, 'forbidden');
    } else if (body.status === 'approved' || body.status === 'rejected') {
      if (!isModerator) throw new AppError('Forbidden', 403, 'forbidden');
      if (body.status === 'rejected' && !body.rejectReason?.trim()) {
        throw new AppError('Reject reason required', 400, 'validation_error');
      }
    }

    await pool.query(
      `UPDATE ads SET status = $2, reject_reason = $3, updated_at = NOW() WHERE id = $1`,
      [
        id,
        body.status,
        body.status === 'rejected' ? (body.rejectReason ?? null) : null,
      ],
    );

    if (body.status === 'approved') {
      await notifySeller({
        sellerId: ad.seller_id as string,
        adId: id,
        kind: 'moderation_approved',
        title: 'Ad approved',
        body: `"${ad.title}" is now live.`,
      });
    } else if (body.status === 'rejected') {
      await notifySeller({
        sellerId: ad.seller_id as string,
        adId: id,
        kind: 'moderation_rejected',
        title: 'Ad declined',
        body: body.rejectReason ?? 'Your ad was declined.',
      });
    }

    const res = await pool.query(`SELECT * FROM ads WHERE id = $1`, [id]);
    return mapAd(res.rows[0]);
  });

  app.delete('/v1/market/ads/:id', async (req) => {
    const user = requireAuth(req);
    const { id } = req.params as { id: string };
    const res = await pool.query(
      `DELETE FROM ads WHERE id = $1 AND seller_id = $2`,
      [id, user.sub],
    );
    if (!res.rowCount) throw new AppError('Ad not found', 404, 'not_found');
    return { ok: true };
  });

  app.post('/v1/market/ads/:id/reveal-phone', async (req) => {
    const user = requireAuth(req);
    const { id } = req.params as { id: string };
    const adRes = await pool.query(`SELECT * FROM ads WHERE id = $1`, [id]);
    if (!adRes.rowCount) throw new AppError('Ad not found', 404, 'not_found');
    const ad = adRes.rows[0];
    if (ad.status !== 'approved') {
      throw new AppError('Ad not available', 404, 'not_found');
    }
    if (ad.seller_id === user.sub) {
      throw new AppError('Cannot reveal your own phone', 400, 'own_ad');
    }

    const sellerRes = await pool.query(`SELECT * FROM sellers WHERE id = $1`, [
      ad.seller_id,
    ]);
    if (!sellerRes.rowCount) {
      throw new AppError('Seller not found', 404, 'not_found');
    }
    const seller = sellerRes.rows[0];
    if (seller.suspended) {
      throw new AppError('Seller unavailable', 403, 'seller_suspended');
    }
    if (!seller.show_phone) {
      throw new AppError('Seller hid their phone', 403, 'phone_hidden');
    }

    const used = await pool.query(
      `SELECT COUNT(*)::int AS c FROM phone_reveal_events
       WHERE viewer_id = $1 AND created_at >= NOW() - INTERVAL '1 day'`,
      [user.sub],
    );
    if ((used.rows[0].c as number) >= phoneRevealDailyLimit) {
      throw new AppError(
        'Daily call limit reached. Use chat instead.',
        429,
        'phone_rate_limit',
      );
    }

    await pool.query(
      `INSERT INTO phone_reveal_events (id, viewer_id, ad_id) VALUES ($1,$2,$3)`,
      [crypto.randomUUID(), user.sub, id],
    );

    return {
      phoneE164: seller.phone_e164,
      remainingToday: phoneRevealDailyLimit - ((used.rows[0].c as number) + 1),
    };
  });

  app.post('/v1/market/favorites/:adId/toggle', async (req) => {
    const user = requireAuth(req);
    const { adId } = req.params as { adId: string };
    const existing = await pool.query(
      `SELECT 1 FROM favorites WHERE user_id = $1 AND ad_id = $2`,
      [user.sub, adId],
    );
    if (existing.rowCount) {
      await pool.query(
        `DELETE FROM favorites WHERE user_id = $1 AND ad_id = $2`,
        [user.sub, adId],
      );
      return { favorited: false };
    }
    await pool.query(
      `INSERT INTO favorites (user_id, ad_id) VALUES ($1, $2)`,
      [user.sub, adId],
    );
    return { favorited: true };
  });

  app.get('/v1/market/favorites', async (req) => {
    const user = requireAuth(req);
    const res = await pool.query(
      `SELECT a.* FROM favorites f
       JOIN ads a ON a.id = f.ad_id
       WHERE f.user_id = $1 AND a.status = 'approved'
       ORDER BY f.created_at DESC`,
      [user.sub],
    );
    return { items: res.rows.map(mapAd) };
  });

  app.post('/v1/market/ads/:id/report', async (req) => {
    const user = requireAuth(req);
    const { id } = req.params as { id: string };
    const body = z.object({ reason: z.string().min(3) }).parse(req.body ?? {});
    const reportId = crypto.randomUUID();
    await pool.query(
      `INSERT INTO reports (id, ad_id, reporter_id, reason) VALUES ($1,$2,$3,$4)`,
      [reportId, id, user.sub, body.reason],
    );
    return { id: reportId, ok: true };
  });

  app.post('/v1/market/ads/:id/chat', async (req) => {
    const user = requireAuth(req);
    const { id } = req.params as { id: string };
    const ad = await pool.query(`SELECT * FROM ads WHERE id = $1`, [id]);
    if (!ad.rowCount) throw new AppError('Ad not found', 404, 'not_found');
    if (ad.rows[0].seller_id === user.sub) {
      throw new AppError('Cannot chat on your own ad', 400, 'own_ad');
    }
    const existing = await pool.query(
      `SELECT thread_id FROM ad_threads WHERE ad_id = $1 AND buyer_id = $2`,
      [id, user.sub],
    );
    if (existing.rowCount) {
      return { threadId: existing.rows[0].thread_id };
    }

    const created = await fetch(`${chatUrl}/v1/chat/threads`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: req.headers.authorization ?? '',
      },
      body: JSON.stringify({
        adId: id,
        buyerId: user.sub,
        sellerId: ad.rows[0].seller_id,
      }),
    });
    if (!created.ok) {
      throw new AppError('Failed to open chat', 502, 'chat_unavailable');
    }
    const data = (await created.json()) as { id: string };
    await pool.query(
      `INSERT INTO ad_threads (ad_id, buyer_id, thread_id) VALUES ($1,$2,$3)`,
      [id, user.sub, data.id],
    );
    return { threadId: data.id };
  });

  // --- Ops (thin) ---

  app.get('/v1/market/ops/queue', async (req) => {
    const user = requireAuth(req);
    requireRole(user, ['market_moderator', 'market_ops', 'platform_admin']);
    const pending = await pool.query(
      `SELECT * FROM ads WHERE status = 'pending' ORDER BY created_at ASC`,
    );
    const reports = await pool.query(
      `SELECT r.*, a.title AS ad_title, a.seller_id
       FROM reports r
       JOIN ads a ON a.id = r.ad_id
       WHERE r.status = 'open'
       ORDER BY r.created_at ASC
       LIMIT 100`,
    );
    return {
      pendingAds: pending.rows.map(mapAd),
      reports: reports.rows.map((r) => ({
        id: r.id,
        adId: r.ad_id,
        adTitle: r.ad_title,
        sellerId: r.seller_id,
        reporterId: r.reporter_id,
        reason: r.reason,
        status: r.status,
        createdAt: r.created_at,
      })),
    };
  });

  app.post('/v1/market/ops/reports/:id/resolve', async (req) => {
    const user = requireAuth(req);
    requireRole(user, ['market_moderator', 'market_ops', 'platform_admin']);
    const { id } = req.params as { id: string };
    const body = z
      .object({
        action: z.enum(['dismiss', 'unpublish', 'suspend']),
        note: z.string().optional(),
      })
      .parse(req.body ?? {});

    const report = await pool.query(`SELECT * FROM reports WHERE id = $1`, [id]);
    if (!report.rowCount) throw new AppError('Report not found', 404, 'not_found');
    const adId = report.rows[0].ad_id as string;
    const ad = await pool.query(`SELECT * FROM ads WHERE id = $1`, [adId]);
    if (!ad.rowCount) throw new AppError('Ad not found', 404, 'not_found');

    if (body.action === 'unpublish') {
      await pool.query(
        `UPDATE ads SET status = 'rejected', reject_reason = $2, updated_at = NOW()
         WHERE id = $1`,
        [adId, body.note ?? 'Unpublished after report'],
      );
      await notifySeller({
        sellerId: ad.rows[0].seller_id as string,
        adId,
        kind: 'moderation_rejected',
        title: 'Ad unpublished',
        body: body.note ?? 'Your ad was unpublished after a report.',
      });
    } else if (body.action === 'suspend') {
      await ensureSeller(
        ad.rows[0].seller_id as string,
        '+251000000000',
      );
      await pool.query(`UPDATE sellers SET suspended = TRUE WHERE id = $1`, [
        ad.rows[0].seller_id,
      ]);
      await pool.query(
        `UPDATE ads SET status = 'rejected', reject_reason = $2, updated_at = NOW()
         WHERE seller_id = $1 AND status IN ('approved', 'pending')`,
        [ad.rows[0].seller_id, body.note ?? 'Seller suspended'],
      );
    }

    await pool.query(`UPDATE reports SET status = 'resolved' WHERE id = $1`, [
      id,
    ]);
    return { ok: true };
  });

  app.post('/v1/market/ops/sellers/:id/suspend', async (req) => {
    const user = requireAuth(req);
    requireRole(user, ['market_moderator', 'market_ops', 'platform_admin']);
    const { id } = req.params as { id: string };
    const body = z
      .object({
        suspended: z.boolean(),
        note: z.string().optional(),
      })
      .parse(req.body ?? {});
    await ensureSeller(id, '+251000000000');
    await pool.query(`UPDATE sellers SET suspended = $2 WHERE id = $1`, [
      id,
      body.suspended,
    ]);
    if (body.suspended) {
      await pool.query(
        `UPDATE ads SET status = 'rejected',
          reject_reason = COALESCE($2, 'Seller suspended'),
          updated_at = NOW()
         WHERE seller_id = $1 AND status IN ('approved', 'pending')`,
        [id, body.note ?? null],
      );
    }
    const res = await pool.query(`SELECT * FROM sellers WHERE id = $1`, [id]);
    return mapSeller(res.rows[0]);
  });

  app.patch('/v1/market/ops/categories/:id', async (req) => {
    const user = requireAuth(req);
    requireRole(user, ['market_moderator', 'market_ops', 'platform_admin']);
    const { id } = req.params as { id: string };
    const body = z
      .object({
        name: z.string().min(2).optional(),
        iconName: z.string().min(2).optional(),
      })
      .parse(req.body ?? {});
    const res = await pool.query(
      `UPDATE categories SET
        name = COALESCE($2, name),
        icon_name = COALESCE($3, icon_name)
       WHERE id = $1
       RETURNING *`,
      [id, body.name ?? null, body.iconName ?? null],
    );
    if (!res.rowCount) throw new AppError('Category not found', 404, 'not_found');
    return {
      id: res.rows[0].id,
      name: res.rows[0].name,
      iconName: res.rows[0].icon_name,
    };
  });

  app.patch('/v1/market/ops/config', async (req) => {
    const user = requireAuth(req);
    requireRole(user, ['market_moderator', 'market_ops', 'platform_admin']);
    const body = z
      .object({ maxActiveFreeAds: z.number().int().min(1).max(50) })
      .parse(req.body ?? {});
    await pool.query(
      `INSERT INTO market_config (key, value) VALUES ('max_active_free_ads', $1)
       ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value`,
      [String(body.maxActiveFreeAds)],
    );
    return { maxActiveFreeAds: body.maxActiveFreeAds };
  });

  await listen(app, port);
}

function extensionForMime(mime: string): string {
  switch (mime) {
    case 'image/png':
      return '.png';
    case 'image/webp':
      return '.webp';
    case 'image/gif':
      return '.gif';
    default:
      return '.jpg';
  }
}

function mapSeller(row: Record<string, unknown>) {
  return {
    id: row.id,
    name: row.name,
    phoneE164: row.phone_e164,
    locationLabel: row.location_label,
    showPhone: row.show_phone,
    suspended: Boolean(row.suspended),
  };
}

function mapAd(row: Record<string, unknown>) {
  return {
    id: row.id,
    sellerId: row.seller_id,
    categoryId: row.category_id,
    title: row.title,
    description: row.description,
    priceEtb: row.price_etb,
    condition: row.condition,
    locationLabel: row.location_label,
    subcity: row.subcity,
    photoUrls: row.photo_urls,
    status: row.status,
    rejectReason: row.reject_reason,
    attributes: row.attributes ?? {},
    createdAt: row.created_at,
    updatedAt: row.updated_at ?? row.created_at,
  };
}

async function getMaxActiveAds(): Promise<number> {
  const res = await pool.query(
    `SELECT value FROM market_config WHERE key = 'max_active_free_ads'`,
  );
  if (!res.rowCount) return maxActiveFreeAds;
  const n = Number(res.rows[0].value);
  return Number.isFinite(n) && n > 0 ? n : maxActiveFreeAds;
}

async function ensureSeller(id: string, phone: string) {
  const existing = await pool.query(`SELECT * FROM sellers WHERE id = $1`, [id]);
  if (existing.rowCount) return existing.rows[0];
  const name = `Seller ${phone.slice(-4)}`;
  await pool.query(
    `INSERT INTO sellers (id, name, phone_e164, location_label, show_phone, suspended)
     VALUES ($1,$2,$3,'Addis Ababa',TRUE,FALSE)
     ON CONFLICT (id) DO NOTHING`,
    [id, name, phone],
  );
  const res = await pool.query(`SELECT * FROM sellers WHERE id = $1`, [id]);
  return res.rows[0];
}

async function notifySeller(input: {
  sellerId: string;
  adId: string;
  kind: string;
  title: string;
  body: string;
}) {
  await pool.query(
    `INSERT INTO seller_notifications (id, seller_id, ad_id, kind, title, body)
     VALUES ($1,$2,$3,$4,$5,$6)`,
    [
      crypto.randomUUID(),
      input.sellerId,
      input.adId,
      input.kind,
      input.title,
      input.body,
    ],
  );
}

async function seed() {
  const cats = [
    ['phones', 'Phones & Tablets', 'phone'],
    ['electronics', 'Electronics', 'devices'],
    ['vehicles', 'Vehicles', 'car'],
    ['property', 'Property', 'home'],
    ['furniture', 'Home & Furniture', 'chair'],
    ['fashion', 'Fashion', 'checkroom'],
  ];
  for (const [id, name, icon] of cats) {
    await pool.query(
      `INSERT INTO categories (id, name, icon_name) VALUES ($1,$2,$3)
       ON CONFLICT (id) DO NOTHING`,
      [id, name, icon],
    );
  }

  const sellers = [
    [
      '00000000-0000-4000-8000-000000000001',
      'Hanna T.',
      '+251911100001',
      'Bole, Addis Ababa',
      true,
    ],
    [
      '00000000-0000-4000-8000-000000000002',
      'Yonas M.',
      '+251911100002',
      'CMC, Addis Ababa',
      false,
    ],
    [
      '00000000-0000-4000-8000-000000000003',
      'Sara K.',
      '+251911100003',
      'Piassa, Addis Ababa',
      true,
    ],
  ] as const;
  for (const [id, name, phone, location, showPhone] of sellers) {
    await pool.query(
      `INSERT INTO sellers (id, name, phone_e164, location_label, show_phone)
       VALUES ($1,$2,$3,$4,$5)
       ON CONFLICT (id) DO NOTHING`,
      [id, name, phone, location, showPhone],
    );
  }

  const ads: Array<
    [
      string,
      string,
      string,
      string,
      string,
      number,
      string,
      string,
      string,
      string,
      string,
    ]
  > = [
    [
      'a0000000-0000-4000-8000-000000000001',
      '00000000-0000-4000-8000-000000000001',
      'phones',
      'iPhone 13 128GB — clean',
      'Unlocked iPhone 13, battery 89%. Box + cable. Meetup in Bole Atlas.',
      48500,
      'used',
      'Bole',
      'https://images.unsplash.com/photo-1632661674596-df8befba448d?w=800',
      '{"Brand":"Apple","Storage":"128GB"}',
      "NOW() - INTERVAL '5 hours'",
    ],
    [
      'a0000000-0000-4000-8000-000000000002',
      '00000000-0000-4000-8000-000000000002',
      'electronics',
      '55" Smart TV 4K',
      'Almost new Samsung smart TV. Wall mount included.',
      62000,
      'refurbished',
      'Yeka',
      'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=800',
      '{"Brand":"Samsung","Size":"55\\""}',
      "NOW() - INTERVAL '1 day'",
    ],
    [
      'a0000000-0000-4000-8000-000000000003',
      '00000000-0000-4000-8000-000000000003',
      'vehicles',
      'Toyota Vitz 2008',
      'City car, AC working, duty paid. Serious buyers only.',
      980000,
      'used',
      'Nifas Silk',
      'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=800',
      '{"Year":"2008","Fuel":"Petrol"}',
      "NOW() - INTERVAL '2 days'",
    ],
    [
      'a0000000-0000-4000-8000-000000000004',
      '00000000-0000-4000-8000-000000000001',
      'furniture',
      'Solid wood dining set',
      '6 chairs + table. Pickup from Kirkos.',
      28000,
      'used',
      'Kirkos',
      'https://images.unsplash.com/photo-1617806118233-18e1de247200?w=800',
      '{}',
      "NOW() - INTERVAL '30 hours'",
    ],
    [
      'a0000000-0000-4000-8000-000000000005',
      '00000000-0000-4000-8000-000000000002',
      'fashion',
      'Leather jacket — medium',
      'Genuine leather, worn twice. Cash on meetup.',
      4500,
      'brandNew',
      'Arada',
      'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800',
      '{}',
      "NOW() - INTERVAL '12 hours'",
    ],
    [
      'a0000000-0000-4000-8000-000000000006',
      '00000000-0000-4000-8000-000000000003',
      'property',
      'Studio for rent — Bole',
      'Furnished studio near Edna Mall. Water + wifi included.',
      25000,
      'used',
      'Bole',
      'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
      '{"Type":"Rent","Furnishing":"Furnished"}',
      "NOW() - INTERVAL '3 days'",
    ],
  ];

  for (const ad of ads) {
    const [
      id,
      sellerId,
      categoryId,
      title,
      description,
      price,
      condition,
      subcity,
      photo,
      attrs,
      createdExpr,
    ] = ad;
    await pool.query(
      `INSERT INTO ads (
        id, seller_id, category_id, title, description, price_etb, condition,
        location_label, subcity, photo_urls, status, attributes, created_at
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,'Addis Ababa',$8,ARRAY[$9],'approved',$10::jsonb,${createdExpr})
       ON CONFLICT (id) DO NOTHING`,
      [
        id,
        sellerId,
        categoryId,
        title,
        description,
        price,
        condition,
        subcity,
        photo,
        attrs,
      ],
    );
  }
}

boot().catch((err) => {
  console.error(err);
  process.exit(1);
});
