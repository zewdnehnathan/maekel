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

const port = envInt('CHAT_PORT', 3005);
const pool = createPool(databaseUrl('maekel_chat'));

async function boot() {
  await migrate(pool, [
    `CREATE TABLE IF NOT EXISTS threads (
      id UUID PRIMARY KEY,
      ad_id UUID NOT NULL,
      buyer_id UUID NOT NULL,
      seller_id UUID NOT NULL,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      UNIQUE (ad_id, buyer_id)
    )`,
    `CREATE TABLE IF NOT EXISTS messages (
      id UUID PRIMARY KEY,
      thread_id UUID NOT NULL REFERENCES threads(id) ON DELETE CASCADE,
      sender_id TEXT NOT NULL,
      body TEXT NOT NULL,
      sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
  ]);

  const app = await createService({ name: 'chat-service', port });

  app.post('/v1/chat/threads', async (req) => {
    requireAuth(req);
    const body = z
      .object({
        adId: z.string().uuid(),
        buyerId: z.string().uuid(),
        sellerId: z.string().uuid(),
      })
      .parse(req.body ?? {});

    const existing = await pool.query(
      `SELECT * FROM threads WHERE ad_id = $1 AND buyer_id = $2`,
      [body.adId, body.buyerId],
    );
    if (existing.rowCount) return mapThread(existing.rows[0]);

    const id = crypto.randomUUID();
    await pool.query(
      `INSERT INTO threads (id, ad_id, buyer_id, seller_id) VALUES ($1,$2,$3,$4)`,
      [id, body.adId, body.buyerId, body.sellerId],
    );
    await pool.query(
      `INSERT INTO messages (id, thread_id, sender_id, body)
       VALUES ($1,$2,'system',$3)`,
      [
        crypto.randomUUID(),
        id,
        'Safety tip: Meet in a public place. Inspect before you pay. Maekel never asks for fees via chat.',
      ],
    );
    const res = await pool.query(`SELECT * FROM threads WHERE id = $1`, [id]);
    return mapThread(res.rows[0]);
  });

  app.get('/v1/chat/threads', async (req) => {
    const user = requireAuth(req);
    const res = await pool.query(
      `SELECT * FROM threads
       WHERE buyer_id = $1 OR seller_id = $1
       ORDER BY updated_at DESC`,
      [user.sub],
    );
    return { items: res.rows.map(mapThread) };
  });

  app.get('/v1/chat/threads/:id/messages', async (req) => {
    requireAuth(req);
    const { id } = req.params as { id: string };
    const res = await pool.query(
      `SELECT * FROM messages WHERE thread_id = $1 ORDER BY sent_at ASC`,
      [id],
    );
    return {
      items: res.rows.map((m) => ({
        id: m.id,
        threadId: m.thread_id,
        senderId: m.sender_id,
        body: m.body,
        sentAt: m.sent_at,
      })),
    };
  });

  app.post('/v1/chat/threads/:id/messages', async (req) => {
    const user = requireAuth(req);
    const { id } = req.params as { id: string };
    const body = z.object({ body: z.string().min(1) }).parse(req.body ?? {});
    const thread = await pool.query(`SELECT * FROM threads WHERE id = $1`, [id]);
    if (!thread.rowCount) throw new AppError('Thread not found', 404, 'not_found');

    const msgId = crypto.randomUUID();
    await pool.query(
      `INSERT INTO messages (id, thread_id, sender_id, body) VALUES ($1,$2,$3,$4)`,
      [msgId, id, user.sub, body.body.trim()],
    );
    await pool.query(`UPDATE threads SET updated_at = NOW() WHERE id = $1`, [id]);

    return {
      id: msgId,
      threadId: id,
      senderId: user.sub,
      body: body.body.trim(),
      sentAt: new Date().toISOString(),
    };
  });

  await listen(app, port);
}

function mapThread(row: Record<string, unknown>) {
  return {
    id: row.id,
    adId: row.ad_id,
    buyerId: row.buyer_id,
    sellerId: row.seller_id,
    updatedAt: row.updated_at,
  };
}

boot().catch((err) => {
  console.error(err);
  process.exit(1);
});
