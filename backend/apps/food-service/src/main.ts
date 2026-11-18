import {
  AppError,
  createPool,
  createService,
  databaseUrl,
  envInt,
  listen,
  migrate,
  requireAuth,
  requireRole,
} from '@maekel/shared';
import { z } from 'zod';

const port = envInt('FOOD_PORT', 3003);
const pool = createPool(databaseUrl('maekel_food'));
/** When true, orders auto-advance without merchant/rider (legacy demo). */
const autoAdvance = process.env.FOOD_AUTO_ADVANCE === 'true';

const merchantStaff = ['food_merchant', 'food_ops', 'platform_admin'] as const;
const riderStaff = ['food_rider', 'food_ops', 'platform_admin'] as const;
const opsStaff = ['food_ops', 'platform_admin'] as const;

async function boot() {
  await migrate(pool, [
    `CREATE TABLE IF NOT EXISTS merchants (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      kind TEXT NOT NULL,
      subcity TEXT NOT NULL,
      is_open BOOLEAN NOT NULL,
      eta_minutes INT NOT NULL,
      delivery_fee_etb INT NOT NULL,
      min_order_etb INT NOT NULL,
      rating NUMERIC(2,1) NOT NULL,
      cover_url TEXT NOT NULL,
      hours_label TEXT NOT NULL
    )`,
    `CREATE TABLE IF NOT EXISTS menu_items (
      id TEXT PRIMARY KEY,
      merchant_id TEXT NOT NULL REFERENCES merchants(id),
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      price_etb INT NOT NULL,
      photo_url TEXT NOT NULL,
      available BOOLEAN NOT NULL DEFAULT TRUE,
      modifiers JSONB NOT NULL DEFAULT '[]'
    )`,
    `CREATE TABLE IF NOT EXISTS carts (
      user_id UUID PRIMARY KEY,
      merchant_id TEXT,
      lines JSONB NOT NULL DEFAULT '[]',
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
    `CREATE TABLE IF NOT EXISTS orders (
      id UUID PRIMARY KEY,
      customer_id UUID NOT NULL,
      merchant_id TEXT NOT NULL REFERENCES merchants(id),
      lines JSONB NOT NULL,
      address JSONB NOT NULL,
      notes TEXT NOT NULL DEFAULT '',
      subtotal_etb INT NOT NULL,
      delivery_fee_etb INT NOT NULL,
      status TEXT NOT NULL,
      delivery_otp TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      cancelled_at TIMESTAMPTZ
    )`,
    `ALTER TABLE merchants ADD COLUMN IF NOT EXISTS owner_user_id UUID`,
    `ALTER TABLE merchants ADD COLUMN IF NOT EXISTS coverage_subcities JSONB NOT NULL DEFAULT '[]'`,
    `ALTER TABLE orders ADD COLUMN IF NOT EXISTS rider_id UUID`,
    `ALTER TABLE orders ADD COLUMN IF NOT EXISTS reject_reason TEXT`,
    `CREATE TABLE IF NOT EXISTS saved_places (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL,
      label TEXT NOT NULL,
      subcity TEXT NOT NULL,
      details TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
  ]);
  await seed();

  const app = await createService({ name: 'food-service', port });

  // ── Catalog ──────────────────────────────────────────────────────────
  app.get('/v1/food/merchants', async (req) => {
    const q = z
      .object({
        kind: z.enum(['restaurant', 'grocery']).optional(),
        query: z.string().optional(),
        subcity: z.string().optional(),
      })
      .parse(req.query ?? {});
    const params: unknown[] = [];
    const clauses: string[] = [];
    if (q.kind) {
      params.push(q.kind);
      clauses.push(`kind = $${params.length}`);
    }
    if (q.query) {
      params.push(`%${q.query.toLowerCase()}%`);
      clauses.push(
        `(LOWER(name) LIKE $${params.length} OR LOWER(subcity) LIKE $${params.length})`,
      );
    }
    if (q.subcity) {
      params.push(q.subcity);
      // Covered if pin subcity is in coverage list, or list empty and merchant.subcity matches.
      clauses.push(
        `(
          coverage_subcities @> to_jsonb(ARRAY[$${params.length}]::text[])
          OR (
            (coverage_subcities = '[]'::jsonb OR coverage_subcities IS NULL)
            AND subcity = $${params.length}
          )
        )`,
      );
    }
    const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
    const res = await pool.query(
      `SELECT * FROM merchants ${where} ORDER BY name`,
      params,
    );
    return { items: res.rows.map(mapMerchant) };
  });

  app.get('/v1/food/merchants/:id', async (req) => {
    const { id } = req.params as { id: string };
    const res = await pool.query(`SELECT * FROM merchants WHERE id = $1`, [id]);
    if (!res.rowCount) throw new AppError('Not found', 404, 'not_found');
    return mapMerchant(res.rows[0]);
  });

  app.get('/v1/food/merchants/:id/menu', async (req) => {
    const { id } = req.params as { id: string };
    const res = await pool.query(
      `SELECT * FROM menu_items WHERE merchant_id = $1 ORDER BY name`,
      [id],
    );
    return { items: res.rows.map(mapMenuItem) };
  });

  // ── Saved places ─────────────────────────────────────────────────────
  app.get('/v1/food/places', async (req) => {
    const user = requireAuth(req);
    const res = await pool.query(
      `SELECT * FROM saved_places WHERE user_id = $1 ORDER BY created_at DESC`,
      [user.sub],
    );
    return { items: res.rows.map(mapPlace) };
  });

  app.post('/v1/food/places', async (req) => {
    const user = requireAuth(req);
    const body = z
      .object({
        label: z.string().min(1),
        subcity: z.string().min(1),
        details: z.string().min(1),
      })
      .parse(req.body ?? {});
    const id = crypto.randomUUID();
    await pool.query(
      `INSERT INTO saved_places (id, user_id, label, subcity, details)
       VALUES ($1,$2,$3,$4,$5)`,
      [id, user.sub, body.label, body.subcity, body.details],
    );
    const res = await pool.query(`SELECT * FROM saved_places WHERE id = $1`, [
      id,
    ]);
    return mapPlace(res.rows[0]);
  });

  app.delete('/v1/food/places/:id', async (req) => {
    const user = requireAuth(req);
    const { id } = req.params as { id: string };
    const res = await pool.query(
      `DELETE FROM saved_places WHERE id = $1 AND user_id = $2`,
      [id, user.sub],
    );
    if (!res.rowCount) throw new AppError('Not found', 404, 'not_found');
    return { ok: true };
  });

  // ── Cart ─────────────────────────────────────────────────────────────
  app.get('/v1/food/cart', async (req) => {
    const user = requireAuth(req);
    return getCart(user.sub);
  });

  app.post('/v1/food/cart/items', async (req) => {
    const user = requireAuth(req);
    const body = z
      .object({
        itemId: z.string(),
        quantity: z.number().int().positive().default(1),
        modifierIds: z.array(z.string()).default([]),
      })
      .parse(req.body ?? {});
    const itemRes = await pool.query(
      `SELECT * FROM menu_items WHERE id = $1`,
      [body.itemId],
    );
    if (!itemRes.rowCount) throw new AppError('Item not found', 404, 'not_found');
    const item = mapMenuItem(itemRes.rows[0]);
    const cart = await getCart(user.sub);
    if (cart.merchantId && cart.merchantId !== item.merchantId) {
      throw new AppError(
        'Cart holds another restaurant. Clear cart first.',
        409,
        'cart_conflict',
      );
    }
    const lines = [...cart.lines];
    const idx = lines.findIndex(
      (l) =>
        l.item.id === item.id &&
        sameMods(l.selectedModifierIds, body.modifierIds),
    );
    if (idx >= 0) {
      lines[idx] = {
        ...lines[idx],
        quantity: lines[idx].quantity + body.quantity,
      };
    } else {
      lines.push({
        item,
        quantity: body.quantity,
        selectedModifierIds: body.modifierIds,
      });
    }
    await saveCart(user.sub, item.merchantId, lines);
    return getCart(user.sub);
  });

  app.patch('/v1/food/cart/items/:itemId', async (req) => {
    const user = requireAuth(req);
    const { itemId } = req.params as { itemId: string };
    const body = z.object({ quantity: z.number().int() }).parse(req.body ?? {});
    const cart = await getCart(user.sub);
    let lines = cart.lines;
    if (body.quantity <= 0) {
      lines = lines.filter((l) => l.item.id !== itemId);
    } else {
      lines = lines.map((l) =>
        l.item.id === itemId ? { ...l, quantity: body.quantity } : l,
      );
    }
    await saveCart(user.sub, lines.length ? cart.merchantId : null, lines);
    return getCart(user.sub);
  });

  app.delete('/v1/food/cart', async (req) => {
    const user = requireAuth(req);
    await saveCart(user.sub, null, []);
    return getCart(user.sub);
  });

  // ── Customer orders ──────────────────────────────────────────────────
  app.post('/v1/food/orders', async (req) => {
    const user = requireAuth(req);
    const body = z
      .object({
        address: z.object({
          label: z.string(),
          subcity: z.string(),
          details: z.string(),
        }),
        notes: z.string().default(''),
      })
      .parse(req.body ?? {});
    const cart = await getCart(user.sub);
    if (!cart.merchantId || cart.lines.length === 0) {
      throw new AppError('Cart is empty', 400, 'empty_cart');
    }
    const merchantRes = await pool.query(
      `SELECT * FROM merchants WHERE id = $1`,
      [cart.merchantId],
    );
    const merchant = mapMerchant(merchantRes.rows[0]);
    if (!merchant.isOpen) throw new AppError('Merchant closed', 400, 'closed');
    if (!coversSubcity(merchant, body.address.subcity)) {
      throw new AppError(
        'Merchant does not deliver to this area',
        400,
        'out_of_coverage',
      );
    }
    if (cart.subtotalEtb < merchant.minOrderEtb) {
      throw new AppError(
        `Minimum order is ${merchant.minOrderEtb} ETB`,
        400,
        'min_order',
      );
    }
    const id = crypto.randomUUID();
    const otp = String(100000 + Math.floor(Math.random() * 900000));
    await pool.query(
      `INSERT INTO orders (
        id, customer_id, merchant_id, lines, address, notes,
        subtotal_etb, delivery_fee_etb, status, delivery_otp
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,'placed',$9)`,
      [
        id,
        user.sub,
        merchant.id,
        JSON.stringify(cart.lines),
        JSON.stringify(body.address),
        body.notes,
        cart.subtotalEtb,
        merchant.deliveryFeeEtb,
        otp,
      ],
    );
    await saveCart(user.sub, null, []);
    if (autoAdvance) {
      simulatePipeline(id).catch(() => undefined);
    }
    return getOrder(id);
  });

  app.get('/v1/food/orders', async (req) => {
    const user = requireAuth(req);
    const res = await pool.query(
      `SELECT * FROM orders WHERE customer_id = $1 ORDER BY created_at DESC`,
      [user.sub],
    );
    return { items: res.rows.map(mapOrder) };
  });

  app.get('/v1/food/orders/:id', async (req) => {
    requireAuth(req);
    const { id } = req.params as { id: string };
    return getOrder(id);
  });

  app.post('/v1/food/orders/:id/cancel', async (req) => {
    const user = requireAuth(req);
    const { id } = req.params as { id: string };
    const order = await getOrder(id);
    if (order.customerId !== user.sub && !isOps(user.roles)) {
      throw new AppError('Forbidden', 403, 'forbidden');
    }
    if (!['placed', 'confirmed'].includes(order.status)) {
      throw new AppError('Cannot cancel after preparing starts', 400, 'locked');
    }
    await pool.query(
      `UPDATE orders SET status = 'cancelled', cancelled_at = NOW() WHERE id = $1`,
      [id],
    );
    return getOrder(id);
  });

  app.post('/v1/food/orders/:id/complete', async (req) => {
    requireAuth(req);
    const { id } = req.params as { id: string };
    const body = z.object({ otp: z.string().min(4) }).parse(req.body ?? {});
    return completeWithOtp(id, body.otp);
  });

  app.post('/v1/food/orders/:id/advance', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const { id } = req.params as { id: string };
    const order = await getOrder(id);
    const next: Record<string, string> = {
      placed: 'confirmed',
      confirmed: 'preparing',
      preparing: 'ready',
      ready: 'pickedUp',
      pickedUp: 'onTheWay',
    };
    const status = next[order.status] ?? order.status;
    await pool.query(`UPDATE orders SET status = $2 WHERE id = $1`, [id, status]);
    return getOrder(id);
  });

  // ── Merchant console ─────────────────────────────────────────────────
  app.get('/v1/food/merchant/me', async (req) => {
    const user = requireAuth(req);
    const res = await pool.query(
      `SELECT * FROM merchants WHERE owner_user_id = $1 LIMIT 1`,
      [user.sub],
    );
    if (!res.rowCount) return { merchant: null };
    return { merchant: mapMerchant(res.rows[0]) };
  });

  app.get('/v1/food/merchant/claimable', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...merchantStaff]);
    const res = await pool.query(
      `SELECT * FROM merchants WHERE owner_user_id IS NULL ORDER BY name`,
    );
    return { items: res.rows.map(mapMerchant) };
  });

  app.post('/v1/food/merchant/claim', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...merchantStaff]);
    const body = z.object({ merchantId: z.string() }).parse(req.body ?? {});
    const existing = await pool.query(
      `SELECT id FROM merchants WHERE owner_user_id = $1`,
      [user.sub],
    );
    if (existing.rowCount) {
      throw new AppError('You already own a merchant', 409, 'already_owner');
    }
    const res = await pool.query(
      `UPDATE merchants SET owner_user_id = $1
       WHERE id = $2 AND owner_user_id IS NULL
       RETURNING *`,
      [user.sub, body.merchantId],
    );
    if (!res.rowCount) {
      throw new AppError('Merchant unavailable', 409, 'unavailable');
    }
    return mapMerchant(res.rows[0]);
  });

  app.patch('/v1/food/merchant/me', async (req) => {
    const user = requireAuth(req);
    const body = z
      .object({ isOpen: z.boolean().optional() })
      .parse(req.body ?? {});
    const merchant = await requireOwnedMerchant(user.sub, user.roles);
    if (body.isOpen !== undefined) {
      await pool.query(`UPDATE merchants SET is_open = $2 WHERE id = $1`, [
        merchant.id,
        body.isOpen,
      ]);
    }
    const res = await pool.query(`SELECT * FROM merchants WHERE id = $1`, [
      merchant.id,
    ]);
    return mapMerchant(res.rows[0]);
  });

  app.get('/v1/food/merchant/orders', async (req) => {
    const user = requireAuth(req);
    const merchant = await requireOwnedMerchant(user.sub, user.roles);
    const res = await pool.query(
      `SELECT * FROM orders WHERE merchant_id = $1
       AND status NOT IN ('delivered','cancelled')
       ORDER BY created_at ASC`,
      [merchant.id],
    );
    return { items: res.rows.map(mapOrder), merchant };
  });

  app.post('/v1/food/merchant/orders/:id/accept', async (req) => {
    const user = requireAuth(req);
    const merchant = await requireOwnedMerchant(user.sub, user.roles);
    const { id } = req.params as { id: string };
    const order = await getOrder(id);
    assertMerchantOrder(order, merchant.id);
    if (order.status !== 'placed') {
      throw new AppError('Order is not awaiting accept', 400, 'bad_status');
    }
    await pool.query(`UPDATE orders SET status = 'confirmed' WHERE id = $1`, [
      id,
    ]);
    return getOrder(id);
  });

  app.post('/v1/food/merchant/orders/:id/reject', async (req) => {
    const user = requireAuth(req);
    const merchant = await requireOwnedMerchant(user.sub, user.roles);
    const { id } = req.params as { id: string };
    const body = z
      .object({ reason: z.string().default('Rejected by merchant') })
      .parse(req.body ?? {});
    const order = await getOrder(id);
    assertMerchantOrder(order, merchant.id);
    if (!['placed', 'confirmed'].includes(order.status)) {
      throw new AppError('Cannot reject after preparing', 400, 'locked');
    }
    await pool.query(
      `UPDATE orders SET status = 'cancelled', cancelled_at = NOW(), reject_reason = $2
       WHERE id = $1`,
      [id, body.reason],
    );
    return getOrder(id);
  });

  app.post('/v1/food/merchant/orders/:id/preparing', async (req) => {
    const user = requireAuth(req);
    const merchant = await requireOwnedMerchant(user.sub, user.roles);
    const { id } = req.params as { id: string };
    const order = await getOrder(id);
    assertMerchantOrder(order, merchant.id);
    if (order.status !== 'confirmed') {
      throw new AppError('Accept order first', 400, 'bad_status');
    }
    await pool.query(`UPDATE orders SET status = 'preparing' WHERE id = $1`, [
      id,
    ]);
    return getOrder(id);
  });

  app.post('/v1/food/merchant/orders/:id/ready', async (req) => {
    const user = requireAuth(req);
    const merchant = await requireOwnedMerchant(user.sub, user.roles);
    const { id } = req.params as { id: string };
    const order = await getOrder(id);
    assertMerchantOrder(order, merchant.id);
    if (order.status !== 'preparing') {
      throw new AppError('Mark preparing first', 400, 'bad_status');
    }
    await pool.query(`UPDATE orders SET status = 'ready' WHERE id = $1`, [id]);
    return getOrder(id);
  });

  // ── Food rider ───────────────────────────────────────────────────────
  app.get('/v1/food/rider/jobs', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...riderStaff]);
    const available = await pool.query(
      `SELECT * FROM orders
       WHERE status = 'ready' AND rider_id IS NULL
       ORDER BY created_at ASC`,
    );
    const mine = await pool.query(
      `SELECT * FROM orders
       WHERE rider_id = $1
         AND status IN ('ready','pickedUp','onTheWay')
       ORDER BY created_at ASC`,
      [user.sub],
    );
    return {
      available: available.rows.map(mapOrder),
      active: mine.rows.map(mapOrder),
    };
  });

  app.post('/v1/food/rider/jobs/:id/claim', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...riderStaff]);
    const { id } = req.params as { id: string };
    const res = await pool.query(
      `UPDATE orders SET rider_id = $1
       WHERE id = $2 AND status = 'ready' AND rider_id IS NULL
       RETURNING *`,
      [user.sub, id],
    );
    if (!res.rowCount) {
      throw new AppError('Job unavailable', 409, 'unavailable');
    }
    return mapOrder(res.rows[0]);
  });

  app.post('/v1/food/rider/jobs/:id/pickup', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...riderStaff]);
    const { id } = req.params as { id: string };
    const order = await getOrder(id);
    assertRiderOrder(order, user.sub);
    if (order.status !== 'ready') {
      throw new AppError('Order not ready for pickup', 400, 'bad_status');
    }
    await pool.query(`UPDATE orders SET status = 'pickedUp' WHERE id = $1`, [
      id,
    ]);
    return getOrder(id);
  });

  app.post('/v1/food/rider/jobs/:id/on-the-way', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...riderStaff]);
    const { id } = req.params as { id: string };
    const order = await getOrder(id);
    assertRiderOrder(order, user.sub);
    if (order.status !== 'pickedUp') {
      throw new AppError('Pick up first', 400, 'bad_status');
    }
    await pool.query(`UPDATE orders SET status = 'onTheWay' WHERE id = $1`, [
      id,
    ]);
    return getOrder(id);
  });

  app.post('/v1/food/rider/jobs/:id/complete', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...riderStaff]);
    const { id } = req.params as { id: string };
    const body = z.object({ otp: z.string().min(4) }).parse(req.body ?? {});
    const order = await getOrder(id);
    assertRiderOrder(order, user.sub);
    return completeWithOtp(id, body.otp);
  });

  // ── Thin ops ─────────────────────────────────────────────────────────
  app.get('/v1/food/ops/board', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const orders = await pool.query(
      `SELECT * FROM orders
       WHERE status NOT IN ('delivered','cancelled')
          OR created_at > NOW() - INTERVAL '24 hours'
       ORDER BY created_at DESC
       LIMIT 100`,
    );
    const merchants = await pool.query(
      `SELECT * FROM merchants ORDER BY name`,
    );
    return {
      orders: orders.rows.map(mapOrder),
      merchants: merchants.rows.map(mapMerchant),
    };
  });

  app.post('/v1/food/ops/merchants', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const body = z
      .object({
        id: z.string().min(2).optional(),
        name: z.string().min(2),
        kind: z.enum(['restaurant', 'grocery']),
        subcity: z.string().min(1),
        coverageSubcities: z.array(z.string()).default([]),
        deliveryFeeEtb: z.number().int().nonnegative().default(70),
        minOrderEtb: z.number().int().nonnegative().default(150),
        etaMinutes: z.number().int().positive().default(35),
        hoursLabel: z.string().default('10:00 – 22:00'),
        coverUrl: z
          .string()
          .default(
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=900',
          ),
        ownerUserId: z.string().uuid().optional(),
      })
      .parse(req.body ?? {});
    const id =
      body.id ??
      `m-${body.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').slice(0, 24)}`;
    const coverage =
      body.coverageSubcities.length > 0
        ? body.coverageSubcities
        : [body.subcity];
    await pool.query(
      `INSERT INTO merchants (
        id, name, kind, subcity, is_open, eta_minutes, delivery_fee_etb,
        min_order_etb, rating, cover_url, hours_label, owner_user_id, coverage_subcities
      ) VALUES ($1,$2,$3,$4,TRUE,$5,$6,$7,4.0,$8,$9,$10,$11)`,
      [
        id,
        body.name,
        body.kind,
        body.subcity,
        body.etaMinutes,
        body.deliveryFeeEtb,
        body.minOrderEtb,
        body.coverUrl,
        body.hoursLabel,
        body.ownerUserId ?? null,
        JSON.stringify(coverage),
      ],
    );
    const res = await pool.query(`SELECT * FROM merchants WHERE id = $1`, [id]);
    return mapMerchant(res.rows[0]);
  });

  app.post('/v1/food/ops/merchants/:id/assign-owner', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const { id } = req.params as { id: string };
    const body = z
      .object({ ownerUserId: z.string().uuid().nullable() })
      .parse(req.body ?? {});
    const res = await pool.query(
      `UPDATE merchants SET owner_user_id = $2 WHERE id = $1 RETURNING *`,
      [id, body.ownerUserId],
    );
    if (!res.rowCount) throw new AppError('Not found', 404, 'not_found');
    return mapMerchant(res.rows[0]);
  });

  app.post('/v1/food/ops/orders/:id/reassign', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const { id } = req.params as { id: string };
    const body = z
      .object({ riderId: z.string().uuid().nullable() })
      .parse(req.body ?? {});
    const order = await getOrder(id);
    if (!['ready', 'pickedUp', 'onTheWay'].includes(order.status)) {
      throw new AppError('Order not in delivery phase', 400, 'bad_status');
    }
    await pool.query(`UPDATE orders SET rider_id = $2 WHERE id = $1`, [
      id,
      body.riderId,
    ]);
    return getOrder(id);
  });

  app.post('/v1/food/ops/orders/:id/cancel', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const { id } = req.params as { id: string };
    const body = z
      .object({ reason: z.string().default('Cancelled by support') })
      .parse(req.body ?? {});
    const order = await getOrder(id);
    if (order.status === 'delivered') {
      throw new AppError('Already delivered', 400, 'locked');
    }
    if (order.status === 'cancelled') return order;
    await pool.query(
      `UPDATE orders SET status = 'cancelled', cancelled_at = NOW(), reject_reason = $2
       WHERE id = $1`,
      [id, body.reason],
    );
    return getOrder(id);
  });

  await listen(app, port);
}

type CartLine = {
  item: MenuItemDto;
  quantity: number;
  selectedModifierIds: string[];
};

function isOps(roles: string[]) {
  return roles.some((r) => opsStaff.includes(r as (typeof opsStaff)[number]));
}

function coversSubcity(
  merchant: ReturnType<typeof mapMerchant>,
  subcity: string,
): boolean {
  const coverage = merchant.coverageSubcities;
  if (!coverage.length) return merchant.subcity === subcity;
  return coverage.includes(subcity);
}

async function requireOwnedMerchant(userId: string, roles: string[]) {
  const res = await pool.query(
    `SELECT * FROM merchants WHERE owner_user_id = $1 LIMIT 1`,
    [userId],
  );
  if (res.rowCount) return mapMerchant(res.rows[0]);
  if (isOps(roles)) {
    throw new AppError(
      'Claim or assign a merchant first',
      404,
      'no_merchant',
    );
  }
  throw new AppError('No merchant linked to this account', 404, 'no_merchant');
}

function assertMerchantOrder(
  order: ReturnType<typeof mapOrder>,
  merchantId: string,
) {
  if (order.merchantId !== merchantId) {
    throw new AppError('Forbidden', 403, 'forbidden');
  }
}

function assertRiderOrder(
  order: ReturnType<typeof mapOrder>,
  riderId: string,
) {
  if (order.riderId !== riderId) {
    throw new AppError('Not your job', 403, 'forbidden');
  }
}

async function completeWithOtp(id: string, otp: string) {
  const order = await getOrder(id);
  if (!['onTheWay', 'pickedUp'].includes(order.status)) {
    throw new AppError('Order is not out for delivery yet', 400, 'not_ready');
  }
  if (otp !== order.deliveryOtp) {
    throw new AppError('Wrong delivery OTP', 400, 'bad_otp');
  }
  await pool.query(`UPDATE orders SET status = 'delivered' WHERE id = $1`, [id]);
  return getOrder(id);
}

async function getCart(userId: string) {
  const res = await pool.query(`SELECT * FROM carts WHERE user_id = $1`, [
    userId,
  ]);
  if (!res.rowCount) {
    return {
      merchantId: null as string | null,
      lines: [] as CartLine[],
      subtotalEtb: 0,
    };
  }
  const lines = (res.rows[0].lines as CartLine[]) ?? [];
  const subtotalEtb = lines.reduce((sum, l) => {
    const mods = (l.item.modifiers ?? [])
      .filter((m: { id: string; priceEtb: number }) =>
        l.selectedModifierIds.includes(m.id),
      )
      .reduce((s: number, m: { priceEtb: number }) => s + m.priceEtb, 0);
    return sum + (l.item.priceEtb + mods) * l.quantity;
  }, 0);
  return {
    merchantId: res.rows[0].merchant_id as string | null,
    lines,
    subtotalEtb,
  };
}

async function saveCart(
  userId: string,
  merchantId: string | null,
  lines: CartLine[],
) {
  await pool.query(
    `INSERT INTO carts (user_id, merchant_id, lines, updated_at)
     VALUES ($1,$2,$3,NOW())
     ON CONFLICT (user_id) DO UPDATE
     SET merchant_id = EXCLUDED.merchant_id,
         lines = EXCLUDED.lines,
         updated_at = NOW()`,
    [userId, merchantId, JSON.stringify(lines)],
  );
}

async function getOrder(id: string) {
  const res = await pool.query(`SELECT * FROM orders WHERE id = $1`, [id]);
  if (!res.rowCount) throw new AppError('Order not found', 404, 'not_found');
  return mapOrder(res.rows[0]);
}

async function simulatePipeline(orderId: string) {
  const steps: Array<[string, number]> = [
    ['confirmed', 2000],
    ['preparing', 3000],
    ['ready', 2000],
    ['pickedUp', 2000],
    ['onTheWay', 2000],
  ];
  for (const [status, wait] of steps) {
    await new Promise((r) => setTimeout(r, wait));
    const cur = await pool.query(`SELECT status FROM orders WHERE id = $1`, [
      orderId,
    ]);
    if (!cur.rowCount) return;
    if (['cancelled', 'delivered'].includes(cur.rows[0].status)) return;
    await pool.query(`UPDATE orders SET status = $2 WHERE id = $1`, [
      orderId,
      status,
    ]);
  }
}

function sameMods(a: string[], b: string[]) {
  if (a.length !== b.length) return false;
  const sa = [...a].sort();
  const sb = [...b].sort();
  return sa.every((v, i) => v === sb[i]);
}

type ModifierDto = { id: string; name: string; priceEtb: number };

type MenuItemDto = {
  id: string;
  merchantId: string;
  name: string;
  description: string;
  priceEtb: number;
  photoUrl: string;
  available: boolean;
  modifiers: ModifierDto[];
};

type MerchantDto = {
  id: string;
  name: string;
  kind: string;
  subcity: string;
  isOpen: boolean;
  etaMinutes: number;
  deliveryFeeEtb: number;
  minOrderEtb: number;
  rating: number;
  coverUrl: string;
  hoursLabel: string;
  ownerUserId: string | null;
  coverageSubcities: string[];
};

type OrderDto = {
  id: string;
  customerId: string;
  merchantId: string;
  riderId: string | null;
  lines: unknown;
  address: unknown;
  notes: string;
  subtotalEtb: number;
  deliveryFeeEtb: number;
  grandTotalEtb: number;
  status: string;
  deliveryOtp: string;
  createdAt: unknown;
  cancelledAt: unknown;
  rejectReason: string | null;
  paymentMethod: 'cashOnDelivery';
};

function mapMerchant(row: Record<string, unknown>): MerchantDto {
  const coverageRaw = row.coverage_subcities;
  let coverageSubcities: string[] = [];
  if (Array.isArray(coverageRaw)) {
    coverageSubcities = coverageRaw.map(String);
  }
  return {
    id: row.id as string,
    name: row.name as string,
    kind: row.kind as string,
    subcity: row.subcity as string,
    isOpen: row.is_open as boolean,
    etaMinutes: row.eta_minutes as number,
    deliveryFeeEtb: row.delivery_fee_etb as number,
    minOrderEtb: row.min_order_etb as number,
    rating: Number(row.rating),
    coverUrl: row.cover_url as string,
    hoursLabel: row.hours_label as string,
    ownerUserId: (row.owner_user_id as string | null) ?? null,
    coverageSubcities,
  };
}

function mapMenuItem(row: Record<string, unknown>): MenuItemDto {
  const modifiers = Array.isArray(row.modifiers)
    ? (row.modifiers as ModifierDto[])
    : [];
  return {
    id: row.id as string,
    merchantId: row.merchant_id as string,
    name: row.name as string,
    description: row.description as string,
    priceEtb: row.price_etb as number,
    photoUrl: row.photo_url as string,
    available: Boolean(row.available),
    modifiers,
  };
}

function mapOrder(row: Record<string, unknown>): OrderDto {
  const subtotal = row.subtotal_etb as number;
  const fee = row.delivery_fee_etb as number;
  return {
    id: row.id as string,
    customerId: row.customer_id as string,
    merchantId: row.merchant_id as string,
    riderId: (row.rider_id as string | null) ?? null,
    lines: row.lines,
    address: row.address,
    notes: (row.notes as string) ?? '',
    subtotalEtb: subtotal,
    deliveryFeeEtb: fee,
    grandTotalEtb: subtotal + fee,
    status: row.status as string,
    deliveryOtp: row.delivery_otp as string,
    createdAt: row.created_at,
    cancelledAt: row.cancelled_at,
    rejectReason: (row.reject_reason as string | null) ?? null,
    paymentMethod: 'cashOnDelivery',
  };
}

function mapPlace(row: Record<string, unknown>) {
  return {
    id: row.id,
    userId: row.user_id,
    label: row.label,
    subcity: row.subcity,
    details: row.details,
    createdAt: row.created_at,
  };
}

async function seed() {
  await pool.query(`
    INSERT INTO merchants (
      id, name, kind, subcity, is_open, eta_minutes, delivery_fee_etb,
      min_order_etb, rating, cover_url, hours_label, coverage_subcities
    ) VALUES
    ('m-habesha','Habesha Kitfo House','restaurant','Bole',TRUE,35,80,200,4.7,'https://images.unsplash.com/photo-1604329760661-eeb838b49a5c?w=900','10:00 – 22:00','["Bole","CMC","Kirkos"]'),
    ('m-burger','Addis Burger Lab','restaurant','Kazanchis',TRUE,28,70,150,4.5,'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=900','11:00 – 23:00','["Kazanchis","Kirkos","Bole"]'),
    ('m-mart','Bole Fresh Mart','grocery','Bole',TRUE,40,60,250,4.3,'https://images.unsplash.com/photo-1542838132-92c53300491e?w=900','08:00 – 21:00','["Bole","CMC","Yeka"]'),
    ('m-closed','Piassa Pasta (closed)','restaurant','Arada',FALSE,45,90,180,4.1,'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=900','12:00 – 20:00','["Arada","Piassa"]')
    ON CONFLICT (id) DO NOTHING
  `);
  // Backfill coverage for older rows seeded without the column value.
  await pool.query(`
    UPDATE merchants SET coverage_subcities = '["Bole","CMC","Kirkos"]'::jsonb
    WHERE id = 'm-habesha' AND (coverage_subcities = '[]'::jsonb OR coverage_subcities IS NULL)
  `);
  await pool.query(`
    UPDATE merchants SET coverage_subcities = '["Kazanchis","Kirkos","Bole"]'::jsonb
    WHERE id = 'm-burger' AND (coverage_subcities = '[]'::jsonb OR coverage_subcities IS NULL)
  `);
  await pool.query(`
    UPDATE merchants SET coverage_subcities = '["Bole","CMC","Yeka"]'::jsonb
    WHERE id = 'm-mart' AND (coverage_subcities = '[]'::jsonb OR coverage_subcities IS NULL)
  `);
  await pool.query(`
    UPDATE merchants SET coverage_subcities = '["Arada","Piassa"]'::jsonb
    WHERE id = 'm-closed' AND (coverage_subcities = '[]'::jsonb OR coverage_subcities IS NULL)
  `);
  await pool.query(`
    INSERT INTO menu_items VALUES
    ('i-kitfo','m-habesha','Special Kitfo','Minced beef, mitmita, ayib, kocho.',420,'https://images.unsplash.com/photo-1544025162-d76694265947?w=700',TRUE,'[{"id":"mod-injera","name":"Extra injera","priceEtb":40},{"id":"mod-spicy","name":"Extra spicy","priceEtb":0}]'),
    ('i-tibs','m-habesha','Beef Tibs','Sautéed beef with rosemary & peppers.',380,'https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=700',TRUE,'[]'),
    ('i-burger','m-burger','Classic Smash Burger','Double patty, cheddar, house sauce.',320,'https://images.unsplash.com/photo-1550547660-d9450f859349?w=700',TRUE,'[{"id":"mod-fries","name":"Add fries","priceEtb":80}]'),
    ('i-shake','m-burger','Vanilla Shake','Thick milkshake.',150,'https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=700',TRUE,'[]'),
    ('i-milk','m-mart','Fresh Milk 1L','Chilled dairy.',95,'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=700',TRUE,'[]'),
    ('i-bread','m-mart','Sliced Bread','Soft white loaf.',55,'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=700',TRUE,'[]'),
    ('i-eggs','m-mart','Eggs (12)','Farm eggs pack.',180,'https://images.unsplash.com/photo-1582722879054-132667174001?w=700',TRUE,'[]')
    ON CONFLICT (id) DO NOTHING
  `);
}

boot().catch((err) => {
  console.error(err);
  process.exit(1);
});
