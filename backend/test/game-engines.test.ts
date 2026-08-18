import { describe, expect, it } from 'vitest';
import { ChessEngine } from '../src/games/chess';
import { DominoEngine } from '../src/games/domino';
import { LudoEngine } from '../src/games/ludo';

describe('game engines', () => {
  it('plays legal chess opening moves', () => {
    const engine = new ChessEngine();
    engine.addPlayer('u1', 'white');
    engine.addPlayer('u2', 'black');
    engine.start();
    engine.applyAction('u1', { type: 'move', from: 'e2', to: 'e4' });
    engine.applyAction('u2', { type: 'move', from: 'e7', to: 'e5' });
    expect(engine.getState().moveHistory.length).toBe(2);
  });

  it('starts domino and distributes hands', () => {
    const engine = new DominoEngine();
    engine.addPlayer('a', 'A');
    engine.addPlayer('b', 'B');
    engine.start();
    const state = engine.getState();
    expect(state.players[0].handCount).toBe(7);
    expect(state.players[1].handCount).toBe(7);
  });

  it('starts ludo with two players', () => {
    const engine = new LudoEngine();
    engine.addPlayer('a', 'A');
    engine.addPlayer('b', 'B');
    engine.start();
    const state = engine.getState();
    expect(state.status).toBe('active');
    expect(state.players.length).toBe(2);
  });
});
