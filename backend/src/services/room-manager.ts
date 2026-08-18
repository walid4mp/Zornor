import { randomBytes, randomUUID } from 'crypto';
import { query } from '../lib/db';
import { createEngine } from '../games/factory';
import { DominoEngine } from '../games/domino';
import type { GameId, GameAction, GameEngine } from '../games/types';

export type RoomParticipant = {
  userId: string;
  username: string;
  connected: boolean;
  socketId?: string;
};

export type RoomRecord = {
  roomId: string;
  roomCode: string;
  gameId: GameId;
  isPrivate: boolean;
  maxPlayers: number;
  participants: RoomParticipant[];
  engine: GameEngine<unknown>;
  matchStarted: boolean;
  completed: boolean;
  createdAt: string;
};

class RoomManager {
  private rooms = new Map<string, RoomRecord>();

  private generateCode() {
    return randomBytes(3).toString('hex').toUpperCase();
  }

  getRooms(gameId?: GameId) {
    return Array.from(this.rooms.values()).filter((room) => (gameId ? room.gameId === gameId : true));
  }

  getRoom(roomId: string) {
    return this.rooms.get(roomId);
  }

  async createRoom(options: {
    roomId: string;
    hostUserId: string;
    hostUsername: string;
    gameId: GameId;
    isPrivate: boolean;
    maxPlayers: number;
  }) {
    const engine = createEngine(options.gameId);
    const room: RoomRecord = {
      roomId: options.roomId,
      roomCode: this.generateCode(),
      gameId: options.gameId,
      isPrivate: options.isPrivate,
      maxPlayers: options.maxPlayers,
      participants: [{ userId: options.hostUserId, username: options.hostUsername, connected: true }],
      engine,
      matchStarted: false,
      completed: false,
      createdAt: new Date().toISOString()
    };

    engine.addPlayer(options.hostUserId, options.hostUsername);
    this.rooms.set(room.roomId, room);

    await query(
      `INSERT INTO rooms (id, game_id, room_code, is_private, host_user_id, status, max_players)
       VALUES ($1, $2, $3, $4, $5, 'waiting', $6)
       ON CONFLICT (id) DO NOTHING`,
      [room.roomId, room.gameId, room.roomCode, room.isPrivate, options.hostUserId, room.maxPlayers]
    );

    return room;
  }

  async joinRoom(roomId: string, userId: string, username: string) {
    const room = this.rooms.get(roomId);
    if (!room) throw new Error('Room not found');
    if (room.participants.some((participant) => participant.userId === userId)) {
      return room;
    }
    if (room.participants.length >= room.maxPlayers) {
      throw new Error('Room is full');
    }

    room.participants.push({ userId, username, connected: true });
    room.engine.addPlayer(userId, username);
    const requiredPlayers = Math.min(2, room.maxPlayers);
    if (room.participants.length >= requiredPlayers && !room.matchStarted) {
      room.engine.start();
      room.matchStarted = true;
      await query(
        `INSERT INTO matches (room_id, game_id, status, state_json)
         VALUES ($1, $2, 'active', $3)
         ON CONFLICT DO NOTHING`,
        [room.roomId, room.gameId, JSON.stringify(room.engine.getState())]
      );
      await query(`UPDATE rooms SET status='active' WHERE id=$1`, [room.roomId]);
    }
    return room;
  }

  async quickMatch(gameId: GameId, userId: string, username: string) {
    const openRoom = this.getRooms(gameId).find(
      (room) => !room.isPrivate && room.participants.length < room.maxPlayers && !room.participants.some((p) => p.userId === userId)
    );
    if (openRoom) {
      await this.joinRoom(openRoom.roomId, userId, username);
      return openRoom;
    }
    return this.createRoom({
      roomId: randomUUID(),
      hostUserId: userId,
      hostUsername: username,
      gameId,
      isPrivate: false,
      maxPlayers: gameId === 'chess' ? 2 : 2
    });
  }

  attachSocket(roomId: string, userId: string, socketId: string) {
    const room = this.rooms.get(roomId);
    if (!room) return;
    const participant = room.participants.find((item) => item.userId === userId);
    if (participant) {
      participant.connected = true;
      participant.socketId = socketId;
    }
  }

  detachSocket(socketId: string) {
    for (const room of this.rooms.values()) {
      const participant = room.participants.find((item) => item.socketId === socketId);
      if (participant) {
        participant.connected = false;
      }
    }
  }

  async applyAction(roomId: string, userId: string, action: GameAction) {
    const room = this.rooms.get(roomId);
    if (!room) throw new Error('Room not found');
    if (!room.matchStarted) throw new Error('The match has not started yet');
    if (room.completed) throw new Error('This match has already finished');
    const state = room.engine.applyAction(userId, action);

    await query(`UPDATE matches SET state_json=$2 WHERE room_id=$1`, [roomId, JSON.stringify(state)]);

    const winnerUserId = (state as { winnerUserId?: string | null }).winnerUserId ?? null;
    if (winnerUserId && !room.completed) {
      await query(`UPDATE matches SET status='finished', winner_user_id=$2, ended_at=NOW(), state_json=$3 WHERE room_id=$1`, [
        roomId,
        winnerUserId,
        JSON.stringify(state)
      ]);
      await query(`UPDATE rooms SET status='finished' WHERE id=$1`, [roomId]);
      await query(`UPDATE users SET wins = wins + 1, coins = coins + 50, xp = xp + 35 WHERE id = $1`, [winnerUserId]);
      await query(`INSERT INTO coins_transactions (user_id, amount, reason) VALUES ($1, 50, 'match_win')`, [winnerUserId]);
      await query(`INSERT INTO xp_transactions (user_id, amount, reason) VALUES ($1, 35, 'match_win')`, [winnerUserId]);
      await query(`INSERT INTO match_economy(match_id,user_id,entry_fee,prize,net) SELECT id,$2,0,50,50 FROM matches WHERE room_id=$1 ORDER BY created_at DESC LIMIT 1`, [roomId,winnerUserId]);
      await query(`INSERT INTO wallet_ledger(user_id,kind,amount,balance_after,reference_type,reference_id,note) SELECT $1,'match_win',50,coins,'match',$2,'Match victory reward' FROM users WHERE id=$1`, [winnerUserId,roomId]);
      for (const participant of room.participants) {
        await query(`UPDATE users SET matches = matches + 1 WHERE id=$1`, [participant.userId]);
        if (participant.userId !== winnerUserId) {
          await query(`INSERT INTO match_economy(match_id,user_id,entry_fee,prize,net) SELECT id,$2,0,0,0 FROM matches WHERE room_id=$1 ORDER BY created_at DESC LIMIT 1`, [roomId,participant.userId]);
        }
      }
      room.completed = true;
    }

    return state;
  }

  getPrivateView(roomId: string, userId: string) {
    const room = this.rooms.get(roomId);
    if (!room) return null;
    const baseState = room.engine.getState() as Record<string, unknown>;
    if (room.gameId === 'domino') {
      const hand = (room.engine as DominoEngine).getHandForUser(userId);
      return { ...baseState, myHand: hand };
    }
    return baseState;
  }
}

export const roomManager = new RoomManager();
