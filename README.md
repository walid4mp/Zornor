# ZYNORA Games

**Play. Connect. Win.**

منصة ألعاب اجتماعية متعددة اللاعبين تعمل على Android، وتجمع Ludo وChess وDomino في تطبيق واحد مع حسابات، أصدقاء، غرف، دردشة، Coins، XP، متجر، إعلانات ولوحة إدارة.

## Architecture

- `mobile/` — Flutter Android application
- `backend/` — Node.js + TypeScript + Express + Socket.IO
- `admin/` — Next.js administration dashboard
- PostgreSQL — persistent data
- Render — production backend deployment
- GitHub Actions — automated Android APK build

## Games

- Ludo — 2–4 players
- Chess — 2 players
- Domino — 2–4 players

## Local backend

```bash
cd backend
cp .env.example .env
npm ci
npm run build
npm test
npm start
```

## Local mobile

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=APP_ENV=development
```

Production API is injected at build time:

```bash
flutter build apk --release   --dart-define=ZYNORA_API_BASE_URL=https://zornor.onrender.com   --dart-define=ZYNORA_SOCKET_URL=https://zornor.onrender.com   --dart-define=APP_ENV=production
```

## Render

The `render.yaml` file configures:

- Node web service
- `backend` as root directory
- `npm ci && npm run build`
- `npm start`
- `/health`
- PostgreSQL
- `DATABASE_URL`
- generated `JWT_SECRET`

Do not commit production secrets.

## GitHub Actions

`.github/workflows/build.yml` validates the backend, analyzes/tests Flutter, builds a release APK, and uploads the APK artifact.

## Security

See `SECURITY.md`.

## Status

This repository contains the mobile app, backend, admin dashboard, Android launcher assets, game engines and deployment configuration.
