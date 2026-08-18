import { Router } from 'express';
import { pool, query } from '../lib/db';
import { requireAuth, type AuthedRequest } from '../middleware/auth';

export const communityRouter = Router();
communityRouter.use(requireAuth);

communityRouter.get('/economy', async (req: AuthedRequest, res) => {
  const [balance, ledger, stats] = await Promise.all([
    query('SELECT coins FROM users WHERE id=$1', [req.user!.id]),
    query(`SELECT id,kind,amount,balance_after,note,created_at FROM wallet_ledger WHERE user_id=$1 ORDER BY created_at DESC LIMIT 50`, [req.user!.id]),
    query(`SELECT COALESCE(SUM(prize),0)::int AS winnings, COALESCE(SUM(entry_fee),0)::int AS spent_on_matches,
                   COALESCE(SUM(CASE WHEN net < 0 THEN -net ELSE 0 END),0)::int AS losses,
                   COALESCE(SUM(net),0)::int AS net
            FROM match_economy WHERE user_id=$1`, [req.user!.id])
  ]);
  res.json({ coins: balance.rows[0]?.coins ?? 0, ledger: ledger.rows, stats: stats.rows[0] ?? {} });
});

communityRouter.get('/events', async (_req, res) => {
  const [events, offers, tournaments] = await Promise.all([
    query(`SELECT * FROM events WHERE status <> 'ended' ORDER BY start_date DESC NULLS LAST LIMIT 50`),
    query(`SELECT * FROM offers WHERE enabled=TRUE AND (starts_at IS NULL OR starts_at<=NOW()) AND (ends_at IS NULL OR ends_at>=NOW()) ORDER BY starts_at NULLS LAST`),
    query(`SELECT t.*,g.name AS game_name, COUNT(tp.user_id)::int AS players FROM tournaments t JOIN games g ON g.id=t.game_id LEFT JOIN tournament_players tp ON tp.tournament_id=t.id WHERE t.status IN ('upcoming','open','live') GROUP BY t.id,g.name ORDER BY t.starts_at NULLS LAST`)
  ]);
  res.json({ events: events.rows, offers: offers.rows, tournaments: tournaments.rows });
});

communityRouter.post('/tournaments/:id/join', async (req: AuthedRequest, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const t = await client.query(`SELECT * FROM tournaments WHERE id=$1 AND status IN ('upcoming','open') FOR UPDATE`, [req.params.id]);
    if (!t.rowCount) return res.status(404).json({ message: 'Tournament not found or closed' });
    const tournament = t.rows[0];
    const count = await client.query('SELECT COUNT(*)::int AS count FROM tournament_players WHERE tournament_id=$1', [req.params.id]);
    if (count.rows[0].count >= tournament.max_players) return res.status(409).json({ message: 'Tournament is full' });
    const existing = await client.query('SELECT 1 FROM tournament_players WHERE tournament_id=$1 AND user_id=$2', [req.params.id, req.user!.id]);
    if (existing.rowCount) return res.status(409).json({ message: 'Already joined' });
    const user = await client.query('SELECT coins FROM users WHERE id=$1 FOR UPDATE', [req.user!.id]);
    if ((user.rows[0]?.coins ?? 0) < tournament.entry_fee) return res.status(400).json({ message: 'Not enough coins' });
    await client.query('UPDATE users SET coins=coins-$2,updated_at=NOW() WHERE id=$1', [req.user!.id, tournament.entry_fee]);
    await client.query('INSERT INTO tournament_players(tournament_id,user_id) VALUES($1,$2)', [req.params.id, req.user!.id]);
    await client.query(`INSERT INTO coins_transactions(user_id,amount,reason) VALUES($1,$2,$3)`, [req.user!.id, -tournament.entry_fee, `tournament_entry:${req.params.id}`]);
    await client.query(`INSERT INTO wallet_ledger(user_id,kind,amount,balance_after,reference_type,reference_id,note) SELECT $1,'tournament_entry',$2,coins,'tournament',$3,'Tournament entry fee' FROM users WHERE id=$1`, [req.user!.id, -tournament.entry_fee, req.params.id]);
    await client.query('UPDATE tournaments SET status=CASE WHEN status=\'upcoming\' THEN \'open\' ELSE status END, prize_pool=prize_pool+$2 WHERE id=$1', [req.params.id, tournament.entry_fee]);
    await client.query('COMMIT');
    res.status(201).json({ message: 'Joined tournament' });
  } catch (e) { await client.query('ROLLBACK'); throw e; } finally { client.release(); }
});

communityRouter.get('/gifts', async (_req, res) => {
  const r = await query('SELECT * FROM gifts WHERE enabled=TRUE ORDER BY price');
  res.json({ gifts: r.rows });
});

communityRouter.post('/gifts/send', async (req: AuthedRequest, res) => {
  const receiverId = String(req.body?.receiverUserId ?? '');
  const giftId = String(req.body?.giftId ?? '');
  const quantity = Math.max(1, Math.min(50, Number(req.body?.quantity ?? 1)));
  if (!receiverId || !giftId) return res.status(400).json({ message: 'receiverUserId and giftId are required' });
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const gift = await client.query('SELECT * FROM gifts WHERE id=$1 AND enabled=TRUE', [giftId]);
    if (!gift.rowCount) return res.status(404).json({ message: 'Gift not found' });
    const receiver = await client.query('SELECT id FROM users WHERE id=$1', [receiverId]);
    if (!receiver.rowCount || receiverId === req.user!.id) return res.status(400).json({ message: 'Invalid receiver' });
    const total = gift.rows[0].price * quantity;
    const sender = await client.query('SELECT coins FROM users WHERE id=$1 FOR UPDATE', [req.user!.id]);
    if ((sender.rows[0]?.coins ?? 0) < total) return res.status(400).json({ message: 'Not enough coins' });
    await client.query('UPDATE users SET coins=coins-$2 WHERE id=$1', [req.user!.id, total]);
    await client.query('INSERT INTO gift_transactions(sender_user_id,receiver_user_id,gift_id,quantity,total_price) VALUES($1,$2,$3,$4,$5)', [req.user!.id, receiverId, giftId, quantity, total]);
    await client.query(`INSERT INTO coins_transactions(user_id,amount,reason) VALUES($1,$2,$3)`, [req.user!.id, -total, `gift:${giftId}`]);
    await client.query(`INSERT INTO wallet_ledger(user_id,kind,amount,balance_after,reference_type,reference_id,note) SELECT $1,'gift_sent',$2,coins,'gift',$3,$4 FROM users WHERE id=$1`, [req.user!.id, -total, giftId, `Sent ${quantity} ${gift.rows[0].name}`]);
    await client.query(`INSERT INTO notifications(user_id,type,title,body) VALUES($1,'gift','هدية جديدة','وصلتك هدية ${gift.rows[0].emoji} من لاعب')`, [receiverId]);
    await client.query('COMMIT');
    res.status(201).json({ message: 'Gift sent', totalPrice: total });
  } catch (e) { await client.query('ROLLBACK'); throw e; } finally { client.release(); }
});

communityRouter.get('/live', async (_req, res) => {
  const r = await query(`SELECT l.*,u.username,u.avatar_url FROM live_rooms l JOIN users u ON u.id=l.host_user_id WHERE l.status='live' ORDER BY l.viewer_count DESC,l.started_at DESC`);
  res.json({ rooms: r.rows });
});

communityRouter.post('/live', async (req: AuthedRequest, res) => {
  const title = String(req.body?.title ?? 'ZYNORA Live').trim().slice(0,80);
  const description = String(req.body?.description ?? '').trim().slice(0,240);
  const r = await query(`INSERT INTO live_rooms(host_user_id,title,description) VALUES($1,$2,$3) RETURNING *`, [req.user!.id,title,description]);
  res.status(201).json({ room: r.rows[0] });
});

communityRouter.post('/live/:id/gift', async (req: AuthedRequest, res) => {
  const giftId = String(req.body?.giftId ?? '');
  const quantity = Math.max(1, Math.min(50, Number(req.body?.quantity ?? 1)));
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const live = await client.query('SELECT * FROM live_rooms WHERE id=$1 AND status=\'live\' FOR UPDATE', [req.params.id]);
    if (!live.rowCount) return res.status(404).json({ message: 'Live room not found' });
    const gift = await client.query('SELECT * FROM gifts WHERE id=$1 AND enabled=TRUE', [giftId]);
    if (!gift.rowCount) return res.status(404).json({ message: 'Gift not found' });
    const total = gift.rows[0].price * quantity;
    const sender = await client.query('SELECT coins FROM users WHERE id=$1 FOR UPDATE', [req.user!.id]);
    if ((sender.rows[0]?.coins ?? 0) < total) return res.status(400).json({ message: 'Not enough coins' });
    await client.query('UPDATE users SET coins=coins-$2 WHERE id=$1', [req.user!.id,total]);
    await client.query(`INSERT INTO live_room_gifts(live_room_id,sender_user_id,receiver_user_id,gift_id,quantity,total_price) VALUES($1,$2,$3,$4,$5,$6)`, [req.params.id,req.user!.id,live.rows[0].host_user_id,giftId,quantity,total]);
    await client.query(`INSERT INTO coins_transactions(user_id,amount,reason) VALUES($1,$2,$3)`, [req.user!.id,-total,`live_gift:${req.params.id}`]);
    await client.query(`INSERT INTO notifications(user_id,type,title,body) VALUES($1,'live_gift','هدية في اللايف','أرسل لك لاعب ${gift.rows[0].emoji} هدية')`, [live.rows[0].host_user_id]);
    await client.query('COMMIT');
    res.json({ message:'Gift sent to live room', totalPrice: total });
  } catch(e){await client.query('ROLLBACK');throw e;} finally{client.release();}
});

communityRouter.get('/voice-rooms', async (_req,res)=>{
  const r=await query(`SELECT v.*,u.username,COUNT(m.user_id)::int AS members FROM voice_rooms v JOIN users u ON u.id=v.host_user_id LEFT JOIN voice_room_members m ON m.voice_room_id=v.id WHERE v.status='open' GROUP BY v.id,u.username ORDER BY v.created_at DESC`);
  res.json({rooms:r.rows});
});
communityRouter.post('/voice-rooms', async(req:AuthedRequest,res)=>{
  const name=String(req.body?.name??'ZYNORA Lounge').trim().slice(0,60);
  const maxSpeakers=Math.max(2,Math.min(16,Number(req.body?.maxSpeakers??8)));
  const r=await query(`INSERT INTO voice_rooms(host_user_id,name,max_speakers) VALUES($1,$2,$3) RETURNING *`,[req.user!.id,name,maxSpeakers]);
  await query(`INSERT INTO voice_room_members(voice_room_id,user_id,role) VALUES($1,$2,'speaker')`,[r.rows[0].id,req.user!.id]);
  res.status(201).json({room:r.rows[0]});
});
communityRouter.post('/voice-rooms/:id/join', async(req:AuthedRequest,res)=>{
  const r=await query(`SELECT * FROM voice_rooms WHERE id=$1 AND status='open'`,[req.params.id]);
  if(!r.rowCount)return res.status(404).json({message:'Voice room not found'});
  await query(`INSERT INTO voice_room_members(voice_room_id,user_id,role) VALUES($1,$2,'listener') ON CONFLICT DO NOTHING`,[req.params.id,req.user!.id]);
  res.json({room:r.rows[0]});
});
communityRouter.get('/notifications', async(req:AuthedRequest,res)=>{
  const r=await query(`SELECT * FROM notifications WHERE user_id=$1 ORDER BY created_at DESC LIMIT 100`,[req.user!.id]);
  res.json({notifications:r.rows});
});
communityRouter.post('/notifications/read-all', async(req:AuthedRequest,res)=>{
  await query('UPDATE notifications SET is_read=TRUE WHERE user_id=$1',[req.user!.id]);
  res.json({message:'Notifications marked as read'});
});
