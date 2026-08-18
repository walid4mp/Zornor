import type { GameAction, GameEngine } from './types';

type DominoTile = { id: string; left: number; right: number };

type DominoPlayer = {
  userId: string;
  username: string;
  hand: DominoTile[];
  score: number;
};

export type DominoState = {
  gameId: 'domino';
  players: Array<{
    userId: string;
    username: string;
    handCount: number;
    score: number;
  }>;
  board: DominoTile[];
  boardEnds: { left: number | null; right: number | null };
  turnUserId: string | null;
  boneyardCount: number;
  winnerUserId: string | null;
  status: 'waiting' | 'active' | 'blocked' | 'finished';
};

function fullSet(): DominoTile[] {
  const tiles: DominoTile[] = [];
  for (let left = 0; left <= 6; left += 1) {
    for (let right = left; right <= 6; right += 1) {
      tiles.push({ id: `${left}-${right}`, left, right });
    }
  }
  return tiles.sort(() => Math.random() - 0.5);
}

function pipSum(hand: DominoTile[]) {
  return hand.reduce((sum, tile) => sum + tile.left + tile.right, 0);
}

export class DominoEngine implements GameEngine<DominoState> {
  readonly gameId = 'domino' as const;
  private players: DominoPlayer[] = [];
  private deck: DominoTile[] = [];
  private board: DominoTile[] = [];
  private turnIndex = 0;
  private status: DominoState['status'] = 'waiting';
  private winnerUserId: string | null = null;

  addPlayer(userId: string, username: string) {
    if (this.players.length >= 4) return;
    this.players.push({ userId, username, hand: [], score: 0 });
  }

  start() {
    if (![2, 4].includes(this.players.length)) throw new Error('Domino supports 2 or 4 players');
    this.deck = fullSet();
    const handSize = 7;
    for (let round = 0; round < handSize; round += 1) {
      for (const player of this.players) {
        const tile = this.deck.pop();
        if (tile) player.hand.push(tile);
      }
    }
    this.turnIndex = 0;
    this.status = 'active';
  }

  getCurrentTurnUserId() {
    return this.players[this.turnIndex]?.userId ?? null;
  }

  private boardEnds() {
    if (this.board.length === 0) return { left: null, right: null };
    return { left: this.board[0].left, right: this.board[this.board.length - 1].right };
  }

  private canPlace(tile: DominoTile) {
    const { left, right } = this.boardEnds();
    if (left === null || right === null) return true;
    return [tile.left, tile.right].includes(left) || [tile.left, tile.right].includes(right);
  }

  private normalizeForSide(tile: DominoTile, side: 'left' | 'right') {
    const ends = this.boardEnds();
    if (ends.left === null || ends.right === null) return tile;
    if (side === 'left') {
      if (tile.right === ends.left) return tile;
      if (tile.left === ends.left) return { ...tile, left: tile.right, right: tile.left };
    }
    if (tile.left === ends.right) return tile;
    if (tile.right === ends.right) return { ...tile, left: tile.right, right: tile.left };
    throw new Error('Tile cannot be placed on this side');
  }

  private tryAdvanceTurn() {
    for (let i = 0; i < this.players.length; i += 1) {
      this.turnIndex = (this.turnIndex + 1) % this.players.length;
      const player = this.players[this.turnIndex];
      if (player.hand.some((tile) => this.canPlace(tile)) || this.deck.length > 0) {
        return;
      }
    }

    this.status = 'blocked';
    const sorted = [...this.players].sort((a, b) => pipSum(a.hand) - pipSum(b.hand));
    this.winnerUserId = sorted[0]?.userId ?? null;
  }

  applyAction(userId: string, action: GameAction) {
    if (this.status !== 'active') throw new Error('Game not active');
    const player = this.players[this.turnIndex];
    if (!player || player.userId !== userId) throw new Error('Not your turn');

    if (action.type === 'draw') {
      const tile = this.deck.pop();
      if (!tile) throw new Error('Boneyard is empty');
      player.hand.push(tile);
      if (!this.canPlace(tile)) this.tryAdvanceTurn();
      return this.getState();
    }

    if (action.type !== 'playTile') throw new Error('Unsupported domino action');
    const tileId = String(action.tileId ?? '');
    const side = action.side === 'left' ? 'left' : 'right';
    const index = player.hand.findIndex((tile) => tile.id === tileId);
    if (index === -1) throw new Error('Tile not found');
    const [tile] = player.hand.splice(index, 1);
    if (!this.canPlace(tile)) throw new Error('Illegal tile');

    const normalized = this.normalizeForSide(tile, side);
    if (this.board.length === 0 || side === 'right') this.board.push(normalized);
    else this.board.unshift(normalized);

    if (player.hand.length === 0) {
      this.status = 'finished';
      this.winnerUserId = player.userId;
      player.score += 1;
      return this.getState();
    }

    this.tryAdvanceTurn();
    return this.getState();
  }

  getState(): DominoState {
    const ends = this.boardEnds();
    return {
      gameId: 'domino',
      players: this.players.map((player) => ({
        userId: player.userId,
        username: player.username,
        handCount: player.hand.length,
        score: player.score
      })),
      board: this.board,
      boardEnds: ends,
      turnUserId: this.getCurrentTurnUserId(),
      boneyardCount: this.deck.length,
      winnerUserId: this.winnerUserId,
      status: this.status
    };
  }

  getHandForUser(userId: string) {
    return this.players.find((player) => player.userId === userId)?.hand ?? [];
  }
}
