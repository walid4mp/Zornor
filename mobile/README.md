# ZYNORA Android App

Flutter client for ZYNORA Games.

## Requirements

- Flutter stable
- Android SDK
- Java 17

## Run

```bash
flutter pub get
flutter run --dart-define=APP_ENV=development
```

## Production APK

```bash
flutter clean
flutter pub get
flutter build apk --release   --dart-define=ZYNORA_API_BASE_URL=https://zornor.onrender.com   --dart-define=ZYNORA_SOCKET_URL=https://zornor.onrender.com   --dart-define=APP_ENV=production
```

Output:

`build/app/outputs/flutter-apk/app-release.apk`

## Notes

- Production traffic uses HTTPS.
- Development emulator HTTP uses Android debug cleartext support.
- Do not commit secrets.
