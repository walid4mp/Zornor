import { Router } from 'express';
import { query } from '../lib/db';
import { friendRequestSchema, purchaseSchema } from '../lib/validation';
import { requireAuth, requireAdmin, type AuthedRequest } from '../middleware/auth';
import { roomManager } from '../services/room-manager';

export const socialRouter = Router();

socialRouter.get('/users/search', requireAuth, async (req: AuthedRequest, res) => {
  const q = `%${String(req.query.q ?? '').trim()}%`;
  const result = await query(
    `SELECT id, username, level, wins, matches FROM users WHERE id <> $1 AND username ILIKE $2 ORDER BY username LIMIT 20`,
    [req.user!.id, q]
  );
  res.json({ users: result.rows });
});

socialRouter.get('/friends', requireAuth, async (req: AuthedRequest, res) => {
  const result = await query(
    `SELECT u.id, u.username, u.level, u.wins, u.matches
     FROM friends f JOIN users u ON u.id = f.friend_user_id
     WHERE f.user_id = $1
     ORDER BY u.username`,
    [req.user!.id]
  );
  const requests = await query(
    `SELECT fr.id, u.username AS sender_username, fr.sender_user_id, fr.status, fr.created_at
     FROM friend_requests fr JOIN users u ON u.id = fr.sender_user_id
     WHERE fr.receiver_user_id=$1 AND fr.status='pending'`,
    [req.user!.id]
  );
  res.json({ friends: result.rows, requests: requests.rows });
});

socialRouter.post('/friends/request', requireAuth, async (req: AuthedRequest, res) => {
  const parsed = friendRequestSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ message: 'Invalid payload', errors: parsed.error.flatten() });
  await query('INSERT INTO friend_requests (sender_user_id, receiver_user_id) VALUES ($1, $2)', [
    req.user!.id,
    parsed.data.receiverUserId
  ]);
  res.status(201).json({ message: 'Friend request sent' });
});

socialRouter.post('/friends/request/:requestId/accept', requireAuth, async (req: AuthedRequest, res) => {
  const request = await query<{ sender_user_id: string; receiver_user_id: string }>(
    `UPDATE friend_requests SET status='accepted'
     WHERE id=$1 AND receiver_user_id=$2
     RETURNING sender_user_id, receiver_user_id`,
    [req.params.requestId, req.user!.id]
  );
  if (!request.rowCount) return res.status(404).json({ message: 'Request not found' });
  const { sender_user_id, receiver_user_id } = request.rows[0];
  await query('INSERT INTO friends (user_id, friend_user_id) VALUES ($1, $2), ($2, $1) ON CONFLICT DO NOTHING', [
    sender_user_id,
    receiver_user_id
  ]);
  res.json({ message: 'Friend request accepted' });
});

socialRouter.get('/shop', requireAuth, async (_req, res) => {
  const result = await query('SELECT * FROM shop_items WHERE is_enabled = TRUE ORDER BY category, price');
  res.json({ items: result.rows });
});

socialRouter.post('/shop/purchase', requireAuth, async (req: AuthedRequest, res) => {
  const parsed = purchaseSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ message: 'Invalid payload', errors: parsed.error.flatten() });

  const itemResult = await query<{ id: string; price: number }>('SELECT id, price FROM shop_items WHERE id=$1 AND is_enabled=TRUE', [
    parsed.data.itemId
  ]);
  const item = itemResult.rows[0];
  if (!item) return res.status(404).json({ message: 'Item not found' });

  const userResult = await query<{ coins: number }>('SELECT coins FROM users WHERE id=$1', [req.user!.id]);
  const user = userResult.rows[0];
  if (!user || user.coins < item.price) return res.status(400).json({ message: 'Not enough coins' });

  await query('UPDATE users SET coins = coins - $2 WHERE id=$1', [req.user!.id, item.price]);
  await query('INSERT INTO user_items (user_id, item_id) VALUES ($1, $2) ON CONFLICT DO NOTHING', [req.user!.id, item.id]);
  await query('INSERT INTO coins_transactions (user_id, amount, reason) VALUES ($1, $2, $3)', [
    req.user!.id,
    -item.price,
    `shop_purchase:${item.id}`
  ]);
  res.json({ message: 'Purchase completed' });
});

socialRouter.get('/missions', requireAuth, async (req: AuthedRequest, res) => {
  const missions = await query('SELECT * FROM missions ORDER BY id');
  const achievements = await query('SELECT * FROM achievements ORDER BY id');
  const events = await query('SELECT * FROM events ORDER BY start_date DESC NULLS LAST');
  const notifications = await query('SELECT * FROM notifications WHERE user_id=$1 ORDER BY created_at DESC LIMIT 30', [req.user!.id]);
  res.json({ missions: missions.rows, achievements: achievements.rows, events: events.rows, notifications: notifications.rows });
});

socialRouter.get('/admin/summary', requireAuth, requireAdmin, async (_req, res) => {
  const [users, activeRooms, matches, transactions, shopItems, events] = await Promise.all([
    query('SELECT COUNT(*)::int AS count FROM users'),
    query("SELECT COUNT(*)::int AS count FROM rooms WHERE status='active'"),
    query('SELECT COUNT(*)::int AS count FROM matches'),
    query('SELECT COUNT(*)::int AS count FROM coins_transactions'),
    query('SELECT * FROM shop_items ORDER BY category, price'),
    query('SELECT * FROM events ORDER BY start_date DESC NULLS LAST')
  ]);
  res.json({
    metrics: {
      users: users.rows[0]?.count ?? 0,
      activeRooms: activeRooms.rows[0]?.count ?? 0,
      matches: matches.rows[0]?.count ?? 0,
      coinTransactions: transactions.rows[0]?.count ?? 0
    },
    shopItems: shopItems.rows,
    events: events.rows,
    rooms: roomManager.getRooms().map((room) => ({
      roomId: room.roomId,
      roomCode: room.roomCode,
      gameId: room.gameId,
      status: room.matchStarted ? 'active' : 'waiting',
      players: room.participants.length
    }))
  });
});
