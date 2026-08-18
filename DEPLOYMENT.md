# ZYNORA deployment

## Render
Production backend URL: `https://zornor.onrender.com`

The Render service should use the repository root with `render.yaml`, which provisions:
- Node backend under `backend/`
- PostgreSQL database `Zornor`
- generated `JWT_SECRET`
- production port `10000`

### Required admin variables
Set these in the Render service Environment tab:
- `ADMIN_EMAIL` = your admin email
- `ADMIN_PASSWORD` = a password of **at least 12 characters**
- `ADMIN_NAME` = `ZYNORA Admin`

`ADMIN_PASSWORD` is optional at boot, but if supplied it must be 12+ characters.

### Mobile
The Android build uses only:
- API: `https://zornor.onrender.com`
- Socket.IO: `https://zornor.onrender.com`

No legacy `tikboost-full-2.onrender.com` endpoint is used.

## GitHub Actions
The workflow runs:
1. `flutter pub get`
2. backend `npm ci`, build and tests
3. `flutter analyze`
4. Flutter tests
5. release APK build

A Flutter analyzer `info` is not allowed to fail the job; actual analyzer errors remain fatal.

## Admin production credentials

Render now generates `ADMIN_PASSWORD` automatically from `render.yaml`. Set `ADMIN_EMAIL` manually in the Render environment to the administrator email you want to use. If an older deployment still has a short `ADMIN_PASSWORD`, remove that old value and redeploy so the generated secret is used.

The production backend keeps the password validation at 12+ characters and does not weaken it for deployment convenience.
