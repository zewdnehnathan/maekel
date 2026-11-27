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
import type { Pool } from 'pg';
import { z } from 'zod';

const port = envInt('RIDE_PORT', 3004);
const pool = createPool(databaseUrl('maekel_ride'));
const VEHICLE = 'Economy';
const OFFER_TTL_SEC = 45;
const opsStaff = ['ride_ops', 'platform_admin'] as const;

const SERVICE_BBOX = {
  minLat: 8.83,
  maxLat: 9.15,
  minLng: 38.62,
  maxLng: 39.0,
};

const DEFAULT_CONFIG = {
  baseEtb: 100,
  perKmEtb: 16,
  minFareEtb: 120,
  offerRadiusKm: 8,
  etaBaseMin: 5,
  etaMinPerKm: 2.5,
};

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
      is_approved BOOLEAN NOT NULL DEFAULT FALSE,
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
    `ALTER TABLE fare_quotes ADD COLUMN IF NOT EXISTS pickup_lat DOUBLE PRECISION`,
    `ALTER TABLE fare_quotes ADD COLUMN IF NOT EXISTS pickup_lng DOUBLE PRECISION`,
    `ALTER TABLE fare_quotes ADD COLUMN IF NOT EXISTS dropoff_lat DOUBLE PRECISION`,
    `ALTER TABLE fare_quotes ADD COLUMN IF NOT EXISTS dropoff_lng DOUBLE PRECISION`,
    `ALTER TABLE fare_quotes ADD COLUMN IF NOT EXISTS distance_km NUMERIC(8,3)`,
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
    `ALTER TABLE trips ADD COLUMN IF NOT EXISTS eta_minutes INT`,
    `ALTER TABLE trips ADD COLUMN IF NOT EXISTS offer_expires_at TIMESTAMPTZ`,
    `ALTER TABLE trips ADD COLUMN IF NOT EXISTS cancel_reason TEXT`,
    `ALTER TABLE trips ADD COLUMN IF NOT EXISTS pickup_lat DOUBLE PRECISION`,
    `ALTER TABLE trips ADD COLUMN IF NOT EXISTS pickup_lng DOUBLE PRECISION`,
    `ALTER TABLE trips ADD COLUMN IF NOT EXISTS dropoff_lat DOUBLE PRECISION`,
    `ALTER TABLE trips ADD COLUMN IF NOT EXISTS dropoff_lng DOUBLE PRECISION`,
    `ALTER TABLE trips ADD COLUMN IF NOT EXISTS distance_km NUMERIC(8,3)`,
    `CREATE TABLE IF NOT EXISTS misconduct_reports (
      id UUID PRIMARY KEY,
      trip_id UUID NOT NULL REFERENCES trips(id),
      reporter_user_id UUID NOT NULL,
      reporter_role TEXT NOT NULL,
      accused_user_id UUID NOT NULL,
      reason TEXT NOT NULL,
      note TEXT,
      status TEXT NOT NULL DEFAULT 'pending',
      review_note TEXT,
      reviewed_by UUID,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      reviewed_at TIMESTAMPTZ
    )`,
    `CREATE TABLE IF NOT EXISTS ride_config (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )`,
  ]);
  await seed();
  await ensureDefaultConfig();

  const app = await createService({ name: 'ride-service', port });

  app.get('/v1/ride/places', async () => {
    const res = await pool.query(
      `SELECT * FROM places WHERE id NOT LIKE 'pin-%' ORDER BY name`,
    );
    return { items: res.rows.map(mapPlace) };
  });

  app.get('/v1/ride/config', async () => getFareConfig());

  app.post('/v1/ride/driver/location', async (req) => {
    const user = requireAuth(req);
    const body = z
      .object({
        lat: z.number().min(-90).max(90),
        lng: z.number().min(-180).max(180),
      })
      .parse(req.body ?? {});
    const driver = await ensureDriver(user.sub, user.phone, user.roles);
    await pool.query(
      `UPDATE drivers
       SET last_lat = $2, last_lng = $3, last_location_at = NOW()
       WHERE id = $1`,
      [driver.id, body.lat, body.lng],
    );
    return { id: driver.id, lat: body.lat, lng: body.lng };
  });

  app.post('/v1/ride/quotes', async (req) => {
    requireAuth(req);
    const body = z
      .object({
        pickupId: z.string().optional(),
        dropoffId: z.string().optional(),
        pickupLat: z.number().min(-90).max(90),
        pickupLng: z.number().min(-180).max(180),
        dropoffLat: z.number().min(-90).max(90),
        dropoffLng: z.number().min(-180).max(180),
      })
      .parse(req.body ?? {});

    if (!isInServiceArea(body.pickupLat, body.pickupLng)) {
      throw new AppError(
        'Pickup is outside the Addis Ababa service area',
        400,
        'out_of_area',
      );
    }
    if (!isInServiceArea(body.dropoffLat, body.dropoffLng)) {
      throw new AppError(
        'Drop-off is outside the Addis Ababa service area',
        400,
        'out_of_area',
      );
    }

    const distanceKm = haversineKm(
      body.pickupLat,
      body.pickupLng,
      body.dropoffLat,
      body.dropoffLng,
    );
    if (distanceKm < 0.2) {
      throw new AppError(
        'Pickup and drop-off are too close',
        400,
        'same_place',
      );
    }

    const pickupId =
      body.pickupId ??
      (await ensurePinPlace(body.pickupLat, body.pickupLng, 'Pickup pin'));
    const dropoffId =
      body.dropoffId ??
      (await ensurePinPlace(body.dropoffLat, body.dropoffLng, 'Drop-off pin'));
    if (pickupId === dropoffId) {
      throw new AppError('Pickup and dropoff must differ', 400, 'same_place');
    }

    const cfg = await getFareConfig();
    const total = Math.max(
      cfg.minFareEtb,
      Math.round(cfg.baseEtb + cfg.perKmEtb * distanceKm),
    );
    const eta = Math.max(
      3,
      Math.round(cfg.etaBaseMin + cfg.etaMinPerKm * distanceKm),
    );

    const id = crypto.randomUUID();
    await pool.query(
      `INSERT INTO fare_quotes (
        id, pickup_id, dropoff_id, vehicle_class, total_etb, eta_minutes,
        pickup_lat, pickup_lng, dropoff_lat, dropoff_lng, distance_km
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)`,
      [
        id,
        pickupId,
        dropoffId,
        VEHICLE,
        total,
        eta,
        body.pickupLat,
        body.pickupLng,
        body.dropoffLat,
        body.dropoffLng,
        distanceKm,
      ],
    );
    return {
      id,
      pickupId,
      dropoffId,
      vehicleClass: VEHICLE,
      totalEtb: total,
      etaMinutes: eta,
      distanceKm: Number(distanceKm.toFixed(2)),
      breakdown: {
        baseEtb: cfg.baseEtb,
        perKmEtb: cfg.perKmEtb,
        minFareEtb: cfg.minFareEtb,
        distanceKm: Number(distanceKm.toFixed(2)),
      },
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
        id, passenger_id, pickup_id, dropoff_id, fare_etb, vehicle_class, status,
        idempotency_key, eta_minutes, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng, distance_km
      ) VALUES ($1,$2,$3,$4,$5,$6,'requested',$7,$8,$9,$10,$11,$12,$13)`,
      [
        id,
        user.sub,
        q.pickup_id,
        q.dropoff_id,
        q.total_etb,
        q.vehicle_class,
        typeof idem === 'string' ? idem : null,
        q.eta_minutes,
        q.pickup_lat,
        q.pickup_lng,
        q.dropoff_lat,
        q.dropoff_lng,
        q.distance_km,
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
      !['requested', 'matching', 'assigned', 'arriving'].includes(
        trip.status as string,
      )
    ) {
      throw new AppError('Cannot cancel now', 400, 'locked');
    }
    await pool.query(
      `UPDATE trips SET status = 'cancelled', cancel_reason = 'passenger_cancel',
        offer_expires_at = NULL
       WHERE id = $1`,
      [id],
    );
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
    await pool.query(`UPDATE trips SET passenger_rating = $2 WHERE id = $1`, [
      id,
      body.stars,
    ]);
    return getTrip(id);
  });

  app.get('/v1/ride/driver/me', async (req) => {
    const user = requireAuth(req);
    return ensureDriver(user.sub, user.phone, user.roles);
  });

  app.post('/v1/ride/driver/online', async (req) => {
    const user = requireAuth(req);
    const body = z.object({ online: z.boolean() }).parse(req.body ?? {});
    const driver = await ensureDriver(user.sub, user.phone, user.roles);
    if (body.online && !driver.isApproved) {
      throw new AppError(
        'Driver is not approved to go online. Ask Ride ops to approve your account.',
        403,
        'not_approved',
      );
    }
    await pool.query(`UPDATE drivers SET is_online = $2 WHERE id = $1`, [
      driver.id,
      body.online,
    ]);
    return ensureDriver(user.sub, user.phone, user.roles);
  });

  app.get('/v1/ride/driver/offers', async (req) => {
    const user = requireAuth(req);
    const driver = await ensureDriver(user.sub, user.phone, user.roles);
    await expireStaleOffers();
    const cfg = await getFareConfig();
    const res = await pool.query(
      `SELECT * FROM trips
       WHERE status = 'matching'
          OR (status = 'assigned' AND driver_id = $1)
       ORDER BY created_at DESC`,
      [driver.id],
    );
    const items = res.rows
      .map(mapTrip)
      .filter((trip) => {
        if (trip.status === 'assigned') return trip.driverId === driver.id;
        if (driver.lat == null || driver.lng == null) return false;
        if (trip.pickupLat == null || trip.pickupLng == null) return true;
        return (
          haversineKm(
            driver.lat as number,
            driver.lng as number,
            trip.pickupLat as number,
            trip.pickupLng as number,
          ) <= cfg.offerRadiusKm
        );
      });
    return { items };
  });

  app.get('/v1/ride/driver/active', async (req) => {
    const user = requireAuth(req);
    const driver = await ensureDriver(user.sub, user.phone, user.roles);
    const res = await pool.query(
      `SELECT * FROM trips
       WHERE driver_id = $1
         AND status NOT IN ('completed','cancelled','requested','matching')
       ORDER BY created_at DESC LIMIT 1`,
      [driver.id],
    );
    return res.rowCount ? mapTrip(res.rows[0]) : null;
  });

  app.get('/v1/ride/driver/earnings/today', async (req) => {
    const user = requireAuth(req);
    const driver = await ensureDriver(user.sub, user.phone, user.roles);
    const res = await pool.query(
      `SELECT * FROM trips
       WHERE driver_id = $1
         AND status = 'completed'
         AND completed_at >= date_trunc('day', NOW())
       ORDER BY completed_at DESC`,
      [driver.id],
    );
    const items = res.rows.map(mapTrip);
    const totalEtb = items.reduce(
      (sum, t) => sum + (t.fareEtb as number),
      0,
    );
    return { totalEtb, items };
  });

  app.post('/v1/ride/driver/trips/:id/accept', async (req) => {
    const user = requireAuth(req);
    const driver = await ensureDriver(user.sub, user.phone, user.roles);
    if (!driver.isApproved || !driver.isOnline) {
      throw new AppError('Go online as an approved driver first', 403, 'offline');
    }
    const { id } = req.params as { id: string };
    await expireStaleOffers();
    const trip = await getTrip(id);
    if (trip.status !== 'matching') {
      throw new AppError('Offer is no longer available', 409, 'offer_gone');
    }
    if (
      trip.offerExpiresAt &&
      new Date(trip.offerExpiresAt as string).getTime() < Date.now()
    ) {
      await pool.query(
        `UPDATE trips SET status = 'cancelled', cancel_reason = 'no_driver',
          offer_expires_at = NULL
         WHERE id = $1 AND status = 'matching'`,
        [id],
      );
      throw new AppError('Offer expired', 409, 'offer_expired');
    }
    const cfg = await getFareConfig();
    if (
      driver.lat != null &&
      driver.lng != null &&
      trip.pickupLat != null &&
      trip.pickupLng != null
    ) {
      const dist = haversineKm(
        driver.lat as number,
        driver.lng as number,
        trip.pickupLat as number,
        trip.pickupLng as number,
      );
      if (dist > cfg.offerRadiusKm) {
        throw new AppError(
          'Pickup is outside your offer radius',
          403,
          'too_far',
        );
      }
    }
    const updated = await pool.query(
      `UPDATE trips SET driver_id = $2, status = 'assigned', offer_expires_at = NULL
       WHERE id = $1 AND status = 'matching'
       RETURNING *`,
      [id, driver.id],
    );
    if (!updated.rowCount) {
      throw new AppError('Offer is no longer available', 409, 'offer_gone');
    }
    return mapTrip(updated.rows[0]);
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
    const status = next[trip.status as string] ?? trip.status;
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

  app.post('/v1/ride/driver/trips/:id/report', async (req) => {
    const user = requireAuth(req);
    const driver = await ensureDriver(user.sub, user.phone, user.roles);
    const { id } = req.params as { id: string };
    const body = z
      .object({
        reason: z.enum(['no_show', 'wrong_pin', 'other']),
        note: z.string().max(200).optional(),
      })
      .parse(req.body ?? {});
    const trip = await getTrip(id);
    if (trip.driverId !== driver.id) {
      throw new AppError('Not your trip', 403, 'forbidden');
    }
    if (['completed', 'cancelled'].includes(trip.status as string)) {
      throw new AppError('Trip already closed', 400, 'locked');
    }
    const reason = `driver_report:${body.reason}`;
    await pool.query(
      `UPDATE trips SET status = 'cancelled', cancel_reason = $2,
        offer_expires_at = NULL
       WHERE id = $1`,
      [id, body.note ? `${reason}:${body.note}` : reason],
    );
    return getTrip(id);
  });

  app.get('/v1/ride/drivers/:id', async (req) => {
    const { id } = req.params as { id: string };
    const res = await pool.query(`SELECT * FROM drivers WHERE id = $1`, [id]);
    if (!res.rowCount) throw new AppError('Driver not found', 404, 'not_found');
    return mapDriver(res.rows[0]);
  });

  // ── Ops ──────────────────────────────────────────────────────────────
  app.get('/v1/ride/ops/config', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    return getFareConfig();
  });

  app.patch('/v1/ride/ops/config', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const body = z
      .object({
        baseEtb: z.number().int().min(0).max(5000).optional(),
        perKmEtb: z.number().min(0).max(500).optional(),
        minFareEtb: z.number().int().min(0).max(10000).optional(),
        offerRadiusKm: z.number().min(1).max(50).optional(),
        etaBaseMin: z.number().min(0).max(60).optional(),
        etaMinPerKm: z.number().min(0).max(30).optional(),
      })
      .parse(req.body ?? {});
    const current = await getFareConfig();
    const next = { ...current, ...body };
    await setConfig('base_etb', String(next.baseEtb));
    await setConfig('per_km_etb', String(next.perKmEtb));
    await setConfig('min_fare_etb', String(next.minFareEtb));
    await setConfig('offer_radius_km', String(next.offerRadiusKm));
    await setConfig('eta_base_min', String(next.etaBaseMin));
    await setConfig('eta_min_per_km', String(next.etaMinPerKm));
    return getFareConfig();
  });

  app.get('/v1/ride/ops/drivers', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const res = await pool.query(
      `SELECT * FROM drivers ORDER BY is_approved DESC, name ASC`,
    );
    return { items: res.rows.map(mapDriver) };
  });

  app.post('/v1/ride/ops/drivers/:id/approve', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const { id } = req.params as { id: string };
    const body = z.object({ approved: z.boolean() }).parse(req.body ?? {});
    const res = await pool.query(
      `UPDATE drivers SET is_approved = $2,
        is_online = CASE WHEN $2 = FALSE THEN FALSE ELSE is_online END
       WHERE id = $1 RETURNING *`,
      [id, body.approved],
    );
    if (!res.rowCount) throw new AppError('Driver not found', 404, 'not_found');
    return mapDriver(res.rows[0]);
  });

  app.get('/v1/ride/ops/trips/active', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const res = await pool.query(
      `SELECT * FROM trips
       WHERE status NOT IN ('completed','cancelled')
       ORDER BY created_at DESC
       LIMIT 100`,
    );
    return { items: res.rows.map(mapTrip) };
  });

  app.post('/v1/ride/ops/trips/:id/cancel', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const { id } = req.params as { id: string };
    const body = z
      .object({ note: z.string().max(200).optional() })
      .parse(req.body ?? {});
    const trip = await getTrip(id);
    if (['completed', 'cancelled'].includes(trip.status as string)) {
      throw new AppError('Trip already closed', 400, 'locked');
    }
    await pool.query(
      `UPDATE trips SET status = 'cancelled',
        cancel_reason = $2,
        offer_expires_at = NULL
       WHERE id = $1`,
      [id, body.note ? `ops_cancel:${body.note}` : 'ops_cancel'],
    );
    return getTrip(id);
  });

  // ── Safety / misconduct reports (#8) ─────────────────────────────────
  app.post('/v1/ride/trips/:id/report-misconduct', async (req) => {
    const user = requireAuth(req);
    const { id } = req.params as { id: string };
    const body = z
      .object({
        reason: z.enum([
          'unsafe_driving',
          'harassment',
          'rude_behavior',
          'vehicle_issue',
          'other',
        ]),
        note: z.string().max(500).optional(),
      })
      .parse(req.body ?? {});

    const tripRow = await pool.query(`SELECT * FROM trips WHERE id = $1`, [id]);
    if (!tripRow.rowCount) throw new AppError('Not found', 404, 'not_found');
    const trip = tripRow.rows[0] as Record<string, unknown>;
    const status = trip.status as string;
    if (!['completed', 'cancelled', 'in_progress'].includes(status)) {
      throw new AppError(
        'Report after the trip is underway or finished',
        400,
        'bad_status',
      );
    }

    const passengerId = trip.passenger_id as string;
    const driverId = trip.driver_id as string | null;
    if (!driverId) {
      throw new AppError('No driver on this trip', 400, 'no_driver');
    }
    const driver = await pool.query(
      `SELECT user_id FROM drivers WHERE id = $1`,
      [driverId],
    );
    const driverUserId = driver.rows[0]?.user_id as string | undefined;
    if (!driverUserId) {
      throw new AppError('Driver account missing', 400, 'no_driver');
    }

    let reporterRole: 'passenger' | 'driver';
    let accusedUserId: string;
    if (user.sub === passengerId) {
      reporterRole = 'passenger';
      accusedUserId = driverUserId;
    } else if (user.sub === driverUserId) {
      reporterRole = 'driver';
      accusedUserId = passengerId;
    } else {
      throw new AppError('Only trip parties can report', 403, 'forbidden');
    }

    const dup = await pool.query(
      `SELECT id FROM misconduct_reports
       WHERE trip_id = $1 AND reporter_user_id = $2 AND status = 'pending'`,
      [id, user.sub],
    );
    if (dup.rowCount) {
      throw new AppError('Report already pending', 409, 'duplicate');
    }

    const reportId = crypto.randomUUID();
    await pool.query(
      `INSERT INTO misconduct_reports (
        id, trip_id, reporter_user_id, reporter_role, accused_user_id,
        reason, note, status
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,'pending')`,
      [
        reportId,
        id,
        user.sub,
        reporterRole,
        accusedUserId,
        body.reason,
        body.note ?? null,
      ],
    );
    const res = await pool.query(
      `SELECT * FROM misconduct_reports WHERE id = $1`,
      [reportId],
    );
    return mapMisconductReport(res.rows[0]);
  });

  app.get('/v1/ride/ops/misconduct-reports', async (req) => {
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
            `SELECT * FROM misconduct_reports ORDER BY created_at DESC LIMIT 100`,
          )
        : await pool.query(
            `SELECT * FROM misconduct_reports WHERE status = $1
             ORDER BY created_at ASC LIMIT 100`,
            [q.status],
          );
    return { items: res.rows.map(mapMisconductReport) };
  });

  app.post('/v1/ride/ops/misconduct-reports/:id/review', async (req) => {
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
      `SELECT * FROM misconduct_reports WHERE id = $1`,
      [id],
    );
    if (!reportRes.rowCount) throw new AppError('Not found', 404, 'not_found');
    const report = reportRes.rows[0] as Record<string, unknown>;
    if (report.status !== 'pending') {
      throw new AppError('Already reviewed', 400, 'bad_status');
    }

    let newStatus = 'ignored';
    if (body.action === 'warn' || body.action === 'suspend') {
      await moderateIdentityUser({
        userId: report.accused_user_id as string,
        action: body.action,
        message:
          body.message ??
          (body.action === 'warn'
            ? 'Warning: a Ride safety report was filed about your account.'
            : undefined),
        note: body.note ?? `Ride misconduct report ${id}`,
      });
      newStatus = body.action === 'warn' ? 'warned' : 'suspended';
    }

    const updated = await pool.query(
      `UPDATE misconduct_reports
       SET status = $2, review_note = $3, reviewed_by = $4, reviewed_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [id, newStatus, body.note ?? body.action, user.sub],
    );
    return mapMisconductReport(updated.rows[0]);
  });

  await listen(app, port);
}

function mapMisconductReport(row: Record<string, unknown>) {
  return {
    id: row.id,
    tripId: row.trip_id,
    reporterUserId: row.reporter_user_id,
    reporterRole: row.reporter_role,
    accusedUserId: row.accused_user_id,
    reason: row.reason,
    note: row.note,
    status: row.status,
    reviewNote: row.review_note,
    reviewedBy: row.reviewed_by,
    createdAt: row.created_at,
    reviewedAt: row.reviewed_at,
  };
}

async function withIdentityPool<T>(fn: (p: Pool) => Promise<T>): Promise<T> {
  const identityPool = createPool(databaseUrl('maekel_identity'));
  try {
    return await fn(identityPool);
  } finally {
    await identityPool.end().catch(() => undefined);
  }
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
        [input.userId, input.note ?? 'Suspended via ride report'],
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
            'Warning: a Ride safety report was filed about your account.',
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

function haversineKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const R = 6371;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function isInServiceArea(lat: number, lng: number): boolean {
  return (
    lat >= SERVICE_BBOX.minLat &&
    lat <= SERVICE_BBOX.maxLat &&
    lng >= SERVICE_BBOX.minLng &&
    lng <= SERVICE_BBOX.maxLng
  );
}

async function ensureDefaultConfig() {
  for (const [key, value] of Object.entries({
    base_etb: String(DEFAULT_CONFIG.baseEtb),
    per_km_etb: String(DEFAULT_CONFIG.perKmEtb),
    min_fare_etb: String(DEFAULT_CONFIG.minFareEtb),
    offer_radius_km: String(DEFAULT_CONFIG.offerRadiusKm),
    eta_base_min: String(DEFAULT_CONFIG.etaBaseMin),
    eta_min_per_km: String(DEFAULT_CONFIG.etaMinPerKm),
  })) {
    await pool.query(
      `INSERT INTO ride_config (key, value) VALUES ($1,$2)
       ON CONFLICT (key) DO NOTHING`,
      [key, value],
    );
  }
}

async function setConfig(key: string, value: string) {
  await pool.query(
    `INSERT INTO ride_config (key, value) VALUES ($1,$2)
     ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value`,
    [key, value],
  );
}

async function getFareConfig() {
  const res = await pool.query(`SELECT key, value FROM ride_config`);
  const map = Object.fromEntries(
    res.rows.map((r) => [r.key as string, r.value as string]),
  );
  return {
    baseEtb: Number(map.base_etb ?? DEFAULT_CONFIG.baseEtb),
    perKmEtb: Number(map.per_km_etb ?? DEFAULT_CONFIG.perKmEtb),
    minFareEtb: Number(map.min_fare_etb ?? DEFAULT_CONFIG.minFareEtb),
    offerRadiusKm: Number(map.offer_radius_km ?? DEFAULT_CONFIG.offerRadiusKm),
    etaBaseMin: Number(map.eta_base_min ?? DEFAULT_CONFIG.etaBaseMin),
    etaMinPerKm: Number(map.eta_min_per_km ?? DEFAULT_CONFIG.etaMinPerKm),
    vehicleClass: VEHICLE,
  };
}

async function ensurePinPlace(lat: number, lng: number, label: string) {
  const id = `pin-${lat.toFixed(4)}-${lng.toFixed(4)}`;
  await pool.query(
    `INSERT INTO places (id, name, subcity, lat, lng)
     VALUES ($1,$2,'Addis',$3,$4)
     ON CONFLICT (id) DO UPDATE
     SET lat = EXCLUDED.lat, lng = EXCLUDED.lng`,
    [id, `${label} (${lat.toFixed(4)}, ${lng.toFixed(4)})`, lat, lng],
  );
  return id;
}

async function getTrip(id: string) {
  const res = await pool.query(`SELECT * FROM trips WHERE id = $1`, [id]);
  if (!res.rowCount) throw new AppError('Trip not found', 404, 'not_found');
  return mapTrip(res.rows[0]);
}

async function ensureDriver(
  userId: string,
  phone: string,
  roles: string[] = [],
) {
  const existing = await pool.query(
    `SELECT * FROM drivers WHERE user_id = $1`,
    [userId],
  );
  if (existing.rowCount) return mapDriver(existing.rows[0]);
  const id = `drv-user-${userId}`;
  const autoApproved = roles.some((r) =>
    ['platform_admin', 'ride_ops'].includes(r),
  );
  await pool.query(
    `INSERT INTO drivers (id, user_id, name, rating, plate, car_model, photo_hint, phone_e164, is_online, is_approved)
     VALUES ($1,$2,'You (Driver)',5.0,'AA-DEMO-01','Economy sedan','YO',$3,FALSE,$4)
     ON CONFLICT (id) DO NOTHING`,
    [id, userId, phone, autoApproved],
  );
  const res = await pool.query(`SELECT * FROM drivers WHERE id = $1`, [id]);
  return mapDriver(res.rows[0]);
}

async function autoMatch(tripId: string) {
  await sleep(1500);
  const opened = await pool.query(
    `UPDATE trips
     SET status = 'matching',
         offer_expires_at = NOW() + make_interval(secs => $2),
         cancel_reason = NULL
     WHERE id = $1 AND status = 'requested'
     RETURNING *`,
    [tripId, OFFER_TTL_SEC],
  );
  if (!opened.rowCount) return;

  const trip = mapTrip(opened.rows[0]);
  const cfg = await getFareConfig();
  await sleep(2000);

  const online = await pool.query(
    `SELECT id, last_lat, last_lng FROM drivers
     WHERE is_online = TRUE AND is_approved = TRUE
       AND last_lat IS NOT NULL AND last_lng IS NOT NULL`,
  );
  const nearby = online.rows.filter((d) => {
    if (trip.pickupLat == null || trip.pickupLng == null) return true;
    return (
      haversineKm(
        Number(d.last_lat),
        Number(d.last_lng),
        trip.pickupLat as number,
        trip.pickupLng as number,
      ) <= cfg.offerRadiusKm
    );
  });

  if (!nearby.length) {
    await pool.query(
      `UPDATE trips
       SET status = 'cancelled',
           cancel_reason = 'no_driver',
           offer_expires_at = NULL
       WHERE id = $1 AND status = 'matching'`,
      [tripId],
    );
    return;
  }

  await sleep(OFFER_TTL_SEC * 1000);
  await expireStaleOffers();
}

async function expireStaleOffers() {
  await pool.query(
    `UPDATE trips
     SET status = 'cancelled',
         cancel_reason = COALESCE(cancel_reason, 'no_driver'),
         offer_expires_at = NULL
     WHERE status = 'matching'
       AND offer_expires_at IS NOT NULL
       AND offer_expires_at < NOW()`,
  );
}

function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

function mapPlace(row: Record<string, unknown>) {
  return {
    id: row.id,
    name: row.name,
    subcity: row.subcity,
    lat: row.lat == null ? null : Number(row.lat),
    lng: row.lng == null ? null : Number(row.lng),
  };
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
    etaMinutes: row.eta_minutes == null ? null : Number(row.eta_minutes),
    offerExpiresAt: row.offer_expires_at ?? null,
    cancelReason: row.cancel_reason ?? null,
    pickupLat: row.pickup_lat == null ? null : Number(row.pickup_lat),
    pickupLng: row.pickup_lng == null ? null : Number(row.pickup_lng),
    dropoffLat: row.dropoff_lat == null ? null : Number(row.dropoff_lat),
    dropoffLng: row.dropoff_lng == null ? null : Number(row.dropoff_lng),
    distanceKm: row.distance_km == null ? null : Number(row.distance_km),
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
