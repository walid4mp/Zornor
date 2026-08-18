import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const inProduction = process.env.NODE_ENV === 'production';

const schema = z.object({
  PORT: z.coerce.number().default(inProduction ? 10000 : 3000),
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  APP_ORIGIN: z.string().default('*'),
  ADMIN_ORIGIN: z.string().default('*'),
  DATABASE_URL: inProduction
    ? z.string({ required_error: 'DATABASE_URL is required in production' }).min(8)
    : z.string().default('postgres://postgres:postgres@localhost:5432/zynora'),
  JWT_SECRET: inProduction
    ? z.string({ required_error: 'JWT_SECRET is required in production' }).min(16)
    : z.string().default('change-me-in-production'),
  ADMIN_EMAIL: z.string().email().optional(),
  ADMIN_PASSWORD: z.preprocess(
    (value) => value === '' ? undefined : value,
    z.string().min(12, 'ADMIN_PASSWORD must contain at least 12 characters').optional()
  ),
  ADMIN_NAME: z.string().default('ZYNORA Admin')
});

export const env = schema.parse(process.env);
export const isProd = env.NODE_ENV === 'production';
