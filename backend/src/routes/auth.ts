import { Router } from 'express';
import { comparePassword, hashPassword, signToken } from '../lib/auth';
import { query } from '../lib/db';
import { loginSchema, registerSchema } from '../lib/validation';
import { requireAuth, type AuthedRequest } from '../middleware/auth';

export const authRouter = Router();

authRouter.post('/register', async (req, res) => {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ message: 'Invalid payload', errors: parsed.error.flatten() });

  const { email, username, password } = parsed.data;
  const existing = await query('SELECT id FROM users WHERE email=$1 OR username=$2', [email, username]);
  if (existing.rowCount) return res.status(409).json({ message: 'User already exists' });

  const passwordHash = await hashPassword(password);
  const result = await query<{
    id: string;
    username: string;
    role: string;
    coins: number;
    xp: number;
    level: number;
  }>(
    `INSERT INTO users (email, username, password_hash)
     VALUES ($1, $2, $3)
     RETURNING id, username, role, coins, xp, level`,
    [email, username, passwordHash]
  );

  const user = result.rows[0];
  const token = signToken({ sub: user.id, username: user.username, role: user.role });
  res.status(201).json({ token, user });
});

authRouter.post('/login', async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ message: 'Invalid payload', errors: parsed.error.flatten() });
  const { email, password } = parsed.data;

  const result = await query<{
    id: string;
    username: string;
    role: string;
    password_hash: string;
    coins: number;
    xp: number;
    level: number;
  }>('SELECT id, username, role, password_hash, coins, xp, level FROM users WHERE email=$1', [email]);

  const user = result.rows[0];
  if (!user) return res.status(401).json({ message: 'Invalid credentials' });
  const valid = await comparePassword(password, user.password_hash);
  if (!valid) return res.status(401).json({ message: 'Invalid credentials' });

  const token = signToken({ sub: user.id, username: user.username, role: user.role });
  res.json({
    token,
    user: {
      id: user.id,
      username: user.username,
      role: user.role,
      coins: user.coins,
      xp: user.xp,
      level: user.level
    }
  });
});

authRouter.get('/me', requireAuth, async (req: AuthedRequest, res) => {
  const result = await query(
    `SELECT id, email, username, avatar_url, level, xp, coins, wins, matches, ludo_rating, chess_rating, domino_rating, role
     FROM users WHERE id=$1`,
    [req.user!.id]
  );
  res.json({ user: result.rows[0] });
});

authRouter.post('/forgot-password', async (req, res) => {
  const email = String(req.body?.email ?? '');
  if (!email) return res.status(400).json({ message: 'Email is required' });
  res.json({ message: 'Password reset request accepted. Configure SMTP to send emails in production.' });
});

authRouter.post('/reset-password', async (req, res) => {
  const { email, newPassword } = req.body ?? {};
  if (!email || !newPassword) return res.status(400).json({ message: 'Email and newPassword are required' });
  const passwordHash = await hashPassword(String(newPassword));
  await query('UPDATE users SET password_hash=$2 WHERE email=$1', [String(email), passwordHash]);
  res.json({ message: 'Password updated' });
});
