# CG Net Mobile

Customer-facing ISP mobile app scaffold (Flutter).

## Stack

- Flutter 3.24+ / Dart 3.5+
- Riverpod, go_router, easy_localization (EN / MY / ZH)
- Dio, flutter_secure_storage, Lottie, shimmer
- Material 3 — primary `#0100CA`, primary light `#EBEBFB`, accent `#FFEE13`, surfaces `#EDF3F8`

## Setup

```bash
# Requires Flutter SDK on PATH
flutter create . --project-name cg_net_mobile
flutter pub get
flutter run
```

Optional API base URL:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api.example.com
```

## App flow

1. Language selection (EN / MY / ZH) → saved in local prefs (`my` = Myanmar)  
2. Splash (token check) → Onboarding → Login (phone, MM/TH/CN) → OTP → success (Lottie) → set username/password → Home  
3. Bottom nav: Home · Package · Inbox · Support · Profile  

Billing / payment / plan-change are deferred.

## Structure

```
lib/
├── main.dart
├── core/           # network, storage, router, theme, utils
├── components/     # app-wide widgets
├── models/
└── pages/          # feature screens (+ controller / repository / local components)
```

- Screen: `*_page.dart`
- Logic: `*_controller.dart` (Riverpod)
- Feature API: `*_repository.dart` inside that page folder

## Mock data

Package list loads `assets/mock/packages.json`. Real endpoint (commented, ready to enable):

`GET /v1/customer/plans/available`

## Design reference

[CG-NT Figma](https://www.figma.com/design/11hEAsRtr3TPOtvhsnIPQJ/CG-NT?node-id=0-1)
