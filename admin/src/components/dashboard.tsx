'use client';

import { FormEvent, useCallback, useEffect, useMemo, useState } from 'react';

type Summary = {
  metrics: { users: number; activeRooms: number; matches: number; coinTransactions: number };
  shopItems: Array<{ id: string; name: string; category: string; price: number; is_enabled?: boolean }>;
  events: Array<{ id: string; name: string; status: string; reward_coins?: number }>;
  rooms: Array<{ roomId: string; roomCode: string; gameId: string; status: string; players: number }>;
};

const fallback: Summary = {
  metrics: { users: 0, activeRooms: 0, matches: 0, coinTransactions: 0 },
  shopItems: [],
  events: [],
  rooms: [],
};

const DEFAULT_API = 'https://zornor.onrender.com';

export default function Dashboard() {
  const [data, setData] = useState<Summary>(fallback);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [token, setToken] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const apiUrl = useMemo(
    () => (process.env.NEXT_PUBLIC_API_BASE_URL || DEFAULT_API).replace(/\/+$/, ''),
    []
  );

  const loadDashboard = useCallback(
    async (sessionToken: string) => {
      setLoading(true);
      setError('');
      try {
        const response = await fetch(`${apiUrl}/admin/summary`, {
          headers: { Authorization: `Bearer ${sessionToken}` },
          cache: 'no-store',
        });
        const payload = await response.json().catch(() => ({}));
        if (!response.ok) {
          throw new Error(payload?.message || `HTTP ${response.status}`);
        }
        setData(payload as Summary);
        setToken(sessionToken);
        sessionStorage.setItem('zynora_admin_token', sessionToken);
      } catch (e) {
        sessionStorage.removeItem('zynora_admin_token');
        setToken('');
        setError(e instanceof Error ? e.message : 'تعذر تحميل لوحة الإدارة.');
      } finally {
        setLoading(false);
      }
    },
    [apiUrl]
  );

  useEffect(() => {
    const stored = sessionStorage.getItem('zynora_admin_token');
    if (stored) {
      void loadDashboard(stored);
    }
  }, [loadDashboard]);

  async function login(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setError('');
    try {
      const response = await fetch(`${apiUrl}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: email.trim(), password }),
      });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(payload?.message || `HTTP ${response.status}`);
      if (payload?.user?.role !== 'admin' || !payload?.token) {
        throw new Error('الحساب لا يملك صلاحية إدارة ZYNORA.');
      }
      await loadDashboard(payload.token as string);
      setPassword('');
    } catch (e) {
      setError(e instanceof Error ? e.message : 'فشل تسجيل الدخول.');
      setLoading(false);
    }
  }

  function logout() {
    sessionStorage.removeItem('zynora_admin_token');
    setToken('');
    setData(fallback);
    setError('');
  }

  if (!token) {
    return (
      <div className="mx-auto flex min-h-[70vh] w-full max-w-md items-center justify-center">
        <form
          onSubmit={login}
          className="w-full rounded-[32px] border border-white/10 bg-slate-950/60 p-7 shadow-2xl backdrop-blur-xl"
        >
          <div className="mb-6 text-center">
            <div className="mx-auto mb-4 grid h-16 w-16 place-items-center rounded-2xl bg-gradient-to-br from-violet-500 via-cyan-400 to-amber-400 text-2xl font-black">
              Z
            </div>
            <div className="text-xs font-bold uppercase tracking-[0.32em] text-cyan-200">ZYNORA GAMES</div>
            <h1 className="mt-2 text-3xl font-black">لوحة الإدارة</h1>
            <p className="mt-2 text-sm text-white/60">سجّل بحساب Admin الحقيقي للوصول إلى البيانات.</p>
          </div>

          <label className="mb-2 block text-sm text-white/70">البريد الإلكتروني</label>
          <input
            className="mb-4 w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 outline-none ring-cyan-400/50 focus:ring-2"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            type="email"
            autoComplete="username"
            required
          />

          <label className="mb-2 block text-sm text-white/70">كلمة المرور</label>
          <input
            className="mb-4 w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 outline-none ring-cyan-400/50 focus:ring-2"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            type="password"
            autoComplete="current-password"
            required
          />

          {error ? (
            <div className="mb-4 rounded-2xl border border-rose-400/20 bg-rose-500/10 p-3 text-sm text-rose-100">
              {error}
            </div>
          ) : null}

          <button
            disabled={loading}
            className="w-full rounded-2xl bg-gradient-to-r from-violet-500 via-cyan-500 to-amber-400 px-4 py-3 font-bold text-white transition hover:scale-[1.01] disabled:cursor-wait disabled:opacity-60"
          >
            {loading ? 'جاري الدخول...' : 'دخول لوحة الإدارة'}
          </button>
        </form>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <section className="rounded-[28px] border border-white/10 bg-white/8 p-6 shadow-2xl backdrop-blur">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <p className="text-sm uppercase tracking-[0.35em] text-cyan-200/80">ZYNORA Games</p>
            <h1 className="mt-2 text-4xl font-black">لوحة تحكم الإدارة</h1>
            <p className="mt-3 max-w-2xl text-white/70">إدارة المستخدمين، الغرف، المباريات، المتجر والأحداث من لوحة واحدة.</p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <span className="rounded-full border border-emerald-300/20 bg-emerald-400/10 px-4 py-2 text-xs font-semibold text-emerald-100">
              متصل
            </span>
            <button
              onClick={() => loadDashboard(token)}
              className="rounded-2xl border border-white/10 bg-white/5 px-4 py-2 text-sm font-semibold hover:bg-white/10"
            >
              تحديث
            </button>
            <button
              onClick={logout}
              className="rounded-2xl border border-rose-300/20 bg-rose-500/10 px-4 py-2 text-sm font-semibold text-rose-100 hover:bg-rose-500/20"
            >
              خروج
            </button>
          </div>
        </div>
      </section>

      {error ? (
        <div className="rounded-3xl border border-rose-400/30 bg-rose-500/10 p-4 text-rose-100">
          تعذر تحديث بيانات الإدارة: {error}
        </div>
      ) : null}

      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {[
          ['المستخدمون', data.metrics.users],
          ['الغرف النشطة', data.metrics.activeRooms],
          ['المباريات', data.metrics.matches],
          ['معاملات العملات', data.metrics.coinTransactions],
        ].map(([label, value]) => (
          <div key={String(label)} className="rounded-[24px] border border-white/10 bg-slate-950/45 p-5">
            <div className="text-sm text-white/60">{label}</div>
            <div className="mt-3 text-3xl font-black">{String(value)}</div>
          </div>
        ))}
      </section>

      <section className="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]">
        <div className="rounded-[28px] border border-white/10 bg-slate-950/45 p-6">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-2xl font-bold">الغرف المباشرة</h2>
            <span className="text-sm text-white/60">ملخص اللعب الجماعي</span>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-right text-sm">
              <thead className="text-white/50">
                <tr>
                  <th className="pb-3">الكود</th>
                  <th className="pb-3">اللعبة</th>
                  <th className="pb-3">الحالة</th>
                  <th className="pb-3">اللاعبون</th>
                </tr>
              </thead>
              <tbody>
                {data.rooms.length === 0 ? (
                  <tr><td className="py-6 text-white/50" colSpan={4}>لا توجد غرف حاليًا</td></tr>
                ) : data.rooms.map((room) => (
                  <tr key={room.roomId} className="border-t border-white/6">
                    <td className="py-3 font-semibold">{room.roomCode}</td>
                    <td className="py-3 uppercase">{room.gameId}</td>
                    <td className="py-3">{room.status}</td>
                    <td className="py-3">{room.players}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <div className="space-y-6">
          <div className="rounded-[28px] border border-white/10 bg-slate-950/45 p-6">
            <h2 className="text-2xl font-bold">الأحداث</h2>
            <div className="mt-4 space-y-3">
              {data.events.slice(0, 5).map((event) => (
                <div key={event.id} className="rounded-2xl border border-white/8 bg-white/5 p-4">
                  <div className="font-bold">{event.name}</div>
                  <div className="mt-1 text-sm text-white/60">{event.status}</div>
                </div>
              ))}
              {data.events.length === 0 ? <div className="text-white/50">لا توجد أحداث</div> : null}
            </div>
          </div>

          <div className="rounded-[28px] border border-white/10 bg-slate-950/45 p-6">
            <h2 className="text-2xl font-bold">المتجر</h2>
            <div className="mt-4 grid gap-3">
              {data.shopItems.slice(0, 6).map((item) => (
                <div key={item.id} className="flex items-center justify-between rounded-2xl border border-white/8 bg-white/5 p-4">
                  <div>
                    <div className="font-bold">{item.name}</div>
                    <div className="text-sm text-white/60">{item.category}</div>
                  </div>
                  <div className="text-lg font-black">{item.price} 🪙</div>
                </div>
              ))}
              {data.shopItems.length === 0 ? <div className="text-white/50">لا توجد عناصر</div> : null}
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
