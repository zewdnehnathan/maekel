import {
  AppError,
  createPool,
  createService,
  databaseUrl,
  envInt,
  listen,
  migrate,
  requireAuth,
} from '@maekel/shared';
import { z } from 'zod';

const port = envInt('FOOD_PORT', 3003);
const pool = createPool(databaseUrl('maekel_food'));

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
  ]);
  await seed();

  const app = await createService({ name: 'food-service', port });

  app.get('/v1/food/merchants', async (req) => {
    const q = z
      .object({
        kind: z.enum(['restaurant', 'grocery']).optional(),
        query: z.string().optional(),
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

  app.get('/v1/food/cart', async (req) => {
    const user = requireAuth(req);
    const cart = await getCart(user.sub);
    return cart;
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
    await saveCart(
      user.sub,
      lines.length ? cart.merchantId : null,
      lines,
    );
    return getCart(user.sub);
  });

  app.delete('/v1/food/cart', async (req) => {
    const user = requireAuth(req);
    await saveCart(user.sub, null, []);
    return getCart(user.sub);
  });

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
    simulatePipeline(id).catch(() => undefined);
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
    requireAuth(req);
    const { id } = req.params as { id: string };
    const order = await getOrder(id);
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
    const order = await getOrder(id);
    if (!['onTheWay', 'pickedUp'].includes(order.status)) {
      throw new AppError('Order is not out for delivery yet', 400, 'not_ready');
    }
    if (body.otp !== order.deliveryOtp) {
      throw new AppError('Wrong delivery OTP', 400, 'bad_otp');
    }
    await pool.query(`UPDATE orders SET status = 'delivered' WHERE id = $1`, [
      id,
    ]);
    return getOrder(id);
  });

  app.post('/v1/food/orders/:id/advance', async (req) => {
    requireAuth(req);
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

  await listen(app, port);
}

type CartLine = {
  item: ReturnType<typeof mapMenuItem>;
  quantity: number;
  selectedModifierIds: string[];
};

async function getCart(userId: string) {
  const res = await pool.query(`SELECT * FROM carts WHERE user_id = $1`, [
    userId,
  ]);
  if (!res.rowCount) {
    return { merchantId: null as string | null, lines: [] as CartLine[], subtotalEtb: 0 };
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

function mapMerchant(row: Record<string, unknown>) {
  return {
    id: row.id,
    name: row.name,
    kind: row.kind,
    subcity: row.subcity,
    isOpen: row.is_open,
    etaMinutes: row.eta_minutes,
    deliveryFeeEtb: row.delivery_fee_etb,
    minOrderEtb: row.min_order_etb,
    rating: Number(row.rating),
    coverUrl: row.cover_url,
    hoursLabel: row.hours_label,
  };
}

function mapMenuItem(row: Record<string, unknown>) {
  return {
    id: row.id,
    merchantId: row.merchant_id,
    name: row.name,
    description: row.description,
    priceEtb: row.price_etb,
    photoUrl: row.photo_url,
    available: row.available,
    modifiers: row.modifiers ?? [],
  };
}

function mapOrder(row: Record<string, unknown>) {
  const subtotal = row.subtotal_etb as number;
  const fee = row.delivery_fee_etb as number;
  return {
    id: row.id,
    customerId: row.customer_id,
    merchantId: row.merchant_id,
    lines: row.lines,
    address: row.address,
    notes: row.notes,
    subtotalEtb: subtotal,
    deliveryFeeEtb: fee,
    grandTotalEtb: subtotal + fee,
    status: row.status,
    deliveryOtp: row.delivery_otp,
    createdAt: row.created_at,
    cancelledAt: row.cancelled_at,
    paymentMethod: 'cashOnDelivery',
  };
}

async function seed() {
  await pool.query(`
    INSERT INTO merchants VALUES
    ('m-habesha','Habesha Kitfo House','restaurant','Bole',TRUE,35,80,200,4.7,'https://images.unsplash.com/photo-1604329760661-eeb838b49a5c?w=900','10:00 – 22:00'),
    ('m-burger','Addis Burger Lab','restaurant','Kazanchis',TRUE,28,70,150,4.5,'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=900','11:00 – 23:00'),
    ('m-mart','Bole Fresh Mart','grocery','Bole',TRUE,40,60,250,4.3,'https://images.unsplash.com/photo-1542838132-92c53300491e?w=900','08:00 – 21:00'),
    ('m-closed','Piassa Pasta (closed)','restaurant','Arada',FALSE,45,90,180,4.1,'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=900','12:00 – 20:00')
    ON CONFLICT (id) DO NOTHING
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
