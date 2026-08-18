CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  avatar_url TEXT,
  level INTEGER NOT NULL DEFAULT 1,
  xp INTEGER NOT NULL DEFAULT 0,
  coins INTEGER NOT NULL DEFAULT 100,
  wins INTEGER NOT NULL DEFAULT 0,
  matches INTEGER NOT NULL DEFAULT 0,
  ludo_rating INTEGER NOT NULL DEFAULT 1000,
  chess_rating INTEGER NOT NULL DEFAULT 1000,
  domino_rating INTEGER NOT NULL DEFAULT 1000,
  email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  role TEXT NOT NULL DEFAULT 'user',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS games (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  min_players INTEGER NOT NULL,
  max_players INTEGER NOT NULL,
  is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  is_matchmaking_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  display_order INTEGER NOT NULL DEFAULT 0,
  image_url TEXT
);

CREATE TABLE IF NOT EXISTS rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id TEXT NOT NULL REFERENCES games(id),
  room_code TEXT UNIQUE NOT NULL,
  is_private BOOLEAN NOT NULL DEFAULT FALSE,
  host_user_id UUID REFERENCES users(id),
  status TEXT NOT NULL DEFAULT 'waiting',
  max_players INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID REFERENCES rooms(id),
  game_id TEXT NOT NULL REFERENCES games(id),
  status TEXT NOT NULL DEFAULT 'active',
  winner_user_id UUID REFERENCES users(id),
  state_json JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID REFERENCES matches(id),
  user_id UUID REFERENCES users(id),
  seat_index INTEGER NOT NULL,
  score INTEGER NOT NULL DEFAULT 0,
  is_winner BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS friends (
  user_id UUID REFERENCES users(id),
  friend_user_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, friend_user_id)
);

CREATE TABLE IF NOT EXISTS friend_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_user_id UUID REFERENCES users(id),
  receiver_user_id UUID REFERENCES users(id),
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID REFERENCES rooms(id),
  sender_user_id UUID REFERENCES users(id),
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS coins_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  amount INTEGER NOT NULL,
  reason TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS xp_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  amount INTEGER NOT NULL,
  reason TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS achievements (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  reward_coins INTEGER NOT NULL DEFAULT 0,
  reward_xp INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS user_achievements (
  user_id UUID REFERENCES users(id),
  achievement_id TEXT REFERENCES achievements(id),
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, achievement_id)
);

CREATE TABLE IF NOT EXISTS missions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  reward_coins INTEGER NOT NULL DEFAULT 0,
  reward_xp INTEGER NOT NULL DEFAULT 0,
  game_id TEXT REFERENCES games(id)
);

CREATE TABLE IF NOT EXISTS events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  reward_json JSONB NOT NULL DEFAULT '{}',
  requirements_json JSONB NOT NULL DEFAULT '{}',
  status TEXT NOT NULL DEFAULT 'draft',
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS shop_items (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  image_url TEXT,
  price INTEGER NOT NULL,
  is_enabled BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS user_items (
  user_id UUID REFERENCES users(id),
  item_id TEXT REFERENCES shop_items(id),
  acquired_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, item_id)
);

CREATE TABLE IF NOT EXISTS advertisements (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  impressions INTEGER NOT NULL DEFAULT 0,
  clicks INTEGER NOT NULL DEFAULT 0,
  ctr NUMERIC NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id UUID REFERENCES users(id),
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  payload_json JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value_json JSONB NOT NULL DEFAULT '{}'
);

INSERT INTO games (id, name, description, min_players, max_players, display_order)
VALUES
  ('ludo', 'Ludo', 'Classic social board race for 2-4 players.', 2, 4, 1),
  ('chess', 'Chess', 'Competitive strategy duel with real chess rules.', 2, 2, 2),
  ('domino', 'Domino', 'Domino matches with real tile distribution and scoring.', 2, 4, 3)
ON CONFLICT (id) DO NOTHING;

INSERT INTO achievements (id, name, description, reward_coins, reward_xp)
VALUES
  ('first_win', 'First Win', 'Win your first match.', 50, 30),
  ('ten_wins', '10 Wins', 'Win 10 matches.', 120, 80),
  ('hundred_matches', '100 Matches', 'Play 100 matches.', 300, 150),
  ('seven_day_streak', '7 Day Streak', 'Play 7 days in a row.', 150, 100),
  ('chess_master', 'Chess Master', 'Win 25 chess matches.', 200, 120),
  ('ludo_champion', 'Ludo Champion', 'Win 25 ludo matches.', 200, 120),
  ('domino_champion', 'Domino Champion', 'Win 25 domino matches.', 200, 120)
ON CONFLICT (id) DO NOTHING;

INSERT INTO missions (id, name, description, reward_coins, reward_xp, game_id)
VALUES
  ('play_match', 'Play 1 Match', 'Complete one match in any game.', 25, 15, NULL),
  ('win_match', 'Win 1 Match', 'Win one match in any game.', 60, 30, NULL),
  ('play_chess', 'Play Chess', 'Finish one chess match.', 30, 20, 'chess'),
  ('play_ludo', 'Play Ludo', 'Finish one ludo match.', 30, 20, 'ludo'),
  ('play_domino', 'Play Domino', 'Finish one domino match.', 30, 20, 'domino'),
  ('invite_friend', 'Invite Friend', 'Invite one friend to a room.', 40, 20, NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO shop_items (id, category, name, description, image_url, price, is_enabled)
VALUES
  ('avatar_neon_fox', 'avatars', 'Neon Fox', 'Animated premium avatar style.', NULL, 120, TRUE),
  ('frame_aurora', 'frames', 'Aurora Frame', 'Gradient profile frame.', NULL, 180, TRUE),
  ('emote_gg', 'emotes', 'GG Emote', 'Quick victory emote.', NULL, 45, TRUE),
  ('theme_midnight', 'themes', 'Midnight Pulse', 'Dark premium UI theme.', NULL, 250, TRUE),
  ('dice_skin_plasma', 'dice_skins', 'Plasma Dice', 'Glowing ludo dice skin.', NULL, 90, TRUE),
  ('cosmetic_confetti', 'cosmetics', 'Victory Confetti', 'Premium match victory confetti.', NULL, 150, TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO advertisements (id, name, type, enabled)
VALUES
  ('banner_default', 'Default Banner', 'banner', TRUE),
  ('interstitial_default', 'Default Interstitial', 'interstitial', TRUE),
  ('rewarded_default', 'Default Rewarded', 'rewarded', TRUE)
ON CONFLICT (id) DO NOTHING;


CREATE INDEX IF NOT EXISTS idx_rooms_status_game ON rooms(status, game_id);
CREATE INDEX IF NOT EXISTS idx_matches_room_status ON matches(room_id, status);
CREATE INDEX IF NOT EXISTS idx_messages_room_created_at ON messages(room_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_created_at ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_friend_requests_receiver_status ON friend_requests(receiver_user_id, status);


CREATE TABLE IF NOT EXISTS coin_packages (
  id TEXT PRIMARY KEY, name TEXT NOT NULL, coins INTEGER NOT NULL, price_cents INTEGER NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD', is_enabled BOOLEAN NOT NULL DEFAULT TRUE, display_order INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS recharge_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES users(id), package_id TEXT NOT NULL REFERENCES coin_packages(id),
  payment_method TEXT NOT NULL, payment_reference TEXT, status TEXT NOT NULL DEFAULT 'pending', admin_note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), reviewed_at TIMESTAMPTZ
);
INSERT INTO coin_packages (id,name,coins,price_cents,currency,display_order) VALUES
 ('coins_1000','1,000 Coins',1000,199,'USD',1),('coins_5500','5,500 Coins',5500,799,'USD',2),
 ('coins_12000','12,000 Coins',12000,1499,'USD',3),('coins_30000','30,000 Coins',30000,2999,'USD',4)
ON CONFLICT (id) DO NOTHING;
CREATE INDEX IF NOT EXISTS idx_recharge_requests_status ON recharge_requests(status,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_recharge_requests_user ON recharge_requests(user_id,created_at DESC);

-- ZYNORA social/economy/live expansion
CREATE TABLE IF NOT EXISTS wallet_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  kind TEXT NOT NULL,
  amount INTEGER NOT NULL,
  balance_after INTEGER,
  reference_type TEXT,
  reference_id TEXT,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS match_economy (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID REFERENCES matches(id),
  user_id UUID NOT NULL REFERENCES users(id),
  entry_fee INTEGER NOT NULL DEFAULT 0,
  prize INTEGER NOT NULL DEFAULT 0,
  net INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS tournaments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id TEXT NOT NULL REFERENCES games(id),
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  entry_fee INTEGER NOT NULL DEFAULT 0,
  prize_pool INTEGER NOT NULL DEFAULT 0,
  max_players INTEGER NOT NULL DEFAULT 16,
  status TEXT NOT NULL DEFAULT 'upcoming',
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ
);
CREATE TABLE IF NOT EXISTS tournament_players (
  tournament_id UUID REFERENCES tournaments(id),
  user_id UUID REFERENCES users(id),
  score INTEGER NOT NULL DEFAULT 0,
  rank INTEGER,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY(tournament_id,user_id)
);
CREATE TABLE IF NOT EXISTS offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  reward_json JSONB NOT NULL DEFAULT '{}',
  price INTEGER NOT NULL DEFAULT 0,
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  enabled BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE IF NOT EXISTS gifts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  emoji TEXT NOT NULL,
  price INTEGER NOT NULL,
  animation TEXT NOT NULL DEFAULT 'sparkle',
  enabled BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE IF NOT EXISTS gift_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_user_id UUID NOT NULL REFERENCES users(id),
  receiver_user_id UUID NOT NULL REFERENCES users(id),
  gift_id TEXT NOT NULL REFERENCES gifts(id),
  room_id UUID REFERENCES rooms(id),
  quantity INTEGER NOT NULL DEFAULT 1,
  total_price INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS live_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_user_id UUID NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'live',
  viewer_count INTEGER NOT NULL DEFAULT 0,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ
);
CREATE TABLE IF NOT EXISTS live_room_gifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  live_room_id UUID NOT NULL REFERENCES live_rooms(id),
  sender_user_id UUID NOT NULL REFERENCES users(id),
  receiver_user_id UUID REFERENCES users(id),
  gift_id TEXT NOT NULL REFERENCES gifts(id),
  quantity INTEGER NOT NULL DEFAULT 1,
  total_price INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS voice_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_user_id UUID NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open',
  max_speakers INTEGER NOT NULL DEFAULT 8,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS voice_room_members (
  voice_room_id UUID REFERENCES voice_rooms(id),
  user_id UUID REFERENCES users(id),
  role TEXT NOT NULL DEFAULT 'listener',
  muted BOOLEAN NOT NULL DEFAULT FALSE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY(voice_room_id,user_id)
);
CREATE INDEX IF NOT EXISTS idx_wallet_ledger_user_created ON wallet_ledger(user_id,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_match_economy_user_created ON match_economy(user_id,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tournaments_status_start ON tournaments(status,starts_at);
CREATE INDEX IF NOT EXISTS idx_live_rooms_status ON live_rooms(status,started_at DESC);

INSERT INTO gifts(id,name,emoji,price,animation) VALUES
 ('rose','Rose','🌹',10,'rose'),('heart','Heart','💖',25,'heart'),('fire','Fire','🔥',50,'fire'),
 ('crown','Crown','👑',250,'crown'),('diamond','Diamond','💎',1000,'diamond'),('rocket','Rocket','🚀',2500,'rocket')
ON CONFLICT(id) DO NOTHING;
INSERT INTO offers(title,description,reward_json,price,starts_at,ends_at) VALUES
 ('Welcome Boost','Starter bundle for new players','{"coins":500,"xp":100}',0,NOW(),NOW()+INTERVAL '30 days'),
 ('Weekend Arena','Play 5 matches this weekend for a bonus','{"coins":750,"xp":250}',0,NOW(),NOW()+INTERVAL '7 days')
ON CONFLICT DO NOTHING;
INSERT INTO tournaments(game_id,name,description,entry_fee,prize_pool,max_players,status,starts_at)
VALUES ('ludo','ZYNORA Ludo Cup','بطولة لودو أسبوعية تنافسية',100,1500,16,'upcoming',NOW()+INTERVAL '1 day'),
       ('chess','ZYNORA Chess Masters','بطولة شطرنج بنظام نقاط',250,4000,16,'upcoming',NOW()+INTERVAL '2 days')
ON CONFLICT DO NOTHING;
