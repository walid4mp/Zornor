# ZYNORA Security

- Never commit `.env`, passwords, JWT secrets, Render API keys, GitHub PATs, or private keys.
- Production uses `DATABASE_URL` and `JWT_SECRET` from Render Environment Variables.
- Do not use localhost database URLs in production.
- Rotate any credential that has been exposed.
- Admin APIs are protected by role-based authorization.
- Game results, Coins and XP must be validated server-side.
