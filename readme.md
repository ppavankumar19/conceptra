# 🎓 Conceptra — Interactive Education Visualization System

> "Don't just learn formulas — experience them."

Conceptra is a production-grade, full-stack interactive learning platform designed for students in Classes 6–12. It transforms static textbook formulas into real-time, animated, and visual experiences through slider-driven inputs, live graphs, and intelligent explanations — all powered by a Flutter frontend, a FastAPI Python backend, PostgreSQL, Redis, and Supabase authentication.

---

## 📑 Table of Contents

- [Project Overview](#project-overview)
- [Architecture Overview](#architecture-overview)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
  - [Supabase Configuration](#supabase-configuration)
  - [PostgreSQL Setup](#postgresql-setup)
  - [Redis Setup](#redis-setup)
  - [Python Backend Setup](#python-backend-setup)
  - [Flutter Frontend Setup](#flutter-frontend-setup)
- [Running the Application Locally](#running-the-application-locally)
- [Deployment](#deployment)
- [Security Notes](#security-notes)
- [Testing](#testing)
- [Observability](#observability)
- [Internationalization and Accessibility](#internationalization-and-accessibility)
- [Contributing](#contributing)
- [Roadmap](#roadmap)
- [License](#license)

---

## Project Overview

Conceptra provides an interactive simulation environment where students adjust parameters using sliders and immediately observe how mathematical and physics concepts behave visually. The platform supports role-based access for Students, Teachers, and Administrators, with full offline capability on mobile, real-time synchronization, audit logging, and a comprehensive analytics dashboard.

### Key Capabilities

- **Interactive Simulations** — Slider-driven inputs with real-time computation and animated visual output
- **Live Graphs** — Distance–Time, Speed–Time, Force curves rendered dynamically
- **Step-by-Step Explanations** — Formula breakdowns with contextual reasoning
- **Role-Based Access Control (RBAC)** — Students, Teachers, Admins with scoped permissions
- **Offline Support** — Mobile-first offline data caching and background synchronization
- **Observability** — Structured logging, Prometheus metrics, and distributed tracing
- **Internationalization** — Multi-language support via Flutter's i18n framework
- **Accessibility** — WCAG 2.1 AA compliance across all UI components

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                            │
│   Flutter App (Mobile / Web)                                    │
│   - Riverpod State Management                                   │
│   - Hive Local Cache (Offline)                                  │
│   - flutter_localizations (i18n)                                │
└───────────────────────┬─────────────────────────────────────────┘
                        │ HTTPS / WSS
┌───────────────────────▼─────────────────────────────────────────┐
│                    IDENTITY LAYER                                │
│   Supabase Auth (OAuth 2.0 + JWT)                               │
│   - Google / GitHub OAuth Providers                             │
│   - JWT issued and validated per request                        │
└───────────────────────┬─────────────────────────────────────────┘
                        │ Bearer JWT
┌───────────────────────▼─────────────────────────────────────────┐
│                      API LAYER                                   │
│   FastAPI (Python 3.11+)                                        │
│   - JWT Middleware (Supabase public key validation)             │
│   - RBAC Dependency Injection                                   │
│   - Rate Limiting + CORS                                        │
│   - OpenAPI / Swagger Docs                                      │
└────────┬──────────────────────────────────┬─────────────────────┘
         │                                  │
┌────────▼────────┐                ┌────────▼────────┐
│  Redis Cache    │                │  PostgreSQL DB  │
│  - TTL per API  │                │  - Users        │
│  - Session data │                │  - Simulations  │
│  - Rate limits  │                │  - Audit Logs   │
└─────────────────┘                └─────────────────┘
```

**Architecture Reference Documents:** See `spec.md` for full API surface, data schema, and security model. See `scope.md` for phased milestones and acceptance criteria. See `implementation.md` for step-by-step build and deployment instructions.

---

## Tech Stack

| Layer | Technology | Version | Purpose |
|---|---|---|---|
| Frontend | Flutter | 3.x (stable) | Cross-platform UI, animations, offline |
| Backend | FastAPI (Python) | 0.110+ / Python 3.11+ | REST API, async computation engine |
| Database | PostgreSQL | 15+ | Persistent relational data store |
| Cache | Redis | 7+ | API response caching, rate limiting |
| Auth / Identity | Supabase | Latest (free tier) | OAuth 2.0, JWT, user management |
| State Management | Riverpod | 2.x | Flutter state and dependency injection |
| Local Storage | Hive | 2.x | Offline-first local cache on mobile |
| ORM | SQLAlchemy (async) | 2.x | Python database abstraction layer |
| HTTP Client | Dio | 5.x | Flutter API client with interceptors |
| Testing (Backend) | Pytest | 7.x | Unit and integration test suite |
| Testing (Frontend) | Flutter Test | Built-in | Widget and integration tests |
| Containerization | Docker + Docker Compose | Latest | Local dev and production packaging |
| Orchestration | Kubernetes (optional) | 1.28+ | Production scaling |
| Observability | OpenTelemetry + Prometheus | Latest | Metrics, tracing, logging |
| CI/CD | GitHub Actions | - | Build, test, lint, deploy pipelines |

> **Note:** All services listed above are available on free tiers (Supabase free, Redis free via Upstash or self-hosted, PostgreSQL self-hosted or Supabase free tier, GitHub Actions free tier for public repos).

---

## Repository Structure

```
Conceptra/
├── frontend/                    # Flutter application
│   ├── lib/
│   │   ├── core/                # Theme, router, constants, env
│   │   ├── features/            # Feature modules
│   │   │   ├── auth/
│   │   │   ├── modules/         # Module list, detail, cards
│   │   │   ├── simulations/
│   │   │   └── dashboard/
│   │   ├── shared/              # Shared widgets, services
│   │   └── main.dart
│   ├── test/                    # Widget and integration tests
│   └── pubspec.yaml
│
├── backend/                     # FastAPI application
│   ├── app/
│   │   ├── api/v1/              # Route handlers (auth, modules, simulations, etc.)
│   │   ├── core/                # Config, security, middleware, RBAC
│   │   ├── db/                  # SQLAlchemy models, session
│   │   ├── services/            # Business logic, cache, computation
│   │   ├── schemas/             # Pydantic request/response models
│   │   └── main.py
│   ├── alembic/                 # Database migrations
│   ├── Dockerfile               # Backend Docker image
│   ├── seed_data.py             # Database seed script
│   └── requirements.txt
│
├── infra/                       # Infrastructure as Code
│   ├── docker/
│   │   └── Dockerfile.frontend  # Frontend Docker image (Flutter + Nginx)
│   ├── nginx/
│   │   └── nginx.dev.conf       # Nginx reverse proxy config
│   ├── docker-compose.prod.yml  # Production stack
│   └── docker-compose.yml       # Alternative compose file
│
├── docker-compose.yml           # Main local development stack (at root)
├── .github/
│   └── workflows/               # CI/CD GitHub Actions pipelines
│
├── docs/                        # Architecture diagrams, ADRs
├── readme.md
├── spec.md
├── scope.md
└── implementation.md
```

---

## Prerequisites

Before setting up the project, ensure the following are installed on your machine. All tools listed below are freely available.

| Tool | Minimum Version | Installation |
|---|---|---|
| Flutter SDK | 3.x (stable channel) | flutter.dev/docs/get-started/install |
| Dart SDK | 3.x (bundled with Flutter) | Included with Flutter |
| Python | 3.11+ | python.org |
| pip | 23+ | Bundled with Python |
| Docker Desktop | 24+ | docker.com/get-started |
| Docker Compose | 2.x (bundled with Docker) | Bundled with Docker Desktop |
| Git | 2.40+ | git-scm.com |
| Node.js (optional) | 20 LTS | For Supabase CLI only |
| Supabase CLI (optional) | Latest | supabase.com/docs/guides/cli |

---

## Environment Setup

### Supabase Configuration

Supabase is used exclusively as the identity provider (authentication) on the free tier.

1. Create a free account at [supabase.com](https://supabase.com).
2. Create a new project and note your **Project URL** and **anon/public API key**.
3. Navigate to **Authentication → Providers** and enable your desired OAuth providers (Google, GitHub — both free).
4. Under **Authentication → URL Configuration**, set your redirect URLs:
   - For local development: `http://localhost:3000/auth/callback`
   - For production: `https://yourdomain.com/auth/callback`
5. Navigate to **Settings → API** and copy:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_JWT_SECRET` (used by the backend to validate JWTs)
6. Create a `.env` file in the `backend/` directory using `.env.example` as a template.

### PostgreSQL Setup

**Option A — Docker (recommended for local development):**

Use the provided `docker-compose.yml` which includes a pre-configured PostgreSQL 15 service. No manual installation is required. Start it with the Docker Compose command described in the [Running Locally](#running-the-application-locally) section.

**Option B — Supabase Managed PostgreSQL (free tier):**

Supabase provides a free PostgreSQL instance. Use the connection string from **Settings → Database → Connection string** in your Supabase dashboard. Update `DATABASE_URL` in your `.env` file accordingly.

**Option C — Local Installation:**

Install PostgreSQL 15 from [postgresql.org](https://postgresql.org), create a database named `conceptra`, and a user with appropriate privileges. Update `DATABASE_URL` in `.env`.

**Running Migrations:**

After setting up PostgreSQL, apply database migrations using Alembic from within the `backend/` directory. The migration files are located under `alembic/versions/`.

### Redis Setup

**Option A — Docker (recommended for local development):**

The provided `docker-compose.yml` includes a Redis 7 service. No separate installation is needed.

**Option B — Upstash Redis (free tier for production):**

Create a free Redis database at [upstash.com](https://upstash.com). Copy the connection URL and update `REDIS_URL` in your `.env` file. Upstash offers a free tier with up to 10,000 requests per day, suitable for development and small-scale production.

**Option C — Local Installation:**

Install Redis from [redis.io](https://redis.io/download) and start the server on its default port.

### Python Backend Setup

1. Navigate to the `backend/` directory.
2. Create a Python virtual environment using the `venv` module (no additional tools required).
3. Activate the virtual environment.
4. Install all dependencies from `requirements.txt` using pip.
5. Copy `.env.example` to `.env` and populate all required environment variables.

**Required environment variables:**

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string |
| `REDIS_URL` | Redis connection string |
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_JWT_SECRET` | JWT secret from Supabase dashboard |
| `ALLOWED_ORIGINS` | Comma-separated list of allowed CORS origins |
| `ENVIRONMENT` | `development` or `production` |
| `LOG_LEVEL` | `DEBUG`, `INFO`, `WARNING`, or `ERROR` |

### Flutter Frontend Setup

1. Ensure Flutter SDK is installed and `flutter doctor` reports no critical issues.
2. Navigate to the `frontend/` directory.
3. Run `flutter pub get` to install all declared dependencies.
4. Copy `lib/core/env.example.dart` to `lib/core/env.dart` and populate:
   - `supabaseUrl` — Your Supabase project URL
   - `supabaseAnonKey` — Your Supabase anon/public key
   - `apiBaseUrl` — Backend API base URL (default: `http://localhost:8000/api/v1`, use `/api/v1` for Docker)

---

## Running the Application Locally

### Starting the Full Stack with Docker Compose

The easiest way to run the complete stack locally is via Docker Compose. From the project root:

```
docker-compose up --build
```

This will start:
- PostgreSQL on port 5432
- Redis on port 6379
- FastAPI backend on port 8000
- Flutter web on port 3000 (if included in compose)

The backend API documentation (Swagger UI) will be available at `http://localhost:8000/docs`.

### Starting Services Individually

**Backend only:**
Activate your Python virtual environment, ensure `.env` is populated, then start the FastAPI development server with Uvicorn from the `backend/` directory using auto-reload enabled.

**Flutter frontend only:**
From the `frontend/` directory, run `flutter run` for a connected device or `flutter run -d chrome` for the web target.

---

## Deployment

### Current Production Status (March 2026)

- Frontend URL: `https://conceptra-webapp.vercel.app`
- Backend API base: `https://conceptra-api.onrender.com/api/v1`
- Health check: `https://conceptra-api.onrender.com/api/v1/health/ready`

Current production deployment uses:
- Vercel for Flutter web frontend
- Render for FastAPI backend (Docker)
- Supabase for PostgreSQL + Auth
- Upstash/Redis for caching and rate limiting

Important production auth/callback settings:
- Supabase Site URL: `https://conceptra-webapp.vercel.app`
- Supabase Redirect URLs include:
  - `https://conceptra-webapp.vercel.app/**`
  - `https://conceptra-webapp-git-master-pavan-kumar-s-projects-a55a3b6a.vercel.app/**`
  - `http://localhost:3000/**` (optional local dev)
- Google OAuth authorized redirect URI:
  - `https://lvgsombxkoedcgznqnge.supabase.co/auth/v1/callback`

Important backend runtime notes:
- Use asyncpg DB URL format for Render:
  - `postgresql+asyncpg://...`
- For Supabase, use pooler host and SSL:
  - `...pooler.supabase.com:5432/...?...ssl=require`
- `ALLOWED_ORIGINS` must include production frontend + preview domain.

For full step-by-step deployment and incident fixes, see `deploy.md` section **"11. Production Incident Log (March 21, 2026)"**.

### Production Docker Compose

For single-server production deployments, use `docker-compose.prod.yml`. This configuration:
- Uses production-hardened Dockerfiles (non-root users, minimal base images)
- Runs Gunicorn with Uvicorn workers for the backend
- Serves Flutter web build via Nginx
- Enables TLS termination (bring your own certificates or use Certbot for free Let's Encrypt certificates)

### Kubernetes (Optional, Advanced)

For teams requiring horizontal scaling, Kubernetes manifests are provided under `infra/k8s/`. These cover:
- Backend Deployment and Service
- Redis Deployment and Service
- PostgreSQL StatefulSet and PersistentVolumeClaim
- Ingress resource (compatible with NGINX Ingress Controller — free and open-source)
- ConfigMap and Secret references for environment configuration

### Free Hosting Options

| Service | What It Hosts | Free Tier Notes |
|---|---|---|
| Fly.io | FastAPI backend | Generous free tier for small apps |
| Railway | Backend + PostgreSQL + Redis | Free trial credits |
| Supabase | PostgreSQL + Auth | Free tier (500MB DB, 50MB storage) |
| Upstash | Redis | Free tier (10k req/day) |
| Vercel / Netlify | Flutter web build | Free static hosting |
| GitHub Container Registry | Docker images | Free for public repos |

### CI/CD Pipeline

GitHub Actions workflows are provided in `.github/workflows/`:

- `ci.yml` — Runs on every pull request: lint, unit tests, integration tests, security scan
- `cd.yml` — Runs on merge to `main`: builds Docker images, pushes to registry, deploys to target environment
- `security.yml` — Weekly dependency vulnerability scan using free tools (pip-audit, flutter pub outdated)

---

## Security Notes

- **JWT Validation** — Every API request requires a valid Supabase-issued JWT. The backend validates the token signature using Supabase's public key via the `python-jose` library. Tokens are short-lived (1 hour) with refresh token rotation.
- **HTTPS Everywhere** — TLS is required in production. The `docker-compose.prod.yml` configuration enforces HTTPS via Nginx.
- **CORS** — In development, any `localhost` origin is allowed via regex. In production, only explicitly listed origins in `ALLOWED_ORIGINS` are permitted.
- **CSRF Protection** — The API is stateless (JWT, no server-side sessions), which inherently prevents CSRF. Custom state parameters are used in OAuth flows.
- **Rate Limiting** — Redis-backed rate limiting is applied at the API gateway level (configurable per route). Default: 100 requests per minute per authenticated user.
- **SQL Injection Prevention** — All database queries use SQLAlchemy parameterized statements. Raw SQL is prohibited.
- **Secrets Management** — No secrets are committed to the repository. All sensitive values are injected via environment variables. In Kubernetes, Kubernetes Secrets or a free-tier secret manager (e.g., Doppler free plan) is recommended.
- **Dependency Scanning** — `pip-audit` and `flutter pub outdated` run automatically in CI to detect known vulnerabilities.
- **Non-Root Containers** — All production Docker containers run as non-root users.

---

## Testing

### Backend Tests

Tests are written with Pytest and organized into unit, integration, and end-to-end categories. A test database (SQLite in-memory or a dedicated PostgreSQL test schema) is used to isolate test state. Run the full test suite from the `backend/` directory.

Coverage targets:
- Unit tests: ≥ 80% line coverage
- Integration tests: All API endpoints covered
- Security tests: Authentication and authorization boundaries validated

### Frontend Tests

Flutter tests are organized into widget tests and integration tests. Widget tests validate individual UI components in isolation. Integration tests use Flutter's integration test framework to exercise full user flows against a mocked or real backend.

Run tests with `flutter test` for unit/widget tests and `flutter test integration_test/` for integration tests.

---

## Observability

| Signal | Tool | Details |
|---|---|---|
| Structured Logging | `structlog` + JSON formatter | Correlation IDs on every request |
| Metrics | Prometheus + `/metrics` endpoint | Request latency, error rate, cache hit rate |
| Tracing | OpenTelemetry SDK | Spans across API, DB, and cache layers |
| Dashboards | Grafana (free, self-hosted) | Pre-built dashboards for backend KPIs |
| Alerting | Grafana Alerting | Configurable thresholds and notification channels |

---

## Internationalization and Accessibility

- **i18n** — Flutter's `flutter_localizations` package is used with ARB files under `frontend/l10n/`. Adding a new language requires creating a new ARB file and registering the locale.
- **Initial Supported Locales** — English (`en`), Hindi (`hi`), Telugu (`te`)
- **a11y** — All interactive widgets use semantic labels. Color contrast meets WCAG 2.1 AA. Screen reader support is validated on both iOS VoiceOver and Android TalkBack.

---

## Contributing

1. Fork the repository and create a feature branch from `main`.
2. Follow the coding standards defined in `CONTRIBUTING.md`.
3. Write tests for all new functionality.
4. Ensure CI passes before requesting a review.
5. Submit a pull request with a clear description of the change and any related issue references.

**Commit message convention:** Conventional Commits format (`feat:`, `fix:`, `docs:`, `chore:`, etc.)

**Branch naming:** `feature/<short-description>`, `bugfix/<short-description>`, `chore/<short-description>`

---

## Roadmap

| Phase | Version | Target Features |
|---|---|---|
| MVP | v0.1 | Auth (Supabase), Physics module (Speed), basic UI |
| Beta | v0.5 | Math module, Teacher dashboard, offline sync |
| v1.0 | v1.0 | Full RBAC, audit logs, notifications, analytics |
| v1.5 | v1.5 | AI explanation engine, gamification, student progress tracking |
| v2.0 | v2.0 | Chemistry simulations, multi-school tenant support |

See `scope.md` for detailed milestone definitions and acceptance criteria.

---

## License

MIT License. See `LICENSE` for full terms.

---

*Conceptra is built and maintained by Sandeep Bangaru. Contributions are welcome.*
