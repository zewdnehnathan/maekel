# Maekel

Addis Ababa super-app shell (Flutter) — auth, home hub, and stubs for Ride, Market, Food, and Games.

## Run

```bash
# Ensure Flutter is on PATH (SDK often at %USERPROFILE%\flutter\bin)
flutter pub get
flutter run
```

## Mock login

1. Enter a 9-digit local phone (e.g. `911234567`) — prefix `+251`
2. OTP: `123456`

## Routes

| Path | Screen |
|------|--------|
| `/auth` | Phone sign-in |
| `/auth/otp` | Mock OTP |
| `/home` | Hub |
| `/ride`, `/ride/driver` | Ride stubs |
| `/market`, `/market/sell` | Market stubs |
| `/food` | Food stub |
| `/games`, `/games/brick-breaker`, `/games/tetris` | Games stubs |
