import { Chess } from 'chess.js';
import type { GameAction, GameEngine } from './types';

type ChessPlayer = { userId: string; username: string; color: 'w' | 'b' };

export type ChessState = {
  gameId: 'chess';
  fen: string;
  turn: 'w' | 'b';
  status: 'waiting' | 'active' | 'check' | 'checkmate' | 'stalemate' | 'draw' | 'resigned';
  players: ChessPlayer[];
  moveHistory: string[];
  winnerUserId: string | null;
};

export class ChessEngine implements GameEngine<ChessState> {
  readonly gameId = 'chess' as const;
  private chess = new Chess();
  private players: ChessPlayer[] = [];
  private started = false;
  private winnerUserId: string | null = null;
  private status: ChessState['status'] = 'waiting';

  addPlayer(userId: string, username: string) {
    if (this.players.length >= 2) return;
    const color: 'w' | 'b' = this.players.length === 0 ? 'w' : 'b';
    this.players.push({ userId, username, color });
  }

  start() {
    if (this.players.length < 2) throw new Error('Chess needs 2 players');
    this.started = true;
    this.status = 'active';
  }

  getCurrentTurnUserId() {
    const current = this.players.find((player) => player.color === this.chess.turn());
    return current?.userId ?? null;
  }

  applyAction(userId: string, action: GameAction) {
    if (!this.started) throw new Error('Game not started');
    if (action.type === 'resign') {
      const resigning = this.players.find((player) => player.userId === userId);
      const winner = this.players.find((player) => player.userId !== userId);
      if (!resigning || !winner) throw new Error('Invalid player');
      this.status = 'resigned';
      this.winnerUserId = winner.userId;
      return this.getState();
    }

    if (this.getCurrentTurnUserId() !== userId) {
      throw new Error('Not your turn');
    }

    if (action.type !== 'move') {
      throw new Error('Unsupported chess action');
    }

    const from = String(action.from ?? '');
    const to = String(action.to ?? '');
    const promotion = typeof action.promotion === 'string' ? action.promotion : 'q';
    const move = this.chess.move({ from, to, promotion });
    if (!move) throw new Error('Illegal move');

    if (this.chess.isCheckmate()) {
      this.status = 'checkmate';
      this.winnerUserId = userId;
    } else if (this.chess.isStalemate()) {
      this.status = 'stalemate';
    } else if (this.chess.isDraw()) {
      this.status = 'draw';
    } else if (this.chess.inCheck()) {
      this.status = 'check';
    } else {
      this.status = 'active';
    }

    return this.getState();
  }

  getState(): ChessState {
    return {
      gameId: 'chess',
      fen: this.chess.fen(),
      turn: this.chess.turn(),
      status: this.status,
      players: this.players,
      moveHistory: this.chess.history(),
      winnerUserId: this.winnerUserId
    };
  }
}
