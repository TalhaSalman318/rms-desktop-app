# rms_desktop_app

A Flutter restaurant management and POS application with a Node.js/Express and
MongoDB backend.

## Backend setup

Copy `backend/.env.example` to `backend/.env` and set `MONGODB_URI`. When using
an empty database, also set `INITIAL_ADMIN_PASSWORD` to a unique password of at
least 12 characters. `INITIAL_ADMIN_USERNAME` defaults to `admin`. Do not commit
`backend/.env` or share its contents.

Run the API from the `backend` directory with `npm start`. All API routes except
health checks and login require an authenticated session. Passwords are stored
using scrypt. Existing accounts with legacy SHA-256 hashes are upgraded
automatically after a successful sign-in. New passwords must contain at least
12 characters. Change the admin password from Settings.

## Login sessions

The app stores only its session token, never the admin password. On Windows the
token is encrypted with the current user's DPAPI key before it is persisted;
other platforms use SharedPreferences. A valid session is restored after
restarting the app. Signing out revokes the server session; sessions expire
after 30 days. Configure `API_BASE_URL` with HTTPS when connecting to a backend
outside the local machine.

No customer or staff accounts are supported.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
