# 🐾 Golden Paw — Dogecoin Faucet & Pet Ecosystem

> Earn DOGE, stake in The Vault, grow your Shiba Inu companion, and watch the Golden Paw ecosystem reward you every step of the way.

---

## 🗂️ Project Structure

```
gp-vault-main/
├── lib/                         # Flutter frontend
│   ├── main.dart                # App entry point, GoRouter, providers
│   ├── api_constants.dart       # Backend base URL
│   ├── screens/                 # Page-level screens
│   │   ├── account/             # Account sub-screens
│   │   ├── admin/               # Admin dashboard tabs
│   │   ├── ads/                 # Ad Hub dialogs & sub-screens
│   │   └── faucet/              # Faucet sub-screens
│   ├── widgets/                 # Reusable UI components
│   │   └── pet/                 # Pet-specific widgets
│   │       ├── pet_sprite_widget.dart
│   │       ├── speech_bubble_widget.dart
│   │       ├── poo_layer_widget.dart
│   │       └── pet_tabs_widget.dart
│   ├── src/                     # Firebase, theme & service wrappers
│   └── utils/                   # Shared utilities (pet_events, etc.)
├── backend/                     # Node.js Express API (deployed on Render)
│   ├── server.js                # Express entry point
│   └── src/
│       ├── routes/              # Route handlers (faucet, pet, chat, etc.)
│       └── services/            # Business logic (ai chat, etc.)
├── assets/                      # App images (pet sprites, backgrounds)
├── firestore.rules              # Firestore security rules
├── firebase.json                # Firebase Hosting config
└── pubspec.yaml                 # Flutter dependencies
```

---

## 🚀 Quick Start

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.11.5`
- [Node.js](https://nodejs.org/) `26.x` (backend)
- A Firebase project with Firestore, Auth, and Firebase Messaging enabled
- A Render account (or any Node host) for the backend

### 1. Flutter Frontend

```bash
# Clone the repo
git clone https://github.com/your-org/gp-vault-main.git
cd gp-vault-main

# Install Flutter dependencies
flutter pub get

# Run in Chrome (web)
flutter run -d chrome

# Build for production
flutter build web --release
```

### 2. Backend (Node.js / Express)

```bash
cd backend
npm install

# Create a .env file with the following keys:
# FIREBASE_SERVICE_ACCOUNT=<base64-encoded service account JSON>
# Any other secrets your routes need

npm start
```

The backend will start on the port defined in your environment (defaults to `3000`).

### 3. Firebase

- Deploy Firestore rules: `firebase deploy --only firestore:rules`
- Deploy to Firebase Hosting: `firebase deploy --only hosting`

---

## 🏗️ Architecture

```
Browser / Mobile
      │
      ▼
Flutter Web App  ──────────────────────────────────────────────────────┐
  GoRouter (routing)                                                    │
  Provider (ThemeProvider)                                              │
  Firebase Auth (client-side login/signup)                              │
  Cloud Firestore (real-time reads: chat, balances, pet state)          │
      │                                                                 │
      │  POST /api/*  (auth token in headers)                           │
      ▼                                                                 │
Node.js Express Backend (Render)                                        │
  Firebase Admin SDK (bypasses Firestore rules for writes)              │
  node-cron (scheduled jobs: stat decay, matured returns)               │
  express-rate-limit (spam protection)                                  │
      │                                                                 │
      ▼                                                                 │
Firestore Database ◄──────────────────────────────────────────────────┘
```

---

## 🔐 Security Notes

- All balance mutations happen **server-side** via Firebase Admin SDK — clients cannot directly modify balances, XP, or roles in Firestore.
- The `/send-doge` (faucet) endpoint is rate-limited to prevent bot abuse.
- Firestore rules block direct writes to `chat_messages` and all sensitive `users` fields.

---

## 🧪 CI / CD

Every push and pull request triggers the GitHub Actions workflow (`.github/workflows/ci.yml`) which:
1. Runs `flutter analyze` (zero-tolerance for issues)
2. Runs `flutter test`
3. Runs `npm audit` on the backend dependencies

---

## 📦 Key Dependencies

| Package | Purpose |
|--------|---------|
| `go_router` | Declarative client-side routing |
| `provider` | Theme state management |
| `firebase_core` / `firebase_auth` | Authentication |
| `cloud_firestore` | Real-time database reads |
| `firebase_messaging` | Push notifications |
| `firebase_app_check` | Bot / abuse protection |
| `shared_preferences` | Local persistence (sleep state, etc.) |
| `geolocator` | Pet walk distance tracking |
| `flutter_markdown` | Rendering blog / update posts |
| `express-rate-limit` | Backend API rate limiting |
| `node-cron` | Scheduled pet stat decay & reward processing |

---

## 🤝 Contributing

1. Follow the modularization pattern: large widget files (>400 LOC) should be broken into sub-widgets under a named subdirectory (e.g., `lib/widgets/pet/`).
2. All changes must pass `flutter analyze` with zero issues.
3. Write a widget test for any new screen or significant widget you add.
4. Keep the backend routes thin — business logic belongs in `backend/src/services/`.

---

*Golden Paw — Earn, grow, and play with your Shiba Inu companion. 🐾*
