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

const port = envInt('GAMES_PORT', 3006);
const pool = createPool(databaseUrl('maekel_games'));
const DEFAULT_CITY = 'Addis Ababa';

const gameSchema = z.enum(['tetris', 'brickBreaker', 'candyCrush']);

async function boot() {
  await migrate(pool, [
    `CREATE TABLE IF NOT EXISTS player_profiles (
      user_id UUID PRIMARY KEY,
      display_name TEXT NOT NULL,
      city TEXT NOT NULL DEFAULT 'Addis Ababa',
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
    `CREATE TABLE IF NOT EXISTS high_scores (
      user_id UUID NOT NULL REFERENCES player_profiles(user_id) ON DELETE CASCADE,
      game TEXT NOT NULL,
      score INT NOT NULL CHECK (score >= 0),
      city TEXT NOT NULL DEFAULT 'Addis Ababa',
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      PRIMARY KEY (user_id, game)
    )`,
    `CREATE INDEX IF NOT EXISTS high_scores_leaderboard_idx
      ON high_scores (game, city, score DESC, updated_at ASC)`,
  ]);
  await seed();

  const app = await createService({ name: 'games-service', port });

  app.get('/v1/games/leaderboard', async (req) => {
    const q = z
      .object({
        game: gameSchema.optional(),
        city: z.string().default(DEFAULT_CITY),
        limit: z.coerce.number().int().min(1).max(20).default(3),
      })
      .parse(req.query ?? {});

    if (q.game) {
      return {
        city: q.city,
        game: q.game,
        items: await topScores(q.game, q.city, q.limit),
      };
    }

    const [tetris, brickBreaker, candyCrush] = await Promise.all([
      topScores('tetris', q.city, q.limit),
      topScores('brickBreaker', q.city, q.limit),
      topScores('candyCrush', q.city, q.limit),
    ]);
    return {
      city: q.city,
      tetris,
      brickBreaker,
      candyCrush,
    };
  });

  app.get('/v1/games/me', async (req) => {
    const user = requireAuth(req);
    const profile = await getProfile(user.sub);
    const scores = await pool.query(
      `SELECT game, score, city, updated_at
       FROM high_scores WHERE user_id = $1
       ORDER BY game`,
      [user.sub],
    );
    return {
      profile,
      scores: scores.rows.map((r) => ({
        game: r.game,
        score: r.score,
        city: r.city,
        updatedAt: r.updated_at,
      })),
    };
  });

  app.put('/v1/games/me/profile', async (req) => {
    const user = requireAuth(req);
    const body = z
      .object({
        displayName: z
          .string()
          .trim()
          .min(2)
          .max(24)
          .regex(/^[a-zA-Z0-9 _.\-]+$/, 'Use letters, numbers, spaces, . _ -'),
        city: z.string().trim().min(2).max(64).default(DEFAULT_CITY),
      })
      .parse(req.body ?? {});

    await pool.query(
      `INSERT INTO player_profiles (user_id, display_name, city, updated_at)
       VALUES ($1,$2,$3,NOW())
       ON CONFLICT (user_id) DO UPDATE
       SET display_name = EXCLUDED.display_name,
           city = EXCLUDED.city,
           updated_at = NOW()`,
      [user.sub, body.displayName, body.city],
    );
    return getProfile(user.sub);
  });

  app.post('/v1/games/scores', async (req) => {
    const user = requireAuth(req);
    const body = z
      .object({
        game: gameSchema,
        score: z.number().int().min(0).max(10_000_000),
        displayName: z
          .string()
          .trim()
          .min(2)
          .max(24)
          .regex(/^[a-zA-Z0-9 _.\-]+$/)
          .optional(),
        city: z.string().trim().min(2).max(64).default(DEFAULT_CITY),
      })
      .parse(req.body ?? {});

    let profile = await getProfile(user.sub);
    if (!profile) {
      const name =
        body.displayName ??
        defaultNameFromPhone(user.phone);
      await pool.query(
        `INSERT INTO player_profiles (user_id, display_name, city, updated_at)
         VALUES ($1,$2,$3,NOW())
         ON CONFLICT (user_id) DO NOTHING`,
        [user.sub, name, body.city],
      );
      profile = await getProfile(user.sub);
    } else if (body.displayName) {
      await pool.query(
        `UPDATE player_profiles
         SET display_name = $2, city = $3, updated_at = NOW()
         WHERE user_id = $1`,
        [user.sub, body.displayName, body.city],
      );
      profile = await getProfile(user.sub);
    }

    if (!profile) {
      throw new AppError('Profile required', 400, 'profile_required');
    }

    const existing = await pool.query(
      `SELECT score FROM high_scores WHERE user_id = $1 AND game = $2`,
      [user.sub, body.game],
    );
    const previous = existing.rowCount ? (existing.rows[0].score as number) : 0;
    const isNewBest = body.score > previous;

    if (isNewBest) {
      await pool.query(
        `INSERT INTO high_scores (user_id, game, score, city, updated_at)
         VALUES ($1,$2,$3,$4,NOW())
         ON CONFLICT (user_id, game) DO UPDATE
         SET score = EXCLUDED.score,
             city = EXCLUDED.city,
             updated_at = NOW()`,
        [user.sub, body.game, body.score, profile.city],
      );
    }

    const leaderboard = await topScores(body.game, profile.city, 3);
    return {
      accepted: true,
      isNewBest,
      personalBest: Math.max(previous, body.score),
      previousBest: previous,
      profile,
      leaderboard,
    };
  });

  await listen(app, port);
}

async function topScores(game: string, city: string, limit: number) {
  const res = await pool.query(
    `SELECT h.score, h.updated_at, p.display_name, p.user_id
     FROM high_scores h
     JOIN player_profiles p ON p.user_id = h.user_id
     WHERE h.game = $1 AND h.city = $2
     ORDER BY h.score DESC, h.updated_at ASC
     LIMIT $3`,
    [game, city, limit],
  );
  return res.rows.map((r, index) => ({
    rank: index + 1,
    userId: r.user_id,
    displayName: r.display_name,
    score: r.score,
    updatedAt: r.updated_at,
  }));
}

async function getProfile(userId: string) {
  const res = await pool.query(
    `SELECT user_id, display_name, city, updated_at
     FROM player_profiles WHERE user_id = $1`,
    [userId],
  );
  if (!res.rowCount) return null;
  const r = res.rows[0];
  return {
    userId: r.user_id as string,
    displayName: r.display_name as string,
    city: r.city as string,
    updatedAt: r.updated_at,
  };
}

function defaultNameFromPhone(phone: string): string {
  const digits = phone.replace(/\D/g, '');
  const tail = digits.slice(-4);
  return `Player_${tail || '0000'}`;
}

async function seed() {
  const demo = [
    {
      id: 'b1000000-0000-4000-8000-000000000001',
      name: 'BoleAce',
      tetris: 4200,
      brick: 3100,
      candy: 6800,
    },
    {
      id: 'b1000000-0000-4000-8000-000000000002',
      name: 'PiassaPro',
      tetris: 3600,
      brick: 4500,
      candy: 5400,
    },
    {
      id: 'b1000000-0000-4000-8000-000000000003',
      name: 'CMC_Knight',
      tetris: 5100,
      brick: 2800,
      candy: 7200,
    },
  ] as const;

  const count = await pool.query(`SELECT COUNT(*)::int AS c FROM high_scores`);
  if (count.rows[0].c === 0) {
    for (const p of demo) {
      await pool.query(
        `INSERT INTO player_profiles (user_id, display_name, city)
         VALUES ($1,$2,$3) ON CONFLICT DO NOTHING`,
        [p.id, p.name, DEFAULT_CITY],
      );
      await pool.query(
        `INSERT INTO high_scores (user_id, game, score, city)
         VALUES ($1,'tetris',$2,$3) ON CONFLICT DO NOTHING`,
        [p.id, p.tetris, DEFAULT_CITY],
      );
      await pool.query(
        `INSERT INTO high_scores (user_id, game, score, city)
         VALUES ($1,'brickBreaker',$2,$3) ON CONFLICT DO NOTHING`,
        [p.id, p.brick, DEFAULT_CITY],
      );
      await pool.query(
        `INSERT INTO high_scores (user_id, game, score, city)
         VALUES ($1,'candyCrush',$2,$3) ON CONFLICT DO NOTHING`,
        [p.id, p.candy, DEFAULT_CITY],
      );
    }
    return;
  }

  // If DB was seeded before candyCrush existed, backfill demo scores.
  const candyCount = await pool.query(
    `SELECT COUNT(*)::int AS c FROM high_scores WHERE game = 'candyCrush'`,
  );
  if (candyCount.rows[0].c === 0) {
    for (const p of demo) {
      await pool.query(
        `INSERT INTO player_profiles (user_id, display_name, city)
         VALUES ($1,$2,$3) ON CONFLICT DO NOTHING`,
        [p.id, p.name, DEFAULT_CITY],
      );
      await pool.query(
        `INSERT INTO high_scores (user_id, game, score, city)
         VALUES ($1,'candyCrush',$2,$3) ON CONFLICT DO NOTHING`,
        [p.id, p.candy, DEFAULT_CITY],
      );
    }
  }
}

boot().catch((err) => {
  console.error(err);
  process.exit(1);
});
