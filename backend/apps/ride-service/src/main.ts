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

const port = envInt('RIDE_PORT', 3004);
const pool = createPool(databaseUrl('maekel_ride'));
const VEHICLE = 'Economy';

async function boot() {
  await migrate(pool, [
    `CREATE TABLE IF NOT EXISTS places (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      subcity TEXT NOT NULL,
      lat DOUBLE PRECISION,
      lng DOUBLE PRECISION
    )`,
    `ALTER TABLE places ADD COLUMN IF NOT EXISTS lat DOUBLE PRECISION`,
    `ALTER TABLE places ADD COLUMN IF NOT EXISTS lng DOUBLE PRECISION`,
    `CREATE TABLE IF NOT EXISTS drivers (
      id TEXT PRIMARY KEY,
      user_id UUID,
      name TEXT NOT NULL,
      rating NUMERIC(2,1) NOT NULL,
      plate TEXT NOT NULL,
      car_model TEXT NOT NULL,
      photo_hint TEXT NOT NULL,
      phone_e164 TEXT NOT NULL,
      is_online BOOLEAN NOT NULL DEFAULT FALSE,
      is_approved BOOLEAN NOT NULL DEFAULT TRUE,
      last_lat DOUBLE PRECISION,
      last_lng DOUBLE PRECISION,
      last_location_at TIMESTAMPTZ
    )`,
    `ALTER TABLE drivers ADD COLUMN IF NOT EXISTS last_lat DOUBLE PRECISION`,
    `ALTER TABLE drivers ADD COLUMN IF NOT EXISTS last_lng DOUBLE PRECISION`,
    `ALTER TABLE drivers ADD COLUMN IF NOT EXISTS last_location_at TIMESTAMPTZ`,
    `CREATE TABLE IF NOT EXISTS fare_quotes (
      id UUID PRIMARY KEY,
      pickup_id TEXT NOT NULL REFERENCES places(id),
      dropoff_id TEXT NOT NULL REFERENCES places(id),
      vehicle_class TEXT NOT NULL,
      total_etb INT NOT NULL,
      eta_minutes INT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
    `CREATE TABLE IF NOT EXISTS trips (
      id UUID PRIMARY KEY,
      passenger_id UUID NOT NULL,
      pickup_id TEXT NOT NULL REFERENCES places(id),
      dropoff_id TEXT NOT NULL REFERENCES places(id),
      fare_etb INT NOT NULL,
      vehicle_class TEXT NOT NULL,
      status TEXT NOT NULL,
      driver_id TEXT REFERENCES drivers(id),
      passenger_rating INT,
      idempotency_key TEXT UNIQUE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      completed_at TIMESTAMPTZ
    )`,
  ]);
  await seed();

  const app = await createService({ name: 'ride-service', port });

  app.get('/v1/ride/places', async () => {
    const res = await pool.query(`SELECT * FROM places ORDER BY name`);
    return {
      items: res.rows.map((r) => ({
        id: r.id,
        name: r.name,
        subcity: r.subcity,
        lat: r.lat == null ? null : Number(r.lat),
        lng: r.lng == null ? null : Number(r.lng),
      })),
    };
  });

  app.post('/v1/ride/driver/location', async (req) => {
    const user = requireAuth(req);
    const body = z
      .object({
        lat: z.number().min(-90).max(90),
        lng: z.number().min(-180).max(180),
      })
      .parse(req.body ?? {});
    const driver = await ensureDriver(user.sub, user.phone);
    await pool.query(
      `UPDATE drivers
       SET last_lat = $2, last_lng = $3, last_location_at = NOW()
       WHERE id = $1`,
      [driver.id, body.lat, body.lng],
    );
    return {
      id: driver.id,
      lat: body.lat,
      lng: body.lng,
    };
  });

  app.post('/v1/ride/quotes', async (req) => {
    requireAuth(req);
    const body = z
      .object({ pickupId: z.string(), dropoffId: z.string() })
      .parse(req.body ?? {});
    if (body.pickupId === body.dropoffId) {
      throw new AppError('Pickup and dropoff must differ', 400, 'same_place');
    }
    const id = crypto.randomUUID();
    const total =
      120 +
      Math.abs(hash(body.pickupId) - hash(body.dropoffId)) % 200 +
      50;
    const eta = 8 + (hash(body.dropoffId) % 10);
    await pool.query(
      `INSERT INTO fare_quotes (id, pickup_id, dropoff_id, vehicle_class, total_etb, eta_minutes)
       VALUES ($1,$2,$3,$4,$5,$6)`,
      [id, body.pickupId, body.dropoffId, VEHICLE, total, eta],
    );
    return {
      id,
      pickupId: body.pickupId,
      dropoffId: body.dropoffId,
      vehicleClass: VEHICLE,
      totalEtb: total,
      etaMinutes: eta,
    };
  });

  app.post('/v1/ride/trips', async (req) => {
    const user = requireAuth(req);
    const body = z
      .object({ quoteId: z.string().uuid() })
      .parse(req.body ?? {});
    const idem = req.headers['idempotency-key'];
    if (typeof idem === 'string' && idem.length > 0) {
      const existing = await pool.query(
        `SELECT * FROM trips WHERE idempotency_key = $1`,
        [idem],
      );
      if (existing.rowCount) return mapTrip(existing.rows[0]);
    }

    const active = await pool.query(
      `SELECT id FROM trips
       WHERE passenger_id = $1
         AND status NOT IN ('completed','cancelled')
       LIMIT 1`,
      [user.sub],
    );
    if (active.rowCount) {
      throw new AppError('You already have an active trip', 409, 'active_trip');
    }

    const quote = await pool.query(`SELECT * FROM fare_quotes WHERE id = $1`, [
      body.quoteId,
    ]);
    if (!quote.rowCount) throw new AppError('Quote not found', 404, 'not_found');
    const q = quote.rows[0];
    const id = crypto.randomUUID();
    await pool.query(
      `INSERT INTO trips (
        id, passenger_id, pickup_id, dropoff_id, fare_etb, vehicle_class, status, idempotency_key
      ) VALUES ($1,$2,$3,$4,$5,$6,'requested',$7)`,
      [
        id,
        user.sub,
        q.pickup_id,
        q.dropoff_id,
        q.total_etb,
        q.vehicle_class,
        typeof idem === 'string' ? idem : null,
      ],
    );
    autoMatch(id).catch(() => undefined);
    return getTrip(id);
  });

  app.get('/v1/ride/trips/active', async (req) => {
    const user = requireAuth(req);
    const res = await pool.query(
      `SELECT * FROM trips
       WHERE passenger_id = $1
         AND status NOT IN ('completed','cancelled')
       ORDER BY created_at DESC LIMIT 1`,
      [user.sub],
    );
    return res.rowCount ? mapTrip(res.rows[0]) : null;
  });

  app.get('/v1/ride/trips', async (req) => {
    const user = requireAuth(req);
    const res = await pool.query(
      `SELECT * FROM trips WHERE passenger_id = $1 ORDER BY created_at DESC`,
      [user.sub],
    );
    return { items: res.rows.map(mapTrip) };
  });

  app.get('/v1/ride/trips/:id', async (req) => {
    requireAuth(req);
    const { id } = req.params as { id: string };
    return getTrip(id);
  });

  app.post('/v1/ride/trips/:id/cancel', async (req) => {
    requireAuth(req);
    const { id } = req.params as { id: string };
    const trip = await getTrip(id);
    if (
      !['requested', 'matching', 'assigned', 'arriving'].includes(trip.status)
    ) {
      throw new AppError('Cannot cancel now', 400, 'locked');
    }
    await pool.query(`UPDATE trips SET status = 'cancelled' WHERE id = $1`, [id]);
    return getTrip(id);
  });

  app.post('/v1/ride/trips/:id/rate', async (req) => {
    requireAuth(req);
    const { id } = req.params as { id: string };
    const body = z.object({ stars: z.number().int().min(1).max(5) }).parse(
      req.body ?? {},
    );
    const trip = await getTrip(id);
    if (trip.status !== 'completed') {
      throw new AppError('Trip not completed', 400, 'not_completed');
    }
    await pool.query(
      `UPDATE trips SET passenger_rating = $2 WHERE id = $1`,
      [id, body.stars],
    );
    return getTrip(id);
  });

  app.get('/v1/ride/driver/me', async (req) => {
    const user = requireAuth(req);
    return ensureDriver(user.sub, user.phone);
  });

  app.post('/v1/ride/driver/online', async (req) => {
    const user = requireAuth(req);
    const body = z.object({ online: z.boolean() }).parse(req.body ?? {});
    const driver = await ensureDriver(user.sub, user.phone);
    await pool.query(`UPDATE drivers SET is_online = $2 WHERE id = $1`, [
      driver.id,
      body.online,
    ]);
    return ensureDriver(user.sub, user.phone);
  });

  app.get('/v1/ride/driver/offers', async (req) => {
    const user = requireAuth(req);
    const driver = await ensureDriver(user.sub, user.phone);
    const res = await pool.query(
      `SELECT * FROM trips
       WHERE status = 'matching'
          OR (status = 'assigned' AND driver_id = $1)
       ORDER BY created_at DESC`,
      [driver.id],
    );
    return { items: res.rows.map(mapTrip) };
  });

  app.get('/v1/ride/driver/active', async (req) => {
    const user = requireAuth(req);
    const driver = await ensureDriver(user.sub, user.phone);
    const res = await pool.query(
      `SELECT * FROM trips
       WHERE driver_id = $1
         AND status NOT IN ('completed','cancelled','requested','matching')
       ORDER BY created_at DESC LIMIT 1`,
      [driver.id],
    );
    return res.rowCount ? mapTrip(res.rows[0]) : null;
  });

  app.post('/v1/ride/driver/trips/:id/accept', async (req) => {
    const user = requireAuth(req);
    const driver = await ensureDriver(user.sub, user.phone);
    const { id } = req.params as { id: string };
    await pool.query(
      `UPDATE trips SET driver_id = $2, status = 'assigned' WHERE id = $1`,
      [id, driver.id],
    );
    return getTrip(id);
  });

  app.post('/v1/ride/driver/trips/:id/advance', async (req) => {
    requireAuth(req);
    const { id } = req.params as { id: string };
    const trip = await getTrip(id);
    const next: Record<string, string> = {
      assigned: 'arriving',
      arriving: 'arrived',
      arrived: 'inProgress',
      inProgress: 'completed',
    };
    const status = next[trip.status] ?? trip.status;
    await pool.query(
      `UPDATE trips SET status = $2,
        completed_at = CASE WHEN $2 = 'completed' THEN NOW() ELSE completed_at END
       WHERE id = $1`,
      [id, status],
    );
    return getTrip(id);
  });

  app.post('/v1/ride/driver/trips/:id/confirm-cash', async (req) => {
    requireAuth(req);
    const { id } = req.params as { id: string };
    await pool.query(
      `UPDATE trips SET status = 'completed', completed_at = NOW() WHERE id = $1`,
      [id],
    );
    return getTrip(id);
  });

  app.get('/v1/ride/drivers/:id', async (req) => {
    const { id } = req.params as { id: string };
    const res = await pool.query(`SELECT * FROM drivers WHERE id = $1`, [id]);
    if (!res.rowCount) throw new AppError('Driver not found', 404, 'not_found');
    return mapDriver(res.rows[0]);
  });

  await listen(app, port);
}

function hash(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0;
  return Math.abs(h);
}

async function getTrip(id: string) {
  const res = await pool.query(`SELECT * FROM trips WHERE id = $1`, [id]);
  if (!res.rowCount) throw new AppError('Trip not found', 404, 'not_found');
  return mapTrip(res.rows[0]);
}

async function ensureDriver(userId: string, phone: string) {
  const existing = await pool.query(
    `SELECT * FROM drivers WHERE user_id = $1`,
    [userId],
  );
  if (existing.rowCount) return mapDriver(existing.rows[0]);
  const id = `drv-user-${userId}`;
  await pool.query(
    `INSERT INTO drivers (id, user_id, name, rating, plate, car_model, photo_hint, phone_e164, is_online, is_approved)
     VALUES ($1,$2,'You (Driver)',5.0,'AA-DEMO-01','Economy sedan','YO',$3,FALSE,TRUE)
     ON CONFLICT (id) DO NOTHING`,
    [id, userId, phone],
  );
  const res = await pool.query(`SELECT * FROM drivers WHERE id = $1`, [id]);
  return mapDriver(res.rows[0]);
}

async function autoMatch(tripId: string) {
  await sleep(2000);
  await pool.query(
    `UPDATE trips SET status = 'matching' WHERE id = $1 AND status = 'requested'`,
    [tripId],
  );
  await sleep(2000);
  const online = await pool.query(
    `SELECT id FROM drivers WHERE is_online = TRUE AND is_approved = TRUE LIMIT 1`,
  );
  const seed = await pool.query(`SELECT id FROM drivers WHERE id = 'drv-1'`);
  const driverId = online.rowCount
    ? online.rows[0].id
    : seed.rows[0]?.id;
  if (!driverId) return;
  await pool.query(
    `UPDATE trips SET status = 'assigned', driver_id = $2
     WHERE id = $1 AND status IN ('matching','requested')`,
    [tripId, driverId],
  );
  await sleep(2000);
  await pool.query(
    `UPDATE trips SET status = 'arriving' WHERE id = $1 AND status = 'assigned'`,
    [tripId],
  );
}

function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

function mapTrip(row: Record<string, unknown>) {
  return {
    id: row.id,
    passengerId: row.passenger_id,
    pickupId: row.pickup_id,
    dropoffId: row.dropoff_id,
    fareEtb: row.fare_etb,
    vehicleClass: row.vehicle_class,
    status: row.status,
    driverId: row.driver_id,
    passengerRating: row.passenger_rating,
    createdAt: row.created_at,
    completedAt: row.completed_at,
  };
}

function mapDriver(row: Record<string, unknown>) {
  return {
    id: row.id,
    userId: row.user_id,
    name: row.name,
    rating: Number(row.rating),
    plate: row.plate,
    carModel: row.car_model,
    photoHint: row.photo_hint,
    phoneE164: row.phone_e164,
    isOnline: row.is_online,
    isApproved: row.is_approved,
    lat: row.last_lat == null ? null : Number(row.last_lat),
    lng: row.last_lng == null ? null : Number(row.last_lng),
  };
}

async function seed() {
  const places: Array<[string, string, string, number, number]> = [
    ['p-bole', 'Bole Atlas', 'Bole', 8.9978, 38.7869],
    ['p-airport', 'Bole Airport', 'Bole', 8.9779, 38.7993],
    ['p-cmc', 'CMC Michael', 'Yeka', 9.0227, 38.8228],
    ['p-piassa', 'Piassa', 'Arada', 9.033, 38.752],
    ['p-mexico', 'Mexico Square', 'Kirkos', 9.0105, 38.7445],
    ['p-sarbet', 'Sarbet', 'Nifas Silk', 8.9806, 38.7578],
  ];
  for (const [id, name, subcity, lat, lng] of places) {
    await pool.query(
      `INSERT INTO places (id, name, subcity, lat, lng)
       VALUES ($1,$2,$3,$4,$5)
       ON CONFLICT (id) DO UPDATE
       SET name = EXCLUDED.name,
           subcity = EXCLUDED.subcity,
           lat = EXCLUDED.lat,
           lng = EXCLUDED.lng`,
      [id, name, subcity, lat, lng],
    );
  }

  await pool.query(`
    INSERT INTO drivers (id, name, rating, plate, car_model, photo_hint, phone_e164, is_online, is_approved, last_lat, last_lng, last_location_at)
    VALUES
    ('drv-1','Abebe G.',4.9,'AA-3-12345','Toyota Corolla','AG','+251911200001',FALSE,TRUE,9.01,38.78,NOW()),
    ('drv-2','Mulu S.',4.7,'AA-4-77821','Hyundai Accent','MS','+251911200002',FALSE,TRUE,9.02,38.76,NOW())
    ON CONFLICT (id) DO UPDATE
    SET last_lat = COALESCE(drivers.last_lat, EXCLUDED.last_lat),
        last_lng = COALESCE(drivers.last_lng, EXCLUDED.last_lng)
  `);
}

boot().catch((err) => {
  console.error(err);
  process.exit(1);
});
