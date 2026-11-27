# Chen Guang Mobile

Customer app for Chen Guang subscribers. The Android display name is Chen Guang.

## Stack

- Flutter 3.24+ / Dart 3.5+
- Riverpod, go_router, easy_localization (English, Myanmar, Chinese)
- Dio and flutter_secure_storage
- Material 3. Primary `#0100CA`, page background `#EDF1F7`
- Bundled fonts: Plus Jakarta Sans, Noto Sans Myanmar, Noto Sans SC

## Setup

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://your-api.example.com/api
```

`APP_ENV` defaults to `dev`. A dev build uses `DEV_API_BASE_URL` when `API_BASE_URL` is omitted. Any other environment must set `API_BASE_URL`.

## App flow

1. Splash checks the saved session.
2. Onboarding, phone login, OTP, then username and password when the account is new.
3. Home, Packages, Inbox, Support, and Profile sit on the bottom bar.

From Home the subscriber can pay a bill, top up, open service history, and send installation, complaint, relocation, change-plan, and Wi-Fi requests. Support opens the chat.

## Structure

```
lib/
├── main.dart
├── core/         # network, storage, router, theme
├── components/   # shared widgets
├── data/         # API repositories
├── models/
└── pages/        # screens and their controllers
```

- Screen: `*_page.dart`
- Screen logic: `*_controller.dart`
- API access: `lib/data/**/*_repository.dart`

## Design reference

[CG-NT Figma](https://www.figma.com/design/11hEAsRtr3TPOtvhsnIPQJ/CG-NT?node-id=0-1)
