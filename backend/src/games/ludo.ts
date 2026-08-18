import type { GameAction, GameEngine } from './types';

const ENTRY_INDEX: Record<string, number> = {
  red: 0,
  blue: 13,
  green: 26,
  yellow: 39
};

const COLORS = ['red', 'blue', 'green', 'yellow'] as const;
type LudoColor = (typeof COLORS)[number];

type PieceState = {
  id: string;
  steps: number; // -1 in base, 0..56 in track/home
  isHome: boolean;
};

type LudoPlayer = {
  userId: string;
  username: string;
  color: LudoColor;
  pieces: PieceState[];
  finishedPieces: number;
};

export type LudoState = {
  gameId: 'ludo';
  players: LudoPlayer[];
  turnUserId: string | null;
  currentDice: number | null;
  lastRollUserId: string | null;
  winnerUserId: string | null;
  status: 'waiting' | 'active' | 'finished';
};

function createPieces(color: LudoColor): PieceState[] {
  return Array.from({ length: 4 }, (_, index) => ({
    id: `${color}-${index + 1}`,
    steps: -1,
    isHome: false
  }));
}

function isSafeSpot(globalIndex: number) {
  return [0, 8, 13, 21, 26, 34, 39, 47].includes(globalIndex);
}

function globalTrackIndex(player: LudoPlayer, piece: PieceState) {
  if (piece.steps < 0 || piece.steps > 50) return null;
  return (ENTRY_INDEX[player.color] + piece.steps) % 52;
}

export class LudoEngine implements GameEngine<LudoState> {
  readonly gameId = 'ludo' as const;
  private players: LudoPlayer[] = [];
  private turnIndex = 0;
  private currentDice: number | null = null;
  private status: LudoState['status'] = 'waiting';
  private winnerUserId: string | null = null;

  addPlayer(userId: string, username: string) {
    if (this.players.length >= 4) return;
    const color = COLORS[this.players.length];
    this.players.push({
      userId,
      username,
      color,
      pieces: createPieces(color),
      finishedPieces: 0
    });
  }

  start() {
    if (this.players.length < 2) throw new Error('Ludo needs at least 2 players');
    this.status = 'active';
  }

  getCurrentTurnUserId() {
    return this.players[this.turnIndex]?.userId ?? null;
  }

  private nextTurn(extraTurn = false) {
    if (!extraTurn) {
      this.turnIndex = (this.turnIndex + 1) % this.players.length;
    }
    this.currentDice = null;
  }

  private getMovablePieces(player: LudoPlayer, dice: number) {
    return player.pieces.filter((piece) => {
      if (piece.isHome) return false;
      if (piece.steps === -1) return dice === 6;
      return piece.steps + dice <= 56;
    });
  }

  private captureIfNeeded(player: LudoPlayer, movedPiece: PieceState) {
    const movedIndex = globalTrackIndex(player, movedPiece);
    if (movedIndex === null || isSafeSpot(movedIndex)) return;

    for (const opponent of this.players) {
      if (opponent.userId === player.userId) continue;
      for (const piece of opponent.pieces) {
        if (piece.isHome || piece.steps < 0 || piece.steps > 50) continue;
        if (globalTrackIndex(opponent, piece) === movedIndex) {
          piece.steps = -1;
          piece.isHome = false;
        }
      }
    }
  }

  applyAction(userId: string, action: GameAction) {
    if (this.status !== 'active') throw new Error('Game not active');
    const player = this.players[this.turnIndex];
    if (!player || player.userId !== userId) throw new Error('Not your turn');

    if (action.type === 'rollDice') {
      if (this.currentDice !== null) throw new Error('Dice already rolled');
      const forced = typeof action.forcedDice === 'number' ? action.forcedDice : undefined;
      const dice = forced && forced >= 1 && forced <= 6 ? forced : (Math.floor(Math.random() * 6) + 1);
      this.currentDice = dice;
      const movable = this.getMovablePieces(player, dice);
      if (movable.length === 0) {
        this.nextTurn(false);
      }
      return this.getState();
    }

    if (action.type !== 'movePiece') throw new Error('Unsupported ludo action');
    if (this.currentDice === null) throw new Error('Roll dice first');

    const pieceId = String(action.pieceId ?? '');
    const piece = player.pieces.find((item) => item.id === pieceId);
    if (!piece) throw new Error('Piece not found');
    const dice = this.currentDice;

    if (piece.steps === -1) {
      if (dice !== 6) throw new Error('Need 6 to leave base');
      piece.steps = 0;
    } else {
      if (piece.steps + dice > 56) throw new Error('Move exceeds home');
      piece.steps += dice;
      if (piece.steps === 56) {
        piece.isHome = true;
        player.finishedPieces += 1;
      }
    }

    if (!piece.isHome) {
      this.captureIfNeeded(player, piece);
    }

    if (player.finishedPieces === 4) {
      this.status = 'finished';
      this.winnerUserId = player.userId;
      this.currentDice = null;
      return this.getState();
    }

    this.nextTurn(dice === 6);
    return this.getState();
  }

  getState(): LudoState {
    return {
      gameId: 'ludo',
      players: this.players,
      turnUserId: this.getCurrentTurnUserId(),
      currentDice: this.currentDice,
      lastRollUserId: this.currentDice === null ? null : this.getCurrentTurnUserId(),
      winnerUserId: this.winnerUserId,
      status: this.status
    };
  }
}
