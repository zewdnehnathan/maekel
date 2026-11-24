import multipart from '@fastify/multipart';
import crypto from 'node:crypto';
import {
  AppError,
  createPool,
  createService,
  databaseUrl,
  ensureDatabase,
  env,
  envInt,
  listen,
  migrate,
  requireAuth,
  requireRole,
} from '@maekel/shared';
import { z } from 'zod';

const port = envInt('EVENTS_PORT', 3007);
const publicApiBase = env(
  'PUBLIC_API_BASE',
  `http://127.0.0.1:${envInt('GATEWAY_PORT', 8080)}`,
);
let pool: ReturnType<typeof createPool>;

const opsStaff = ['events_ops', 'platform_admin'] as const;

const ADDIS_SUBCITIES = [
  'Bole',
  'Kirkos',
  'Yeka',
  'Lideta',
  'Nifas Silk',
  'Addis Ketema',
  'Arada',
  'Gulele',
] as const;

const eventStatusSchema = z.enum([
  'draft',
  'pending',
  'approved',
  'rejected',
  'cancelled',
  'ended',
]);

async function boot() {
  await ensureDatabase('maekel_events');
  pool = createPool(databaseUrl('maekel_events'));
  await migrate(pool, [
    `CREATE TABLE IF NOT EXISTS categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      icon_name TEXT NOT NULL DEFAULT 'event'
    )`,
    `CREATE TABLE IF NOT EXISTS organizers (
      id UUID PRIMARY KEY,
      phone_e164 TEXT NOT NULL,
      display_name TEXT NOT NULL DEFAULT '',
      suspended_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
    `CREATE TABLE IF NOT EXISTS events (
      id UUID PRIMARY KEY,
      organizer_id UUID NOT NULL REFERENCES organizers(id),
      category_id TEXT NOT NULL REFERENCES categories(id),
      title TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      venue_name TEXT NOT NULL,
      venue_address TEXT NOT NULL DEFAULT '',
      subcity TEXT NOT NULL,
      starts_at TIMESTAMPTZ NOT NULL,
      ends_at TIMESTAMPTZ,
      capacity INT NOT NULL CHECK (capacity > 0),
      price_etb INT NOT NULL DEFAULT 0 CHECK (price_etb >= 0),
      payment_mode TEXT NOT NULL DEFAULT 'free'
        CHECK (payment_mode IN ('free', 'pay_at_door')),
      status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('draft','pending','approved','rejected','cancelled','ended')),
      cover_url TEXT,
      check_in_code TEXT NOT NULL,
      rejection_reason TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
    `CREATE INDEX IF NOT EXISTS events_status_starts_idx
      ON events (status, starts_at)`,
    `CREATE INDEX IF NOT EXISTS events_organizer_idx ON events (organizer_id)`,
    `CREATE TABLE IF NOT EXISTS tickets (
      id UUID PRIMARY KEY,
      event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
      user_id UUID NOT NULL,
      qty INT NOT NULL DEFAULT 1 CHECK (qty > 0),
      status TEXT NOT NULL DEFAULT 'reserved'
        CHECK (status IN ('reserved', 'checked_in', 'cancelled')),
      ticket_code TEXT NOT NULL UNIQUE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      UNIQUE (event_id, user_id)
    )`,
    `CREATE INDEX IF NOT EXISTS tickets_user_idx ON tickets (user_id)`,
    `CREATE INDEX IF NOT EXISTS tickets_event_idx ON tickets (event_id)`,
    `ALTER TABLE events ADD COLUMN IF NOT EXISTS image_urls TEXT[] NOT NULL DEFAULT '{}'`,
    // Survive Render ephemeral disk: store event photos in Postgres BYTEA.
    `CREATE TABLE IF NOT EXISTS media_objects (
      id TEXT PRIMARY KEY,
      content_type TEXT NOT NULL,
      bytes BYTEA NOT NULL,
      byte_len INT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
  ]);
  await seed();

  const app = await createService({
    name: 'events-service',
    port,
    bodyLimit: 12 * 1024 * 1024,
  });

  await app.register(multipart, {
    limits: {
      fileSize: 8 * 1024 * 1024,
      files: 1,
    },
  });

  app.post('/v1/events/media', async (req) => {
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
      url: `${publicApiBase}/v1/events/media/files/${filename}`,
      contentType: mime,
    };
  });

  app.get('/v1/events/media/files/:filename', async (req, reply) => {
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

  app.get('/v1/events/categories', async () => {
    const res = await pool.query(
      `SELECT id, name, icon_name FROM categories ORDER BY name`,
    );
    return {
      items: res.rows.map((r) => ({
        id: r.id,
        name: r.name,
        iconName: r.icon_name,
      })),
    };
  });

  app.get('/v1/events/subcities', async () => ({
    items: [...ADDIS_SUBCITIES],
  }));

  app.get('/v1/events/events', async (req) => {
    const q = z
      .object({
        query: z.string().optional(),
        categoryId: z.string().optional(),
        subcity: z.string().optional(),
        from: z.string().optional(),
        to: z.string().optional(),
      })
      .parse(req.query ?? {});

    const clauses = [`e.status = 'approved'`, `e.starts_at >= NOW() - INTERVAL '1 day'`];
    const params: unknown[] = [];
    if (q.categoryId) {
      params.push(q.categoryId);
      clauses.push(`e.category_id = $${params.length}`);
    }
    if (q.subcity) {
      params.push(q.subcity);
      clauses.push(`e.subcity = $${params.length}`);
    }
    if (q.query?.trim()) {
      params.push(`%${q.query.trim()}%`);
      clauses.push(
        `(e.title ILIKE $${params.length} OR e.venue_name ILIKE $${params.length} OR e.description ILIKE $${params.length})`,
      );
    }
    if (q.from) {
      params.push(q.from);
      clauses.push(`e.starts_at >= $${params.length}::timestamptz`);
    }
    if (q.to) {
      params.push(q.to);
      clauses.push(`e.starts_at <= $${params.length}::timestamptz`);
    }

    const res = await pool.query(
      `SELECT e.*, o.display_name AS organizer_name, o.phone_e164 AS organizer_phone,
              c.name AS category_name,
              COALESCE((
                SELECT SUM(t.qty) FROM tickets t
                WHERE t.event_id = e.id AND t.status <> 'cancelled'
              ), 0)::int AS tickets_sold
       FROM events e
       JOIN organizers o ON o.id = e.organizer_id
       JOIN categories c ON c.id = e.category_id
       WHERE ${clauses.join(' AND ')}
         AND o.suspended_at IS NULL
       ORDER BY e.starts_at ASC
       LIMIT 200`,
      params,
    );
    return { items: res.rows.map((r) => mapEvent(r)) };
  });

  app.get('/v1/events/events/:id', async (req) => {
    const { id } = z.object({ id: z.string().uuid() }).parse(req.params);
    const event = await getEventRow(id);
    if (!event) throw new AppError('Event not found', 404, 'not_found');
    if (
      event.status !== 'approved' &&
      event.status !== 'cancelled' &&
      event.status !== 'ended'
    ) {
      // Non-public statuses only for organizer / ops (optional auth).
      try {
        const user = requireAuth(req);
        const isOps = opsStaff.some((r) => user.roles.includes(r));
        if (event.organizer_id !== user.sub && !isOps) {
          throw new AppError('Event not found', 404, 'not_found');
        }
      } catch (e) {
        if (e instanceof AppError && e.code === 'not_found') throw e;
        throw new AppError('Event not found', 404, 'not_found');
      }
    }
    return mapEvent(event);
  });

  app.post('/v1/events/events', async (req) => {
    const user = requireAuth(req);
    const body = z
      .object({
        categoryId: z.string().min(1),
        title: z.string().min(3).max(120),
        description: z.string().max(4000).default(''),
        venueName: z.string().min(2).max(160),
        venueAddress: z.string().max(300).default(''),
        subcity: z.string().min(2),
        startsAt: z.string().min(4),
        endsAt: z.string().optional().nullable(),
        capacity: z.number().int().min(1).max(50000),
        priceEtb: z.number().int().min(0).max(1_000_000).default(0),
        paymentMode: z.enum(['free', 'pay_at_door']).default('free'),
        coverUrl: z.string().url().optional().nullable(),
        imageUrls: z.array(z.string().url()).max(8).optional(),
      })
      .parse(req.body ?? {});

    const organizer = await ensureOrganizer(user.sub, user.phone);
    if (organizer.suspended_at) {
      throw new AppError('Organizer suspended', 403, 'suspended');
    }
    await assertCategory(body.categoryId);
    if (body.priceEtb > 0 && body.paymentMode === 'free') {
      throw new AppError(
        'Paid events must use pay_at_door',
        400,
        'invalid_payment',
      );
    }

    const imageUrls = normalizeImageUrls(body.imageUrls, body.coverUrl);
    const id = crypto.randomUUID();
    const checkInCode = randomCode(6);
    const res = await pool.query(
      `INSERT INTO events (
         id, organizer_id, category_id, title, description,
         venue_name, venue_address, subcity, starts_at, ends_at,
         capacity, price_etb, payment_mode, status, cover_url, image_urls, check_in_code
       ) VALUES (
         $1,$2,$3,$4,$5,$6,$7,$8,$9::timestamptz,$10::timestamptz,
         $11,$12,$13,'pending',$14,$15,$16
       )
       RETURNING *`,
      [
        id,
        organizer.id,
        body.categoryId,
        body.title.trim(),
        body.description.trim(),
        body.venueName.trim(),
        body.venueAddress.trim(),
        body.subcity,
        body.startsAt,
        body.endsAt ?? null,
        body.capacity,
        body.priceEtb,
        body.paymentMode,
        imageUrls[0] ?? null,
        imageUrls,
        checkInCode,
      ],
    );
    return mapEvent(await enrichEvent(res.rows[0]), {
      includeCheckInCode: true,
    });
  });

  app.patch('/v1/events/events/:id', async (req) => {
    const user = requireAuth(req);
    const { id } = z.object({ id: z.string().uuid() }).parse(req.params);
    const body = z
      .object({
        categoryId: z.string().min(1).optional(),
        title: z.string().min(3).max(120).optional(),
        description: z.string().max(4000).optional(),
        venueName: z.string().min(2).max(160).optional(),
        venueAddress: z.string().max(300).optional(),
        subcity: z.string().min(2).optional(),
        startsAt: z.string().min(4).optional(),
        endsAt: z.string().optional().nullable(),
        capacity: z.number().int().min(1).max(50000).optional(),
        priceEtb: z.number().int().min(0).max(1_000_000).optional(),
        paymentMode: z.enum(['free', 'pay_at_door']).optional(),
        coverUrl: z.string().url().optional().nullable(),
        imageUrls: z.array(z.string().url()).max(8).optional(),
      })
      .parse(req.body ?? {});

    const existing = await getEventRow(id);
    if (!existing) throw new AppError('Event not found', 404, 'not_found');
    const isOps = opsStaff.some((r) => user.roles.includes(r));
    if (existing.organizer_id !== user.sub && !isOps) {
      throw new AppError('Forbidden', 403, 'forbidden');
    }
    const existingStatus = String(existing.status);
    if (
      ['cancelled', 'ended'].includes(existingStatus) ||
      (existingStatus === 'approved' && !isOps && body.capacity == null)
    ) {
      // Organizer may bump capacity on live events; other edits re-pending.
    }
    if (body.categoryId) await assertCategory(body.categoryId);

    const nextPrice = Number(body.priceEtb ?? existing.price_etb);
    const nextPay = String(body.paymentMode ?? existing.payment_mode);
    if (nextPrice > 0 && nextPay === 'free') {
      throw new AppError(
        'Paid events must use pay_at_door',
        400,
        'invalid_payment',
      );
    }

    const sold = await ticketsSold(id);
    const nextCapacity = Number(body.capacity ?? existing.capacity);
    if (nextCapacity < sold) {
      throw new AppError(
        `Capacity cannot be below tickets sold (${sold})`,
        400,
        'capacity',
      );
    }

    const imagesProvided =
      body.imageUrls !== undefined || body.coverUrl !== undefined;
    const nextImages = imagesProvided
      ? normalizeImageUrls(
          body.imageUrls ??
            ((existing.image_urls as string[] | null) ?? undefined),
          body.coverUrl,
        )
      : null;

    let nextStatus = existing.status as string;
    const materialEdit =
      body.title != null ||
      body.description != null ||
      body.venueName != null ||
      body.venueAddress != null ||
      body.subcity != null ||
      body.startsAt != null ||
      body.endsAt !== undefined ||
      body.categoryId != null ||
      body.priceEtb != null ||
      body.paymentMode != null ||
      imagesProvided;
    if (materialEdit && existing.organizer_id === user.sub && !isOps) {
      if (existing.status === 'approved' || existing.status === 'rejected') {
        nextStatus = 'pending';
      }
    }

    const res = await pool.query(
      `UPDATE events SET
         category_id = COALESCE($2, category_id),
         title = COALESCE($3, title),
         description = COALESCE($4, description),
         venue_name = COALESCE($5, venue_name),
         venue_address = COALESCE($6, venue_address),
         subcity = COALESCE($7, subcity),
         starts_at = COALESCE($8::timestamptz, starts_at),
         ends_at = CASE WHEN $9::boolean THEN $10::timestamptz ELSE ends_at END,
         capacity = COALESCE($11, capacity),
         price_etb = COALESCE($12, price_etb),
         payment_mode = COALESCE($13, payment_mode),
         cover_url = CASE WHEN $14::boolean THEN $15 ELSE cover_url END,
         image_urls = CASE WHEN $14::boolean THEN $16 ELSE image_urls END,
         status = $17,
         updated_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [
        id,
        body.categoryId ?? null,
        body.title?.trim() ?? null,
        body.description?.trim() ?? null,
        body.venueName?.trim() ?? null,
        body.venueAddress?.trim() ?? null,
        body.subcity ?? null,
        body.startsAt ?? null,
        body.endsAt !== undefined,
        body.endsAt ?? null,
        body.capacity ?? null,
        body.priceEtb ?? null,
        body.paymentMode ?? null,
        imagesProvided,
        nextImages?.[0] ?? null,
        nextImages ?? [],
        nextStatus,
      ],
    );
    return mapEvent(await enrichEvent(res.rows[0]));
  });

  app.patch('/v1/events/events/:id/status', async (req) => {
    const user = requireAuth(req);
    const { id } = z.object({ id: z.string().uuid() }).parse(req.params);
    const body = z
      .object({
        status: eventStatusSchema,
        reason: z.string().max(500).optional(),
      })
      .parse(req.body ?? {});

    const existing = await getEventRow(id);
    if (!existing) throw new AppError('Event not found', 404, 'not_found');
    const isOps = opsStaff.some((r) => user.roles.includes(r));
    const isOwner = existing.organizer_id === user.sub;

    if (body.status === 'approved' || body.status === 'rejected') {
      requireRole(user, [...opsStaff]);
    } else if (body.status === 'cancelled') {
      if (!isOwner && !isOps) {
        throw new AppError('Forbidden', 403, 'forbidden');
      }
    } else if (body.status === 'pending') {
      if (!isOwner && !isOps) {
        throw new AppError('Forbidden', 403, 'forbidden');
      }
    } else if (body.status === 'ended') {
      if (!isOwner && !isOps) {
        throw new AppError('Forbidden', 403, 'forbidden');
      }
    } else {
      throw new AppError('Invalid status transition', 400, 'invalid_status');
    }

    const res = await pool.query(
      `UPDATE events SET
         status = $2,
         rejection_reason = CASE WHEN $2 = 'rejected' THEN $3 ELSE rejection_reason END,
         updated_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [id, body.status, body.reason ?? null],
    );
    return mapEvent(await enrichEvent(res.rows[0]));
  });

  app.get('/v1/events/my-events', async (req) => {
    const user = requireAuth(req);
    await ensureOrganizer(user.sub, user.phone);
    const res = await pool.query(
      `SELECT e.*, o.display_name AS organizer_name, o.phone_e164 AS organizer_phone,
              c.name AS category_name,
              COALESCE((
                SELECT SUM(t.qty) FROM tickets t
                WHERE t.event_id = e.id AND t.status <> 'cancelled'
              ), 0)::int AS tickets_sold
       FROM events e
       JOIN organizers o ON o.id = e.organizer_id
       JOIN categories c ON c.id = e.category_id
       WHERE e.organizer_id = $1
       ORDER BY e.starts_at DESC`,
      [user.sub],
    );
    return {
      items: res.rows.map((r) => mapEvent(r, { includeCheckInCode: true })),
    };
  });

  app.get('/v1/events/my-tickets', async (req) => {
    const user = requireAuth(req);
    const res = await pool.query(
      `SELECT t.*, e.title, e.venue_name, e.subcity, e.starts_at, e.status AS event_status,
              e.price_etb, e.payment_mode, e.check_in_code AS event_check_in_code
       FROM tickets t
       JOIN events e ON e.id = t.event_id
       WHERE t.user_id = $1 AND t.status <> 'cancelled'
       ORDER BY e.starts_at ASC`,
      [user.sub],
    );
    return {
      items: res.rows.map((r) => ({
        id: r.id,
        eventId: r.event_id,
        userId: r.user_id,
        qty: r.qty,
        status: r.status,
        ticketCode: r.ticket_code,
        createdAt: r.created_at,
        eventTitle: r.title,
        venueName: r.venue_name,
        subcity: r.subcity,
        startsAt: r.starts_at,
        eventStatus: r.event_status,
        priceEtb: r.price_etb,
        paymentMode: r.payment_mode,
      })),
    };
  });

  app.post('/v1/events/events/:id/rsvp', async (req) => {
    const user = requireAuth(req);
    const { id } = z.object({ id: z.string().uuid() }).parse(req.params);
    const body = z
      .object({ qty: z.number().int().min(1).max(20).default(1) })
      .parse(req.body ?? {});

    const event = await getEventRow(id);
    if (!event) throw new AppError('Event not found', 404, 'not_found');
    if (event.status !== 'approved') {
      throw new AppError('Event is not open for RSVP', 400, 'not_open');
    }
    if (event.organizer_id === user.sub) {
      throw new AppError('Organizers cannot RSVP to their own event', 400, 'own_event');
    }

    const existing = await pool.query(
      `SELECT * FROM tickets WHERE event_id = $1 AND user_id = $2`,
      [id, user.sub],
    );
    if (existing.rowCount && existing.rows[0].status !== 'cancelled') {
      throw new AppError('Already RSVPed', 409, 'already_rsvped');
    }

    const sold = await ticketsSold(id);
    if (sold + body.qty > Number(event.capacity)) {
      throw new AppError('Sold out', 409, 'sold_out');
    }

    const ticketId = crypto.randomUUID();
    const ticketCode = `MK-${randomCode(8)}`;
    let row;
    if (existing.rowCount) {
      const updated = await pool.query(
        `UPDATE tickets SET qty = $2, status = 'reserved', ticket_code = $3
         WHERE id = $1
         RETURNING *`,
        [existing.rows[0].id, body.qty, ticketCode],
      );
      row = updated.rows[0];
    } else {
      const inserted = await pool.query(
        `INSERT INTO tickets (id, event_id, user_id, qty, status, ticket_code)
         VALUES ($1,$2,$3,$4,'reserved',$5)
         RETURNING *`,
        [ticketId, id, user.sub, body.qty, ticketCode],
      );
      row = inserted.rows[0];
    }
    return {
      id: row.id,
      eventId: row.event_id,
      userId: row.user_id,
      qty: row.qty,
      status: row.status,
      ticketCode: row.ticket_code,
      createdAt: row.created_at,
    };
  });

  app.post('/v1/events/events/:id/cancel-rsvp', async (req) => {
    const user = requireAuth(req);
    const { id } = z.object({ id: z.string().uuid() }).parse(req.params);
    const res = await pool.query(
      `UPDATE tickets SET status = 'cancelled'
       WHERE event_id = $1 AND user_id = $2 AND status = 'reserved'
       RETURNING *`,
      [id, user.sub],
    );
    if (!res.rowCount) {
      throw new AppError('No active RSVP', 404, 'not_found');
    }
    return { ok: true };
  });

  app.get('/v1/events/events/:id/attendees', async (req) => {
    const user = requireAuth(req);
    const { id } = z.object({ id: z.string().uuid() }).parse(req.params);
    const event = await getEventRow(id);
    if (!event) throw new AppError('Event not found', 404, 'not_found');
    const isOps = opsStaff.some((r) => user.roles.includes(r));
    if (event.organizer_id !== user.sub && !isOps) {
      throw new AppError('Forbidden', 403, 'forbidden');
    }
    const res = await pool.query(
      `SELECT * FROM tickets
       WHERE event_id = $1 AND status <> 'cancelled'
       ORDER BY created_at ASC`,
      [id],
    );
    return {
      items: res.rows.map((r) => ({
        id: r.id,
        eventId: r.event_id,
        userId: r.user_id,
        qty: r.qty,
        status: r.status,
        ticketCode: r.ticket_code,
        createdAt: r.created_at,
      })),
      checkInCode: event.check_in_code,
      ticketsSold: await ticketsSold(id),
      capacity: event.capacity,
    };
  });

  app.post('/v1/events/events/:id/check-in', async (req) => {
    const user = requireAuth(req);
    const { id } = z.object({ id: z.string().uuid() }).parse(req.params);
    const body = z
      .object({
        ticketCode: z.string().min(4).optional(),
        ticketId: z.string().uuid().optional(),
      })
      .parse(req.body ?? {});

    const event = await getEventRow(id);
    if (!event) throw new AppError('Event not found', 404, 'not_found');
    const isOps = opsStaff.some((r) => user.roles.includes(r));
    if (event.organizer_id !== user.sub && !isOps) {
      throw new AppError('Forbidden', 403, 'forbidden');
    }
    if (!['approved', 'ended'].includes(String(event.status))) {
      throw new AppError('Event not check-in ready', 400, 'not_ready');
    }

    let ticket;
    if (body.ticketId) {
      const res = await pool.query(
        `SELECT * FROM tickets WHERE id = $1 AND event_id = $2`,
        [body.ticketId, id],
      );
      ticket = res.rows[0];
    } else if (body.ticketCode) {
      const res = await pool.query(
        `SELECT * FROM tickets WHERE ticket_code = $1 AND event_id = $2`,
        [body.ticketCode.trim().toUpperCase(), id],
      );
      ticket = res.rows[0];
    } else {
      throw new AppError('ticketCode or ticketId required', 400, 'validation');
    }
    if (!ticket) throw new AppError('Ticket not found', 404, 'not_found');
    if (ticket.status === 'cancelled') {
      throw new AppError('Ticket cancelled', 400, 'cancelled');
    }
    if (ticket.status === 'checked_in') {
      return {
        id: ticket.id,
        status: ticket.status,
        alreadyCheckedIn: true,
      };
    }
    const updated = await pool.query(
      `UPDATE tickets SET status = 'checked_in' WHERE id = $1 RETURNING *`,
      [ticket.id],
    );
    return {
      id: updated.rows[0].id,
      status: updated.rows[0].status,
      alreadyCheckedIn: false,
    };
  });

  app.get('/v1/events/ops/queue', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const pending = await pool.query(
      `SELECT e.*, o.display_name AS organizer_name, o.phone_e164 AS organizer_phone,
              c.name AS category_name,
              COALESCE((
                SELECT SUM(t.qty) FROM tickets t
                WHERE t.event_id = e.id AND t.status <> 'cancelled'
              ), 0)::int AS tickets_sold
       FROM events e
       JOIN organizers o ON o.id = e.organizer_id
       JOIN categories c ON c.id = e.category_id
       WHERE e.status = 'pending'
       ORDER BY e.created_at ASC`,
    );
    const live = await pool.query(
      `SELECT e.*, o.display_name AS organizer_name, o.phone_e164 AS organizer_phone,
              c.name AS category_name,
              COALESCE((
                SELECT SUM(t.qty) FROM tickets t
                WHERE t.event_id = e.id AND t.status <> 'cancelled'
              ), 0)::int AS tickets_sold
       FROM events e
       JOIN organizers o ON o.id = e.organizer_id
       JOIN categories c ON c.id = e.category_id
       WHERE e.status = 'approved'
       ORDER BY e.starts_at ASC
       LIMIT 100`,
    );
    return {
      pending: pending.rows.map((r) => mapEvent(r)),
      live: live.rows.map((r) => mapEvent(r)),
    };
  });

  app.post('/v1/events/ops/organizers/:id/suspend', async (req) => {
    const user = requireAuth(req);
    requireRole(user, [...opsStaff]);
    const { id } = z.object({ id: z.string().uuid() }).parse(req.params);
    const body = z
      .object({ suspended: z.boolean().default(true) })
      .parse(req.body ?? {});
    const res = await pool.query(
      `UPDATE organizers SET
         suspended_at = CASE WHEN $2 THEN NOW() ELSE NULL END
       WHERE id = $1
       RETURNING *`,
      [id, body.suspended],
    );
    if (!res.rowCount) throw new AppError('Organizer not found', 404, 'not_found');
    if (body.suspended) {
      await pool.query(
        `UPDATE events SET status = 'cancelled', updated_at = NOW()
         WHERE organizer_id = $1 AND status IN ('pending','approved')`,
        [id],
      );
    }
    return {
      id: res.rows[0].id,
      suspended: !!res.rows[0].suspended_at,
    };
  });

  app.get('/v1/events/me/organizer', async (req) => {
    const user = requireAuth(req);
    const org = await ensureOrganizer(user.sub, user.phone);
    return {
      id: org.id,
      phone: org.phone_e164,
      displayName: org.display_name,
      suspended: !!org.suspended_at,
    };
  });

  app.patch('/v1/events/me/organizer', async (req) => {
    const user = requireAuth(req);
    const body = z
      .object({ displayName: z.string().min(1).max(80) })
      .parse(req.body ?? {});
    await ensureOrganizer(user.sub, user.phone);
    const res = await pool.query(
      `UPDATE organizers SET display_name = $2 WHERE id = $1 RETURNING *`,
      [user.sub, body.displayName.trim()],
    );
    return {
      id: res.rows[0].id,
      phone: res.rows[0].phone_e164,
      displayName: res.rows[0].display_name,
      suspended: !!res.rows[0].suspended_at,
    };
  });

  await listen(app, port);
}

function normalizeImageUrls(
  imageUrls: string[] | undefined,
  coverUrl: string | null | undefined,
): string[] {
  const fromList = (imageUrls ?? []).map((u) => u.trim()).filter(Boolean);
  if (fromList.length > 0) return [...new Set(fromList)].slice(0, 8);
  if (coverUrl?.trim()) return [coverUrl.trim()];
  return [];
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

function mapEvent(
  r: Record<string, unknown>,
  opts: { includeCheckInCode?: boolean } = {},
) {
  const imageUrls = normalizeImageUrls(
    (r.image_urls as string[] | null | undefined) ?? undefined,
    (r.cover_url as string | null | undefined) ?? null,
  );
  return {
    id: r.id,
    organizerId: r.organizer_id,
    organizerName: r.organizer_name ?? '',
    organizerPhone: r.organizer_phone ?? '',
    categoryId: r.category_id,
    categoryName: r.category_name ?? '',
    title: r.title,
    description: r.description,
    venueName: r.venue_name,
    venueAddress: r.venue_address,
    subcity: r.subcity,
    startsAt: r.starts_at,
    endsAt: r.ends_at,
    capacity: r.capacity,
    ticketsSold: r.tickets_sold ?? 0,
    priceEtb: r.price_etb,
    paymentMode: r.payment_mode,
    status: r.status,
    coverUrl: imageUrls[0] ?? r.cover_url ?? null,
    imageUrls,
    checkInCode: opts.includeCheckInCode ? r.check_in_code : undefined,
    rejectionReason: r.rejection_reason,
    createdAt: r.created_at,
    updatedAt: r.updated_at,
  };
}

async function enrichEvent(row: Record<string, unknown>) {
  const sold = await ticketsSold(row.id as string);
  const cat = await pool.query(`SELECT name FROM categories WHERE id = $1`, [
    row.category_id,
  ]);
  const org = await pool.query(
    `SELECT display_name, phone_e164 FROM organizers WHERE id = $1`,
    [row.organizer_id],
  );
  return {
    ...row,
    tickets_sold: sold,
    category_name: cat.rows[0]?.name ?? '',
    organizer_name: org.rows[0]?.display_name ?? '',
    organizer_phone: org.rows[0]?.phone_e164 ?? '',
  };
}

async function getEventRow(id: string) {
  const res = await pool.query(
    `SELECT e.*, o.display_name AS organizer_name, o.phone_e164 AS organizer_phone,
            c.name AS category_name,
            COALESCE((
              SELECT SUM(t.qty) FROM tickets t
              WHERE t.event_id = e.id AND t.status <> 'cancelled'
            ), 0)::int AS tickets_sold
     FROM events e
     JOIN organizers o ON o.id = e.organizer_id
     JOIN categories c ON c.id = e.category_id
     WHERE e.id = $1`,
    [id],
  );
  return res.rows[0] as Record<string, unknown> | undefined;
}

async function ticketsSold(eventId: string): Promise<number> {
  const res = await pool.query(
    `SELECT COALESCE(SUM(qty), 0)::int AS sold
     FROM tickets WHERE event_id = $1 AND status <> 'cancelled'`,
    [eventId],
  );
  return res.rows[0].sold as number;
}

async function ensureOrganizer(userId: string, phone: string) {
  const existing = await pool.query(`SELECT * FROM organizers WHERE id = $1`, [
    userId,
  ]);
  if (existing.rowCount) return existing.rows[0];
  const inserted = await pool.query(
    `INSERT INTO organizers (id, phone_e164, display_name)
     VALUES ($1, $2, $3)
     RETURNING *`,
    [userId, phone, phone],
  );
  return inserted.rows[0];
}

async function assertCategory(id: string) {
  const res = await pool.query(`SELECT id FROM categories WHERE id = $1`, [id]);
  if (!res.rowCount) {
    throw new AppError('Unknown category', 400, 'invalid_category');
  }
}

function randomCode(len: number): string {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let out = '';
  const bytes = crypto.getRandomValues(new Uint8Array(len));
  for (let i = 0; i < len; i++) {
    out += alphabet[bytes[i]! % alphabet.length]!;
  }
  return out;
}

async function seed() {
  const cats: Array<[string, string, string]> = [
    ['music', 'Music', 'music'],
    ['sports', 'Sports', 'sports'],
    ['culture', 'Culture', 'museum'],
    ['business', 'Business', 'work'],
    ['food', 'Food & Drink', 'restaurant'],
    ['community', 'Community', 'groups'],
    ['nightlife', 'Nightlife', 'nightlife'],
    ['family', 'Family', 'family'],
  ];
  for (const [id, name, icon] of cats) {
    await pool.query(
      `INSERT INTO categories (id, name, icon_name) VALUES ($1,$2,$3)
       ON CONFLICT (id) DO NOTHING`,
      [id, name, icon],
    );
  }
}

boot().catch((err) => {
  console.error(err);
  process.exit(1);
});
