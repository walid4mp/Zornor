import fs from 'fs';
import path from 'path';
import { Pool, type QueryResultRow } from 'pg';
import { env, isProd } from '../config/env';

function buildConnection(): Pool {
  const connectionString = env.DATABASE_URL;
  if (!connectionString) {
    throw new Error('DATABASE_URL is not configured. Set DATABASE_URL in the production environment.');
  }
  if (isProd && /(localhost|127\.0\.0\.1|::1)/i.test(connectionString)) {
    throw new Error('DATABASE_URL points to localhost in production. Use the Render Postgres connection string instead.');
  }

  return new Pool({
    connectionString,
    ssl: isProd ? { rejectUnauthorized: false } : false,
    max: 10,
    min: 1,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 10000,
    application_name: 'zynora-backend'
  });
}

function resolveSchemaPath(): string {
  const candidates = [
    path.resolve(process.cwd(), 'sql/schema.sql'),
    path.resolve(__dirname, '../../sql/schema.sql'),
    path.resolve(__dirname, '../sql/schema.sql')
  ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return candidate;
  }

  throw new Error(`Schema file not found. Checked: ${candidates.join(', ')}`);
}

export const pool = buildConnection();

let initialized = false;
let initPromise: Promise<void> | null = null;

pool.on('error', (err) => {
  console.error('Unhandled Postgres pool error:', err.message);
});

async function runInit(retries = 5, delayMs = 3000): Promise<void> {
  const schemaPath = resolveSchemaPath();
  const schema = fs.readFileSync(schemaPath, 'utf8');

  for (let attempt = 1; attempt <= retries; attempt += 1) {
    try {
      await pool.query('SELECT 1');
      await pool.query(schema);
      initialized = true;
      console.log(`ZYNORA Backend db: schema ready from ${schemaPath}`);
      return;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.warn(`Database init attempt ${attempt}/${retries} failed: ${message}`);
      if (attempt === retries) {
        throw new Error(`Database initialization failed after ${retries} attempts: ${message}`);
      }
      await new Promise((resolve) => setTimeout(resolve, delayMs * attempt));
    }
  }
}

export async function initDatabase(retries = 5, delayMs = 3000): Promise<void> {
  if (initialized) return;
  if (!initPromise) {
    initPromise = runInit(retries, delayMs).finally(() => {
      initPromise = null;
    });
  }
  await initPromise;
}

export async function ensureDatabaseInitialized(): Promise<boolean> {
  if (initialized) return true;
  try {
    await initDatabase();
    return initialized;
  } catch (error) {
    console.error('Database initialization error:', error instanceof Error ? error.message : error);
    return false;
  }
}

export async function query<T extends QueryResultRow>(text: string, params?: unknown[]) {
  const ready = await ensureDatabaseInitialized();
  if (!ready) {
    throw new Error('Database is not ready');
  }
  return pool.query<T>(text, params);
}

export async function databaseReady(): Promise<boolean> {
  if (!initialized) {
    if (!initPromise) {
      void ensureDatabaseInitialized();
    }
    return false;
  }
  try {
    await pool.query('SELECT 1');
    return true;
  } catch {
    return false;
  }
}
