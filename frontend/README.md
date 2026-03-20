# Conceptra — Flutter Frontend

The Conceptra Flutter frontend provides a cross-platform (web, Android, iOS) interactive learning experience. Students adjust simulation parameters via sliders and observe real-time animated results, live graphs, and step-by-step explanations.

## Tech Stack

- **Flutter 3.x** (stable channel) — Cross-platform UI framework
- **Riverpod** — State management and dependency injection
- **Dio** — HTTP client with interceptors (auth, retry, error handling)
- **Hive** — Offline-first local storage and caching
- **fl_chart** — Chart rendering for simulation graphs
- **go_router** — Declarative routing with deep linking

## Project Structure

```
lib/
├── core/              # Theme, router, env config, constants
├── features/
│   ├── auth/          # Authentication (Supabase)
│   ├── modules/       # Module list, detail, cards, providers
│   ├── simulations/   # Interactive simulation screen
│   └── dashboard/     # Student progress dashboard
├── shared/            # Shared widgets, services, API client
└── main.dart          # App entry point
```

## Quick Start

### Prerequisites

- Flutter SDK 3.x (stable channel)
- `flutter doctor` shows no critical issues

### Running Locally (Standalone)

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

### Running with Docker (Recommended)

From the project root:

```bash
docker-compose up --build
```

This starts the full stack (PostgreSQL, Redis, Backend, Frontend) and serves the app at **http://localhost:3000**.

### Environment Configuration

The API base URL is configured via `lib/shared/services/env.dart`. During Docker builds, it is set automatically via `--dart-define=API_BASE_URL=/api/v1`.

## Building for Production

```bash
flutter build web --release --dart-define=API_BASE_URL=/api/v1
```

The production build output is in `build/web/` and can be served by any static file server (Nginx, Vercel, Netlify).
