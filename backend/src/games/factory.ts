import { ChessEngine } from './chess';
import { DominoEngine } from './domino';
import { LudoEngine } from './ludo';
import type { GameEngine, GameId } from './types';

export function createEngine(gameId: GameId): GameEngine<unknown> {
  switch (gameId) {
    case 'chess':
      return new ChessEngine();
    case 'ludo':
      return new LudoEngine();
    case 'domino':
      return new DominoEngine();
    default:
      throw new Error(`Unsupported game: ${gameId satisfies never}`);
  }
}
