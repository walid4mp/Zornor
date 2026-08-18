export type GameId = 'ludo' | 'chess' | 'domino';

export type GameAction = {
  type: string;
  [key: string]: unknown;
};

export interface GameEngine<State> {
  readonly gameId: GameId;
  getState(): State;
  getCurrentTurnUserId(): string | null;
  addPlayer(userId: string, username: string): void;
  start(): void;
  applyAction(userId: string, action: GameAction): State;
}
