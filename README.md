# habesha_tax_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Environment variables and secrets

This app reads config values from a real `.env` file at runtime using `flutter_dotenv` in `main.dart` and `FrappeConfig`.

### 1) Create local `.env` (not committed)

Copy [assets/env/.env.example](assets/env/.env.example) to [assets/env/.env](assets/env/.env) and fill values:

- `FRAPPE_BASE_URL`
- `FRAPPE_API_KEY`
- `FRAPPE_API_SECRET`

`assets/env/.env` is ignored by git via [.gitignore](.gitignore).

### 2) Run/build normally

No special flag is required:

- `flutter run`
- `flutter build apk`
- `flutter build ios`

### 3) Important security note

Do **not** ship real private secrets in a client app. Mobile/web apps can be reverse engineered.

Use a backend/proxy for operations that require `apiSecret`, and keep that secret server-side only.
