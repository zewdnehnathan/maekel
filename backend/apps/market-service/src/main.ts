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
} from '@maekel/shared';
import { z } from 'zod';

const port = envInt('MARKET_PORT', 3002);
const chatUrl = env('CHAT_URL', 'http://127.0.0.1:3005');
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
      show_phone BOOLEAN NOT NULL DEFAULT TRUE
    )`,
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
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
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
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
    `CREATE TABLE IF NOT EXISTS ad_threads (
      ad_id UUID NOT NULL REFERENCES ads(id) ON DELETE CASCADE,
      buyer_id UUID NOT NULL,
      thread_id UUID NOT NULL,
      PRIMARY KEY (ad_id, buyer_id)
    )`,
  ]);

  await seed();

  const app = await createService({ name: 'market-service', port });

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
    const res = await pool.query(`SELECT * FROM sellers ORDER BY name`);
    return { items: res.rows.map(mapSeller) };
  });

  app.get('/v1/market/sellers/:id', async (req) => {
    const { id } = req.params as { id: string };
    const res = await pool.query(`SELECT * FROM sellers WHERE id = $1`, [id]);
    if (!res.rowCount) throw new AppError('Seller not found', 404, 'not_found');
    return mapSeller(res.rows[0]);
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

    const clauses = [`status = 'approved'`];
    const params: unknown[] = [];
    const add = (sql: string, value: unknown) => {
      params.push(value);
      clauses.push(sql.replace('?', `$${params.length}`));
    };
    if (q.categoryId) add(`category_id = ?`, q.categoryId);
    if (q.subcity) add(`subcity = ?`, q.subcity);
    if (q.condition) add(`condition = ?`, q.condition);
    if (q.query) {
      params.push(`%${q.query.toLowerCase()}%`);
      clauses.push(
        `(LOWER(title) LIKE $${params.length} OR LOWER(description) LIKE $${params.length})`,
      );
    }
    const order =
      q.sort === 'priceLow'
        ? 'price_etb ASC'
        : q.sort === 'priceHigh'
          ? 'price_etb DESC'
          : 'created_at DESC';
    const res = await pool.query(
      `SELECT * FROM ads WHERE ${clauses.join(' AND ')} ORDER BY ${order}`,
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
        photoUrls: z.array(z.string()).default([]),
        attributes: z.record(z.string(), z.string()).default({}),
      })
      .parse(req.body ?? {});

    const id = crypto.randomUUID();
    const photos =
      body.photoUrls.length > 0
        ? body.photoUrls
        : [
            'https://images.unsplash.com/photo-1560472355-536de3962603?w=800',
          ];
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
        photos,
        JSON.stringify(body.attributes),
      ],
    );

    // Mock moderation auto-approve.
    setTimeout(async () => {
      await pool.query(
        `UPDATE ads SET status = 'approved' WHERE id = $1 AND status = 'pending'`,
        [id],
      );
    }, 4000);

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
    const owned = await pool.query(
      `SELECT seller_id FROM ads WHERE id = $1`,
      [id],
    );
    if (!owned.rowCount) throw new AppError('Ad not found', 404, 'not_found');
    if (owned.rows[0].seller_id !== user.sub && body.status !== 'approved') {
      // sellers can mark sold; moderation approve is open for MVP demo
    }
    await pool.query(
      `UPDATE ads SET status = $2, reject_reason = $3 WHERE id = $1`,
      [id, body.status, body.rejectReason ?? null],
    );
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

  await listen(app, port);
}

function mapSeller(row: Record<string, unknown>) {
  return {
    id: row.id,
    name: row.name,
    phoneE164: row.phone_e164,
    locationLabel: row.location_label,
    showPhone: row.show_phone,
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
  };
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

  const ads: Array<[string, string, string, string, string, number, string, string, string, string, string]> = [
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
    const [id, sellerId, categoryId, title, description, price, condition, subcity, photo, attrs, createdExpr] =
      ad;
    await pool.query(
      `INSERT INTO ads (
        id, seller_id, category_id, title, description, price_etb, condition,
        location_label, subcity, photo_urls, status, attributes, created_at
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,'Addis Ababa',$8,ARRAY[$9],'approved',$10::jsonb,${createdExpr})
       ON CONFLICT (id) DO NOTHING`,
      [id, sellerId, categoryId, title, description, price, condition, subcity, photo, attrs],
    );
  }
}

boot().catch((err) => {
  console.error(err);
  process.exit(1);
});
