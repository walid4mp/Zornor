import { Router } from 'express';
import crypto from 'crypto';
import { createRoomSchema } from '../lib/validation';
import { requireAuth, type AuthedRequest } from '../middleware/auth';
import { roomManager } from '../services/room-manager';

export const roomsRouter = Router();
roomsRouter.use(requireAuth);

roomsRouter.get('/', async (req, res) => {
  const gameId = req.query.gameId as 'ludo' | 'chess' | 'domino' | undefined;
  const rooms = roomManager.getRooms(gameId).map((room) => ({
    roomId: room.roomId,
    roomCode: room.roomCode,
    gameId: room.gameId,
    isPrivate: room.isPrivate,
    maxPlayers: room.maxPlayers,
    playerCount: room.participants.length,
    matchStarted: room.matchStarted
  }));
  res.json({ rooms });
});

roomsRouter.post('/', async (req: AuthedRequest, res) => {
  const parsed = createRoomSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ message: 'Invalid payload', errors: parsed.error.flatten() });

  const room = await roomManager.createRoom({
    roomId: crypto.randomUUID(),
    hostUserId: req.user!.id,
    hostUsername: req.user!.username,
    ...parsed.data
  });

  res.status(201).json({ room });
});

roomsRouter.post('/:roomId/join', async (req: AuthedRequest, res) => {
  const roomId = String(req.params.roomId);
  const room = await roomManager.joinRoom(roomId, req.user!.id, req.user!.username);
  res.json({ room, state: roomManager.getPrivateView(room.roomId, req.user!.id) });
});

roomsRouter.post('/quick-match', async (req: AuthedRequest, res) => {
  const gameId = req.body?.gameId as 'ludo' | 'chess' | 'domino';
  if (!['ludo', 'chess', 'domino'].includes(gameId)) {
    return res.status(400).json({ message: 'Invalid gameId' });
  }
  const room = await roomManager.quickMatch(gameId, req.user!.id, req.user!.username);
  res.json({ room, searching: !room.matchStarted });
});
