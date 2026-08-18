# ZYNORA production hardening — uploaded source update

This package was reviewed and updated from the supplied `Zornor-main.zip`.

## Included
- Flutter Android app under `mobile/`
- Node.js/TypeScript backend under `backend/`
- Next.js admin dashboard under `admin/`
- Render configuration
- GitHub Actions workflows
- Android launcher assets

## Important fixes
- Replaced the invalid 59-byte brand PNG placeholder with a valid ZYNORA PNG asset.
- Reworked Flutter startup preferences/AdMob initialization so AdMob failures do not crash the app.
- Added global Flutter error guards and safer startup recovery.
- Removed demo credentials from the login screen.
- Added form validation and safer API JSON decoding.
- Added socket reconnect/error feedback and a local leave-room action.
- Removed the development-only Ludo "Force 6" action.
- Improved room-start logic so multiplayer rooms can start once two players are present.
- Prevented game actions before a match starts or after it finishes.
- Scoped notifications to the authenticated user.
- Added database indexes for common multiplayer/social queries.
- Added backend/mobile environment examples.
- Added `SECURITY.md` and `CONTRIBUTING.md`.
- Improved admin dashboard authentication so an admin JWT is not exposed through `NEXT_PUBLIC_*`.
- Simplified the authoritative APK workflow to produce a single `app-release.apk`.
- Changed the secondary Android workflow to manual-only to avoid duplicate builds.
- Added a production README and mobile README.
- Disabled Android cleartext traffic in release; kept it only for debug development.
- Added CI verification that the Flutter project and backend build are present.

## Verification performed in this environment
- JSON/YAML configuration parsing: passed.
- Repository audit found no hardcoded demo login, no Ludo "Force 6", no `NEXT_PUBLIC_ADMIN_TOKEN`, and no old `moduleResolution: node/node10` setting.
- Brand PNG is a valid 512x512 PNG.

## Not executed here
The container used for this edit does not have Flutter installed, and package installation/build execution was not completed here. Run GitHub Actions for the authoritative Flutter/Android build and Render for the production deployment verification.

## ZYNORA Social & Economy Expansion
- Added tournaments, events/offers, virtual coin economy ledger and match earnings statistics.
- Added gifts with tiered virtual prices, live rooms, live-room gifting and voice-room APIs.
- Added community mobile hub with events, tournaments, live, voice and economy tabs.
- Added in-game click/chat feedback using platform system sound.
- Added Socket.IO voice-room signaling events for future WebRTC media clients.
- Added admin endpoints for community management.
- All competitive economy values are virtual ZYNORA Coins; no cash-out or real-money gambling is implemented.
