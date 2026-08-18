import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().email(),
  username: z.string().min(3).max(24).regex(/^[a-zA-Z0-9_]+$/),
  password: z.string().min(8).max(72)
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).max(72)
});

export const createRoomSchema = z.object({
  gameId: z.enum(['ludo', 'chess', 'domino']),
  isPrivate: z.boolean().default(false),
  maxPlayers: z.number().int().min(2).max(4)
});

export const friendRequestSchema = z.object({
  receiverUserId: z.string().uuid()
});

export const purchaseSchema = z.object({
  itemId: z.string().min(1)
});
