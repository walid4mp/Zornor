import express, { type NextFunction, type Request, type Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import morgan from 'morgan';
import { env } from './config/env';
import { ensureDatabaseInitialized, databaseReady, pool } from './lib/db';
import { authRouter } from './routes/auth';
import { gamesRouter } from './routes/games';
import { roomsRouter } from './routes/rooms';
import { socialRouter } from './routes/social';
import { walletRouter } from './routes/wallet';
import { adminRouter } from './routes/admin';
import { communityRouter } from './routes/community';
import { hashPassword } from './lib/auth';

function parseOrigins(): string[] {
  const raw = [env.APP_ORIGIN, env.ADMIN_ORIGIN]
    .flatMap((value) => value.split(','))
    .map((value) => value.trim())
    .filter(Boolean);
  return Array.from(new Set(raw));
}

function allowAnyOrigin(origins: string[]): boolean {
  return origins.includes('*');
}

async function safeInitialize(): Promise<boolean> {
  try {
    return await ensureDatabaseInitialized();
  } catch (error) {
    console.error('Database initialization will be retried lazily:', error instanceof Error ? error.message : error);
    return false;
  }
}

async function queryAdmin(email: string) { const r = await pool.query('SELECT role FROM users WHERE email=$1',[email]); return r.rows[0]?.role ?? null; }

export async function createApp() {
  console.log('ZYNORA Backend starting...');
  console.log(`Environment: ${env.NODE_ENV}`);
  console.log(`Port: ${env.PORT}`);
  console.log(`Database: ${env.DATABASE_URL ? 'configured' : 'missing'}`);
  console.log(`JWT secret: ${env.JWT_SECRET ? 'configured' : 'missing'}`);
  void safeInitialize().then(async ready => { if (ready && env.ADMIN_EMAIL && env.ADMIN_PASSWORD && (await queryAdmin(env.ADMIN_EMAIL)) === null) { const hash=await hashPassword(env.ADMIN_PASSWORD); await pool.query(`INSERT INTO users(email,username,password_hash,role) VALUES($1,$2,$3,'admin') ON CONFLICT(email) DO NOTHING`,[env.ADMIN_EMAIL,env.ADMIN_NAME.replace(/\s+/g,'_').toLowerCase(),hash]); } }).catch(e=>console.error('Admin bootstrap failed:',e));

  const app = express();
  const allowedOrigins = parseOrigins();
  const wildcard = allowAnyOrigin(allowedOrigins);

  app.set('trust proxy', 1);
  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
      contentSecurityPolicy: false
    })
  );
  app.use(
    cors({
      origin: (origin, callback) => {
        if (!origin || wildcard || allowedOrigins.includes(origin)) {
          return callback(null, true);
        }
        return callback(new Error(`Origin not allowed by CORS: ${origin}`));
      },
      credentials: !wildcard
    })
  );
  app.use(express.json({ limit: '1mb' }));
  app.use(morgan('dev'));
  app.use(
    rateLimit({
      windowMs: 60 * 1000,
      max: 120,
      standardHeaders: true,
      legacyHeaders: false
    })
  );

  app.get('/', (_req: Request, res: Response) => {
    res.type('html').send(`<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>ZYNORA Admin</title><style>body{margin:0;background:#070b18;color:#fff;font-family:Arial,sans-serif}main{max-width:1100px;margin:40px auto;padding:24px}section{background:#11182b;border:1px solid #26304b;border-radius:22px;padding:22px;margin-bottom:18px}input,button{padding:12px;border-radius:12px;border:1px solid #33405f;background:#0b1020;color:#fff;margin:5px}button{background:#6d5dfc;cursor:pointer}table{width:100%;border-collapse:collapse}td,th{padding:10px;border-bottom:1px solid #25304a;text-align:right}.muted{color:#9aa7c7}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px}.card{background:#0b1020;border-radius:16px;padding:16px}</style></head><body><main><section><h1>🎮 ZYNORA Admin</h1><p class="muted">لوحة تحكم الخادم: المستخدمون، الشحن، الإعلانات والمباريات.</p><input id="email" type="email" placeholder="البريد"><input id="password" type="password" placeholder="كلمة المرور"><button onclick="login()">دخول</button><span id="msg"></span></section><div id="panel" hidden><section><h2>الإحصائيات</h2><div id="metrics" class="cards"></div></section><section><h2>طلبات الشحن</h2><div id="recharges"></div></section><section><h2>الإعلانات</h2><div id="ads"></div></section></div></main><script>
let token='';
async function api(path,opt={}){opt.headers=Object.assign({},opt.headers||{},{Authorization:'Bearer '+token,'Content-Type':'application/json'});const r=await fetch(path,opt);const d=await r.json().catch(()=>({}));if(!r.ok)throw Error(d.message||('HTTP '+r.status));return d}
async function login(){try{const r=await fetch('/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:document.getElementById('email').value,password:document.getElementById('password').value})});const d=await r.json();if(!r.ok||d.user?.role!=='admin')throw Error(d.message||'حساب Admin مطلوب');token=d.token;document.getElementById('panel').hidden=false;document.getElementById('msg').textContent=' تم الدخول';await load()}catch(e){document.getElementById('msg').textContent=' '+e.message}}
async function load(){const d=await api('/admin/summary');document.getElementById('metrics').innerHTML=Object.entries(d.metrics).map(x=>'<div class="card"><b>'+x[0]+'</b><div>'+x[1]+'</div></div>').join('');document.getElementById('ads').innerHTML=d.ads.map(a=>'<div class="card">'+a.name+' — '+(a.enabled?'مفعّل':'متوقف')+' <button onclick="toggleAd(\''+a.id+'\')">تبديل</button></div>').join('');const r=await api('/admin/recharges');document.getElementById('recharges').innerHTML='<table><tr><th>المستخدم</th><th>الباقة</th><th>العملات</th><th>الحالة</th><th>إجراء</th></tr>'+r.requests.map(x=>'<tr><td>'+x.username+'</td><td>'+x.package_name+'</td><td>'+x.coins+'</td><td>'+x.status+'</td><td>'+(x.status==='pending'?'<button onclick="approve(\''+x.id+'\')">موافقة</button><button onclick="rejectReq(\''+x.id+'\')">رفض</button>':'')+'</td></tr>').join('')+'</table>'}
async function approve(id){await api('/admin/recharges/'+id+'/approve',{method:'POST'});load()} async function rejectReq(id){await api('/admin/recharges/'+id+'/reject',{method:'POST'});load()} async function toggleAd(id){await api('/admin/ads/'+id+'/toggle',{method:'POST'});load()}
</script></body></html>`);
  });

  app.get('/health', async (_req: Request, res: Response) => {
    const dbOk = await databaseReady();
    res.status(200).json({
      status: dbOk ? 'ok' : 'starting',
      service: 'zynora-backend',
      slogan: 'Play. Connect. Win.',
      database: dbOk ? 'connected' : 'initializing',
      uptimeSeconds: Math.round(process.uptime())
    });
  });

  app.use('/auth', authRouter);
  app.use('/wallet', walletRouter);
  app.use('/admin', adminRouter);
  app.use('/community', communityRouter);
  app.use('/games', gamesRouter);
  app.use('/rooms', roomsRouter);
  app.use('/', socialRouter);

  app.use((req, res) => {
    res.status(404).json({ message: `Route ${req.originalUrl} not found` });
  });

  app.use((error: unknown, _req: Request, res: Response, _next: NextFunction) => {
    const message = error instanceof Error ? error.message : 'Internal error';
    if (message.toLowerCase().includes('database') || message.toLowerCase().includes('connection')) {
      res.status(503).json({ message: 'Service temporarily unavailable' });
    } else if (message.toLowerCase().includes('cors')) {
      res.status(403).json({ message: 'Origin is not allowed' });
    } else {
      res.status(500).json({ message });
    }
  });

  pool.on('error', (err) => {
    console.error('Postgres pool error (handled):', err.message);
  });

  return app;
}
