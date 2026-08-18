import type { Server as HttpServer } from 'http';
import { Server } from 'socket.io';
import { env } from '../config/env';
import { verifyToken } from '../lib/auth';
import { roomManager } from '../services/room-manager';

function parseOrigins(): string[] {
  return Array.from(
    new Set(
      [env.APP_ORIGIN, env.ADMIN_ORIGIN]
        .flatMap((value) => value.split(','))
        .map((value) => value.trim())
        .filter(Boolean)
    )
  );
}

export function attachSocket(server: HttpServer) {
  const origins = parseOrigins();
  const wildcard = origins.includes('*');

  const io = new Server(server, {
    cors: {
      origin: wildcard ? true : origins,
      credentials: !wildcard
    }
  });

  io.use((socket, next) => {
    const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.replace('Bearer ', '');
    if (!token) return next(new Error('Unauthorized'));
    try {
      const payload = verifyToken(String(token));
      socket.data.user = { id: payload.sub, username: payload.username, role: payload.role };
      next();
    } catch {
      next(new Error('Unauthorized'));
    }
  });

  const liveViewers = new Map<string, number>();

  io.on('connection', (socket) => {
    socket.on('live:join', ({ roomId }) => {
      const id = String(roomId ?? '');
      if (!id) return;
      socket.join(`live:${id}`);
      const count = (liveViewers.get(id) ?? 0) + 1;
      liveViewers.set(id, count);
      io.to(`live:${id}`).emit('live:viewers', { count });
    });

    socket.on('live:leave', ({ roomId }) => {
      const id = String(roomId ?? '');
      if (!id) return;
      socket.leave(`live:${id}`);
      const count = Math.max(0, (liveViewers.get(id) ?? 1) - 1);
      if (count === 0) liveViewers.delete(id);
      else liveViewers.set(id, count);
      io.to(`live:${id}`).emit('live:viewers', { count });
    });

    socket.on('live:gift', ({ roomId, gift, price, currency, animation }) => {
      const id = String(roomId ?? '');
      if (!id) return;
      io.to(`live:${id}`).emit('live:gift', {
        roomId: id,
        gift: String(gift ?? '🎁'),
        price: Number(price ?? 0),
        currency: String(currency ?? 'gold'),
        animation: String(animation ?? 'sparkle'),
        senderUsername: socket.data.user.username,
        createdAt: new Date().toISOString()
      });
    });

    socket.on('live:message', ({ roomId, message }) => {
      const id = String(roomId ?? '');
      const text = String(message ?? '').trim();
      if (!id || !text || text.length > 500) return;
      io.to(`live:${id}`).emit('live:message', {
        roomId: id,
        senderUserId: socket.data.user.id,
        senderUsername: socket.data.user.username,
        message: text,
        createdAt: new Date().toISOString()
      });
    });

    socket.on('room:subscribe', ({ roomId }) => {
      socket.join(roomId);
      roomManager.attachSocket(roomId, socket.data.user.id, socket.id);
      const state = roomManager.getPrivateView(roomId, socket.data.user.id);
      socket.emit('room:state', state);
    });

    socket.on('voice:join', ({ voiceRoomId }) => {
      socket.join(`voice:${voiceRoomId}`);
      socket.to(`voice:${voiceRoomId}`).emit('voice:peer-joined', { userId: socket.data.user.id, username: socket.data.user.username });
    });

    socket.on('voice:leave', ({ voiceRoomId }) => {
      socket.leave(`voice:${voiceRoomId}`);
      socket.to(`voice:${voiceRoomId}`).emit('voice:peer-left', { userId: socket.data.user.id });
    });

    socket.on('voice:signal', ({ voiceRoomId, targetUserId, signal }) => {
      for (const peer of io.sockets.sockets.values()) {
        if (peer.data.user?.id === targetUserId) {
          peer.emit('voice:signal', { fromUserId: socket.data.user.id, fromUsername: socket.data.user.username, signal });
          break;
        }
      }
    });

    socket.on('chat:send', ({ roomId, message }) => {
      io.to(roomId).emit('chat:message', {
        roomId,
        senderUserId: socket.data.user.id,
        senderUsername: socket.data.user.username,
        message,
        createdAt: new Date().toISOString()
      });
    });

    socket.on('game:action', async ({ roomId, action }) => {
      try {
        await roomManager.applyAction(roomId, socket.data.user.id, action);
        const room = roomManager.getRoom(roomId);
        if (room) {
          for (const participant of room.participants) {
            if (participant.socketId) {
              io.to(participant.socketId).emit('room:state', roomManager.getPrivateView(roomId, participant.userId));
            }
          }
        }
      } catch (error) {
        socket.emit('game:error', { message: error instanceof Error ? error.message : 'Game action failed' });
      }
    });

    socket.on('disconnect', () => {
      roomManager.detachSocket(socket.id);
      for (const [roomId, count] of liveViewers.entries()) {
        if (socket.rooms.has(`live:${roomId}`)) {
          const next = Math.max(0, count - 1);
          if (next === 0) liveViewers.delete(roomId);
          else liveViewers.set(roomId, next);
          io.to(`live:${roomId}`).emit('live:viewers', { count: next });
        }
      }
    });
  });

  return io;
}
