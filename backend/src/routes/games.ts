import { Router } from 'express';
import { query } from '../lib/db';

export const gamesRouter = Router();

gamesRouter.get('/', async (_req, res) => {
  const result = await query('SELECT * FROM games WHERE is_enabled = TRUE ORDER BY display_order ASC');
  res.json({ games: result.rows });
});

gamesRouter.get('/leaderboards', async (_req, res) => {
  const [global, chess, ludo, domino] = await Promise.all([
    query(`SELECT username, wins, matches, level, xp FROM users ORDER BY wins DESC, xp DESC LIMIT 20`),
    query(`SELECT username, chess_rating AS rating FROM users ORDER BY chess_rating DESC LIMIT 20`),
    query(`SELECT username, ludo_rating AS rating FROM users ORDER BY ludo_rating DESC LIMIT 20`),
    query(`SELECT username, domino_rating AS rating FROM users ORDER BY domino_rating DESC LIMIT 20`)
  ]);

  res.json({
    global: global.rows,
    chess: chess.rows,
    ludo: ludo.rows,
    domino: domino.rows
  });
});
