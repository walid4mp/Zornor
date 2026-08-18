# Contributing to ZYNORA

## Development
- Mobile: Flutter/Dart in `mobile/`
- Backend: Node.js/TypeScript in `backend/`
- Admin: Next.js in `admin/`

## Checks
```bash
cd backend && npm ci && npm run build && npm test
cd ../mobile && flutter pub get && flutter analyze && flutter test
```

Do not commit secrets or generated build artifacts.
