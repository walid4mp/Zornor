import http from 'http';
import { createApp } from './app';
import { env } from './config/env';
import { attachSocket } from './socket';

async function bootstrap() {
  const app = await createApp();
  const server = http.createServer(app);
  attachSocket(server);

  server.keepAliveTimeout = 65000;
  server.headersTimeout = 66000;

  const port = Number(env.PORT) || 10000;
  server.listen(port, '0.0.0.0', () => {
    console.log(`ZYNORA Backend ready on 0.0.0.0:${port}`);
  });

  const shutdown = (signal: string) => {
    console.log(`Received ${signal}, shutting down ZYNORA Backend...`);
    server.close(() => process.exit(0));
    setTimeout(() => process.exit(1), 8000).unref();
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

bootstrap().catch((error) => {
  console.error('Fatal bootstrap error:', error);
  process.exit(1);
});
