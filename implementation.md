# Conceptra — Implementation Guide

**Version:** 1.0.0  
**Status:** Living Document  
**Last Updated:** 2026  
**Author:** Sandeep Bangaru  

> This document is a step-by-step implementation reference covering everything from initial machine setup through production deployment. It is organized in the exact order a developer should follow to build and ship Conceptra from scratch.

---

## 📑 Table of Contents

- [Part 1 — Developer Machine Setup](#part-1--developer-machine-setup)
- [Part 2 — Repository Initialization](#part-2--repository-initialization)
- [Part 3 — Infrastructure Setup (Local)](#part-3--infrastructure-setup-local)
- [Part 4 — Supabase Auth Setup](#part-4--supabase-auth-setup)
- [Part 5 — Backend Implementation](#part-5--backend-implementation)
  - [5.1 Project Structure](#51-project-structure)
  - [5.2 Dependencies](#52-dependencies)
  - [5.3 Configuration and Environment](#53-configuration-and-environment)
  - [5.4 Database Models and Migrations](#54-database-models-and-migrations)
  - [5.5 Authentication Middleware](#55-authentication-middleware)
  - [5.6 RBAC and Authorization](#56-rbac-and-authorization)
  - [5.7 Redis Caching Layer](#57-redis-caching-layer)
  - [5.8 Computation Engine](#58-computation-engine)
  - [5.9 API Route Handlers](#59-api-route-handlers)
  - [5.10 Observability Instrumentation](#510-observability-instrumentation)
  - [5.11 Backend Testing](#511-backend-testing)
- [Part 6 — Flutter Frontend Implementation](#part-6--flutter-frontend-implementation)
  - [6.1 Project Setup](#61-project-setup)
  - [6.2 Dependencies](#62-dependencies)
  - [6.3 App Architecture (Feature-First)](#63-app-architecture-feature-first)
  - [6.4 Supabase Flutter SDK Integration](#64-supabase-flutter-sdk-integration)
  - [6.5 State Management with Riverpod](#65-state-management-with-riverpod)
  - [6.6 API Client with Dio](#66-api-client-with-dio)
  - [6.7 Offline Support with Hive](#67-offline-support-with-hive)
  - [6.8 Theming and Animations](#68-theming-and-animations)
  - [6.9 Localization (i18n)](#69-localization-i18n)
  - [6.10 Accessibility (a11y)](#610-accessibility-a11y)
  - [6.11 Frontend Testing](#611-frontend-testing)
- [Part 7 — CI/CD Pipeline Setup](#part-7--cicd-pipeline-setup)
- [Part 8 — Production Deployment](#part-8--production-deployment)
  - [8.1 Option A: Single Server (Docker Compose)](#81-option-a-single-server-docker-compose)
  - [8.2 Option B: Free Cloud Hosting (Fly.io + Supabase + Upstash)](#82-option-b-free-cloud-hosting-flyio--supabase--upstash)
  - [8.3 Option C: Kubernetes](#83-option-c-kubernetes)
- [Part 9 — Post-Deployment Checklist](#part-9--post-deployment-checklist)
- [Part 10 — Observability and Monitoring Setup](#part-10--observability-and-monitoring-setup)
- [Part 11 — Security Hardening Checklist](#part-11--security-hardening-checklist)
- [Part 12 — Common Troubleshooting](#part-12--common-troubleshooting)

---

## Part 1 — Developer Machine Setup

This section covers all tools required on your development machine. All tools are free and open source.

### 1.1 Install Flutter SDK

Download the Flutter SDK for your operating system from the official Flutter website (flutter.dev). Follow the platform-specific installation guide. After installation:

- Add the Flutter `bin` directory to your system `PATH`.
- Run `flutter doctor` and resolve any issues reported. Ensure at minimum one device target (Android emulator or Chrome web) is available.
- Switch to the stable channel using `flutter channel stable` followed by `flutter upgrade`.

**Flutter Version Required:** 3.x (stable channel)

### 1.2 Install Python

Download Python 3.11 or later from python.org. During installation on Windows, check the option to add Python to PATH. Verify the installation by checking the version in a new terminal. Also verify that `pip` is available.

### 1.3 Install Docker Desktop

Download Docker Desktop from docker.com. Docker Desktop includes Docker Engine, Docker Compose v2, and the Docker CLI. After installation, start Docker Desktop and verify it is running. For Linux users, Docker Engine and Docker Compose CLI plugin can be installed separately via the official Docker apt/yum repositories.

### 1.4 Install Git

Download Git from git-scm.com. Configure your user name and email after installation. Set your default branch name to `main`.

### 1.5 Install Visual Studio Code (Recommended)

VS Code is the recommended editor. Install the following extensions:
- Flutter (by Dart Code)
- Dart (by Dart Code)
- Python (by Microsoft)
- Pylance (by Microsoft)
- Docker (by Microsoft)
- GitLens (by GitKraken)
- Even Better TOML (for configuration files)

### 1.6 Install Android Studio (For Mobile Development)

If targeting Android, install Android Studio to obtain the Android SDK and create virtual devices. After installation, open the SDK Manager and install Android SDK Platform for API level 23 (Android 6.0) and a recent API level for testing. Create an AVD (Android Virtual Device) using the AVD Manager.

### 1.7 Install Supabase CLI (Optional but Recommended)

The Supabase CLI allows you to manage Supabase projects from the command line and run a local Supabase instance for development. Install it via npm (requires Node.js 20 LTS) using the official Supabase CLI installation guide at supabase.com/docs/guides/cli.

---

## Part 2 — Repository Initialization

### 2.1 Create the Repository

Create a new public repository on GitHub named `Conceptra`. Public repositories receive unlimited GitHub Actions CI/CD minutes on the free tier.

### 2.2 Clone and Initialize the Monorepo

Clone the repository to your local machine. Inside the repository root, create the top-level directory structure as defined in `readme.md`. Initialize the following root-level files:
- `.gitignore` — Comprehensive ignore rules for Python, Flutter, Docker, and IDE artifacts
- `.editorconfig` — Consistent code style settings (indent size, line endings)
- `LICENSE` — MIT License
- `readme.md`, `spec.md`, `scope.md`, `implementation.md`

### 2.3 Configure .gitignore

The `.gitignore` must exclude the following categories:
- Python: `__pycache__/`, `*.pyc`, `*.pyo`, `.venv/`, `venv/`, `.env`, `*.egg-info/`, `dist/`, `build/`, `.pytest_cache/`, `.coverage`, `htmlcov/`
- Flutter: `.dart_tool/`, `.flutter-plugins`, `.flutter-plugins-dependencies`, `build/`, `*.iml`, `.packages`
- Docker: local volume data directories
- IDE: `.idea/`, `.vscode/settings.json` (allow `.vscode/extensions.json`), `*.swp`
- OS: `.DS_Store`, `Thumbs.db`
- Secrets: `.env`, `.env.*` (but allow `.env.example`)

### 2.4 Branching Strategy

Adopt a trunk-based development approach:
- `main` — Production-ready code. Protected branch; requires PR review and CI to pass before merge.
- `develop` — Integration branch for feature work (optional for small teams).
- `feature/<name>` — Short-lived feature branches.
- `bugfix/<name>` — Bug fix branches.
- `release/<version>` — Release preparation branches.

Configure branch protection rules in the GitHub repository settings:
- Require pull request reviews before merging (1 reviewer minimum)
- Require status checks to pass (CI workflow must pass)
- Require branches to be up to date before merging
- Restrict direct pushes to `main`

---

## Part 3 — Infrastructure Setup (Local)

### 3.1 Docker Compose for Local Development

Create a `docker-compose.yml` at the project root. This file defines the following services:

**postgres service:**
- Image: `postgres:15-alpine`
- Environment variables: `POSTGRES_DB=Conceptra`, `POSTGRES_USER=Conceptra_user`, `POSTGRES_PASSWORD` (use a strong local dev password)
- Port: exposes 5432 to the host
- Volume: named volume `postgres_data` for persistence across container restarts
- Health check: uses `pg_isready` to confirm database is accepting connections

**redis service:**
- Image: `redis:7-alpine`
- Port: exposes 6379 to the host
- Volume: named volume `redis_data`
- Command: enables persistence with `--appendonly yes`
- Health check: uses `redis-cli ping`

**backend service:**
- Build context: `./backend`
- Dockerfile: `infra/docker/Dockerfile.backend`
- Depends on: `postgres` and `redis` health checks
- Environment variables: loaded from `./backend/.env`
- Port: exposes 8000 to the host
- Volume mount: `./backend:/app` for hot reload in development
- Command: Uvicorn with `--reload` flag

Define a `networks` section using a custom bridge network so all services can communicate by service name.

### 3.2 Create Backend Dockerfile (Development)

The development Dockerfile for the backend:
- Base image: `python:3.11-slim`
- Set working directory to `/app`
- Copy `requirements.txt` first (leverages Docker layer cache for dependencies)
- Install dependencies with pip
- Copy the application code
- Expose port 8000
- Set the default command to start Uvicorn

### 3.3 Start the Local Stack

From the project root, run Docker Compose to start all services. Verify:
- PostgreSQL is reachable on localhost:5432
- Redis is reachable on localhost:6379
- The backend container starts (it may fail initially until the application code is added — this is expected)

### 3.4 Database Initialization

Once the backend application and Alembic are configured (see Part 5), run the initial Alembic migration to create all tables. Verify the tables are created by connecting to PostgreSQL using `psql` or a free GUI tool like DBeaver.

---

## Part 4 — Supabase Auth Setup

### 4.1 Create a Supabase Account and Project

Navigate to supabase.com and sign up for a free account. Create a new project:
- Name: `Conceptra-dev` (for development)
- Region: Select the region closest to your users (e.g., ap-south-1 for India)
- Password: Generate and store a strong database password in your password manager

Wait for the project to provision (approximately 2 minutes).

### 4.2 Collect Required Credentials

From your Supabase project dashboard, navigate to **Settings → API** and copy:
- **Project URL** — The base URL for your Supabase project (e.g., `https://xxxx.supabase.co`)
- **anon / public key** — Used by the Flutter SDK for public operations
- **JWT Secret** — Used by the FastAPI backend to validate JWTs. Navigate to **Settings → API → JWT Settings** to find this.

Store these values securely. They will be placed in environment files.

### 4.3 Configure OAuth Providers

Navigate to **Authentication → Providers** in your Supabase dashboard.

**Google OAuth (Free):**
1. Enable the Google provider.
2. Create a project at console.cloud.google.com (free).
3. Enable the Google+ API (or People API).
4. Create OAuth 2.0 credentials (Web application type).
5. Set the authorized redirect URI to the Supabase callback URL shown in the Supabase dashboard.
6. Paste the Google Client ID and Client Secret into the Supabase provider configuration.

**GitHub OAuth (Free):**
1. Enable the GitHub provider.
2. Go to GitHub → Settings → Developer Settings → OAuth Apps → New OAuth App.
3. Set the Authorization callback URL to the Supabase callback URL shown in the Supabase dashboard.
4. Paste the GitHub Client ID and Client Secret into the Supabase provider configuration.

### 4.4 Configure Redirect URLs

Navigate to **Authentication → URL Configuration** and add:
- Site URL: `http://localhost:3000` (for development)
- Additional redirect URLs: your production domain (e.g., `https://Conceptra.yourdomain.com`)

### 4.5 Set Up Custom JWT Claims for RBAC

To embed the user's role in the JWT, configure a Supabase database hook. Navigate to **Database → Functions** and create a PostgreSQL function that:
- Triggers after a user is inserted into `auth.users`
- Creates a corresponding row in your `user_profiles` table with the default role of `student`
- Returns the custom claims object including the role

Navigate to **Database → Hooks** and create a hook that calls this function on the `auth.users` insert event.

This allows the FastAPI backend to read the role directly from the JWT without a database lookup on every request.

### 4.6 Test Authentication

Use the Supabase dashboard's Authentication section or the Supabase client library to create a test user and verify login works. Verify that a JWT is issued and that it contains the expected custom claims.

---

## Part 5 — Backend Implementation

### 5.1 Project Structure

Inside `backend/`, create the following directory and file structure:

The top-level `backend/` directory contains:
- `app/` — The main application package
- `tests/` — All Pytest test files (mirrors the `app/` structure)
- `alembic/` — Database migration scripts
- `alembic.ini` — Alembic configuration
- `requirements.txt` — Python dependencies
- `requirements-dev.txt` — Development-only dependencies (pytest, coverage, etc.)
- `.env.example` — Template for required environment variables
- `Makefile` — Shortcut commands (run, test, migrate, lint)

The `app/` package contains:
- `main.py` — FastAPI app factory and startup configuration
- `core/` — Configuration, security middleware, logging setup
- `api/` — Route handler modules organized by version (`v1/`)
- `services/` — Business logic layer (decoupled from HTTP)
- `db/` — SQLAlchemy models, session factory, base class
- `schemas/` — Pydantic request and response models
- `cache/` — Redis client initialization and cache utility functions
- `tasks/` — Background task definitions

### 5.2 Dependencies

**`requirements.txt`** (production dependencies):

| Package | Purpose |
|---|---|
| `fastapi` | Web framework |
| `uvicorn[standard]` | ASGI server |
| `gunicorn` | Production process manager |
| `sqlalchemy[asyncio]` | Async ORM |
| `asyncpg` | Async PostgreSQL driver |
| `alembic` | Database migrations |
| `pydantic-settings` | Environment variable configuration |
| `python-jose[cryptography]` | JWT validation |
| `aioredis` | Async Redis client |
| `httpx` | Async HTTP client (for Supabase JWKS fetch) |
| `python-multipart` | Multipart form data support |
| `structlog` | Structured logging |
| `opentelemetry-sdk` | Distributed tracing |
| `opentelemetry-instrumentation-fastapi` | FastAPI auto-instrumentation |
| `opentelemetry-instrumentation-sqlalchemy` | SQLAlchemy auto-instrumentation |
| `prometheus-fastapi-instrumentator` | Prometheus metrics |

**`requirements-dev.txt`** (development and testing):

| Package | Purpose |
|---|---|
| `pytest` | Test framework |
| `pytest-asyncio` | Async test support |
| `pytest-cov` | Coverage reporting |
| `httpx` | AsyncClient for API testing |
| `factory-boy` | Test data factories |
| `faker` | Fake data generation |
| `ruff` | Fast Python linter and formatter |
| `pip-audit` | Dependency vulnerability scanning |

### 5.3 Configuration and Environment

Create `app/core/config.py` that defines a Pydantic `Settings` class. This class reads all configuration from environment variables, providing type validation and default values. The Settings class covers:

- `DATABASE_URL` — Full async PostgreSQL connection string (with `postgresql+asyncpg://` prefix)
- `REDIS_URL` — Redis connection string
- `SUPABASE_URL` — Supabase project URL
- `SUPABASE_JWT_SECRET` — JWT secret for token validation
- `ALLOWED_ORIGINS` — List of CORS-allowed origins
- `ENVIRONMENT` — Deployment environment identifier
- `LOG_LEVEL` — Logging verbosity
- `RATE_LIMIT_PER_MINUTE` — Default rate limit threshold

Create `.env.example` at the `backend/` root documenting every required variable with placeholder values and descriptive comments. Copy this to `.env` and populate with real values for local development.

### 5.4 Database Models and Migrations

**SQLAlchemy Models (`app/db/models.py`):**

Define SQLAlchemy ORM models corresponding to every table defined in `spec.md` Section 4. Key implementation notes:
- Use `uuid.UUID` mapped to PostgreSQL `UUID` type with `gen_random_uuid()` server default for primary keys
- Use `TIMESTAMPTZ` (timezone-aware) for all timestamp columns via SQLAlchemy's `DateTime(timezone=True)`
- Use `JSONB` for flexible data columns (input_parameters, computed_result, metadata)
- Define relationships between models using SQLAlchemy `relationship()` for ORM convenience
- Add `__table_args__` for composite indexes and unique constraints as defined in the schema
- Use SQLAlchemy's `event.listens_for` to automatically update `updated_at` timestamps

**Database Session Factory (`app/db/session.py`):**

Create an async SQLAlchemy engine using `create_async_engine` with the `asyncpg` driver. Configure connection pooling:
- `pool_size`: 10 (default for production; reduce to 5 for development)
- `max_overflow`: 20
- `pool_pre_ping`: True (detects stale connections)

Define an async session factory using `AsyncSession` and `async_sessionmaker`. Create a FastAPI dependency function `get_db()` that yields an async session and commits or rolls back on exit.

**Alembic Configuration:**

Initialize Alembic from the `backend/` directory. Configure `alembic.ini` to use the `DATABASE_URL` from environment rather than a hardcoded string. Update `env.py` to use the async engine and to import all SQLAlchemy models so Alembic can detect schema changes with `--autogenerate`.

**Creating and Applying Migrations:**

Generate the initial migration using Alembic's autogenerate feature after defining all models. Review the generated migration file carefully before applying it. Apply migrations against the running PostgreSQL instance using Alembic's upgrade command. Add a Makefile target for convenience.

For subsequent schema changes:
- Modify the SQLAlchemy model
- Generate a new migration with a descriptive name
- Review and test the migration on a local database
- Commit the migration file to the repository
- Apply in production during a maintenance window or via the CD pipeline

### 5.5 Authentication Middleware

Create `app/core/security.py`. This module contains:

**JWKS Key Fetching:**
On application startup, fetch the Supabase project's JWKS (JSON Web Key Set) endpoint. Parse the public key from the response. Cache the public key in-process for the lifetime of the application. Implement a key refresh mechanism for handling key rotation.

**JWT Validation Function:**
Implement a function that accepts a raw JWT string and:
- Decodes the token using `python-jose` with the RS256 algorithm and the cached public key
- Validates the `exp` (expiry), `iss` (issuer), and `aud` (audience) claims
- Returns the decoded payload on success
- Raises an `HTTPException` with status 401 on any validation failure (expired, invalid signature, malformed)

**FastAPI Dependency:**
Create a `get_current_user` dependency function that:
- Extracts the JWT from the `Authorization: Bearer <token>` header
- Calls the validation function
- Fetches the user's profile from PostgreSQL (with Redis caching)
- Returns the user profile model to the route handler
- Raises 401 if the user profile does not exist (e.g., first-time login before profile creation)

**First Login Profile Creation:**
Create a separate dependency `get_or_create_user` that is used on the `/auth/me` endpoint. This dependency calls `get_current_user` but creates the user profile if it does not exist, using the `email` and `name` claims from the JWT.

### 5.6 RBAC and Authorization

Create `app/core/rbac.py`. Define a `require_role()` dependency factory that:
- Accepts a list of allowed roles (e.g., `["teacher", "admin"]`)
- Returns a FastAPI dependency function
- The dependency calls `get_current_user` and checks whether the user's role is in the allowed list
- Raises HTTP 403 with a structured error response if the role is not permitted

Apply `require_role()` to route handlers in the router definitions:
- Pass `dependencies=[Depends(require_role(["admin"]))]` at the router or route level
- For read operations accessible to all authenticated users, use `Depends(get_current_user)` directly

### 5.7 Redis Caching Layer

Create `app/cache/client.py` to initialize the async Redis client using `aioredis`. The client is created on application startup and stored as a FastAPI application state attribute.

Create `app/cache/decorators.py` with a `cached_response()` utility function:
- Accepts a cache key pattern, TTL, and key arguments
- On cache hit: deserialize and return the cached value
- On cache miss: execute the original function, serialize the result, store in Redis, and return
- On Redis error: log the error and fall through to compute without caching (graceful degradation)

Create `app/cache/invalidation.py` with explicit invalidation functions for each cache key pattern. These are called by service layer functions after successful write operations.

**Rate Limiting:**
Implement Redis-based sliding window rate limiting in `app/core/rate_limit.py`. This middleware:
- Checks a Redis sorted set for the user's recent request timestamps
- Returns HTTP 429 with a `Retry-After` header if the request count exceeds the configured limit
- Adds the current timestamp to the set and sets expiry on the set

### 5.8 Computation Engine

Create `app/services/computation.py`. This module contains pure Python functions for each simulation type. Key implementation principles:
- Functions must be deterministic and side-effect-free (suitable for caching)
- Functions must validate input ranges and raise `ValueError` for invalid inputs (e.g., division by zero)
- Functions return a structured result dictionary including computed values, formula string, substitution string, and conclusion text
- Graph data points are generated by computing the output across the full parameter range in configurable increments

**Physics Computations (MVP and v1.0):**

Speed Module: Computes speed from distance and time. Validates time is not zero. Returns speed in m/s, the formula string, step-by-step substitution, a conclusion sentence, and an array of (time, distance) data points across the defined range for plotting a Distance–Time curve.

Acceleration Module: Computes acceleration from the change in velocity and time. Returns acceleration in m/s², the formula, substitution, conclusion, and a Velocity–Time data point array.

Force Module: Computes force from mass and acceleration using Newton's Second Law. Returns force in Newtons, the formula, substitution, conclusion, and a Force–Mass data point array.

**Mathematics Computations (Phase 1):**

Linear Equation Module: Computes y = mx + c across a configurable x range. Returns the slope, intercept, a table of (x, y) pairs, and instructions for plotting the line.

**Localization of Explanations:**
Accept a `locale` parameter in the computation functions. Use a locale-to-template dictionary to return the conclusion text in the requested language. For MVP, support English and Hindi templates. Telugu is added in Phase 2.

### 5.9 API Route Handlers

Organize route handlers under `app/api/v1/`. Create a separate router file for each resource group and include all routers in the main FastAPI app with the `/api/v1` prefix.

**Router Organization:**

`auth.py` router — Handles profile retrieval and update. Uses `get_or_create_user` dependency on the `GET /auth/me` endpoint to support first-login profile creation.

`modules.py` router — Handles module CRUD. List and detail endpoints use the Redis cache decorator. Write endpoints invalidate the relevant cache keys after database commit and append an audit log entry.

`simulate.py` router — Handles simulation execution and history. The `POST /simulate` endpoint:
1. Validates the module exists and is published
2. Validates input parameters against the module's defined parameter constraints
3. Generates a cache key from `module_id` and the sorted parameter hash
4. Checks Redis for a cached result
5. On miss, calls the computation engine service
6. Stores the session in PostgreSQL (always, even on cache hit, to record the user's activity)
7. Stores the computation result in Redis
8. Returns the session ID, inputs, result, explanation, and graph data

`progress.py` router — Handles student progress upsert. Uses PostgreSQL's `INSERT ... ON CONFLICT DO UPDATE` (upsert) via SQLAlchemy to efficiently update progress records.

`analytics.py` router — Aggregates data from `simulation_sessions` and `progress_records`. Results are cached for 15 minutes due to their computational cost.

`admin.py` router — Handles user management and audit log queries. All endpoints require the `admin` role. Write operations append to the audit log.

`health.py` router — Implements `/health` and `/health/ready`. The readiness endpoint performs a lightweight query against PostgreSQL (`SELECT 1`) and a Redis `PING` to confirm connectivity before returning 200.

### 5.10 Observability Instrumentation

**Structured Logging:**
Configure `structlog` in `app/core/logging_config.py` to output JSON-formatted log records. Each log record includes:
- `timestamp` in ISO 8601 format
- `level` (DEBUG, INFO, WARNING, ERROR)
- `event` — Human-readable message
- `correlation_id` — UUID generated per request (injected by middleware)
- `user_id` — Authenticated user ID (injected by auth middleware when available)
- `path`, `method`, `status_code` — HTTP context

A FastAPI middleware intercepts each request, generates a `correlation_id`, adds it to the request state, and logs request/response events.

**Prometheus Metrics:**
Use `prometheus-fastapi-instrumentator` to automatically expose standard HTTP metrics (request count, latency histograms, in-progress requests) at the `/metrics` endpoint. Add custom metrics:
- `Conceptra_simulation_duration_seconds` — Histogram for computation time per module
- `Conceptra_cache_hits_total` and `Conceptra_cache_misses_total` — Counters for cache effectiveness

**OpenTelemetry Tracing:**
Initialize the OpenTelemetry SDK in `app/main.py`. Use `FastAPIInstrumentor` and `SQLAlchemyInstrumentor` for automatic span creation. Configure the OTLP exporter to send traces to your OpenTelemetry Collector (or use the console exporter during development). Each trace links the `correlation_id` to the distributed trace for correlation between logs and traces.

### 5.11 Backend Testing

**Test Configuration:**
Create `tests/conftest.py` that:
- Configures Pytest with `asyncio_mode = "auto"` for async tests
- Creates a test FastAPI application with overridden dependencies (test database session, mocked Redis)
- Provides an `AsyncClient` fixture for HTTP testing using `httpx`
- Provides a `db_session` fixture that wraps tests in a transaction and rolls back after each test
- Provides factory fixtures using `factory-boy` for creating test instances of models

**Unit Tests (`tests/unit/`):**
Test the computation engine in isolation. Cover:
- Correct output for valid inputs across boundary values
- ValueError raised for invalid inputs (zero time, negative mass, etc.)
- Correct graph data point generation
- Correct explanation text generation per locale

**Integration Tests (`tests/integration/`):**
Test API endpoints against the test database and mocked Redis. Cover:
- All authentication scenarios (valid token, expired token, missing token, invalid role)
- All CRUD operations for modules (create, read, update, delete, publish)
- Simulation execution (valid parameters, invalid parameters, cache hit behavior)
- Progress upsert logic
- Rate limiting behavior
- Audit log creation on admin write operations

**Running Tests:**
From the `backend/` directory with the virtual environment activated, run `pytest` with coverage reporting. The CI pipeline enforces a minimum coverage threshold.

---

## Part 6 — Flutter Frontend Implementation

### 6.1 Project Setup

From the `frontend/` directory, create a new Flutter project using the Flutter CLI, targeting all platforms (Android, iOS, web). Remove the default counter app and replace `main.dart` with the Conceptra app entry point.

Configure supported platforms explicitly in `pubspec.yaml` and in the platform-specific configuration files:
- Android: `minSdkVersion 23` (Android 6.0) in `android/app/build.gradle`
- iOS: `IPHONEOS_DEPLOYMENT_TARGET 13.0` in `ios/Podfile`
- Web: No additional version configuration needed; targets modern browsers

### 6.2 Dependencies

Add the following packages to `pubspec.yaml` under `dependencies`:

| Package | Purpose |
|---|---|
| `supabase_flutter` | Supabase Auth SDK for Flutter |
| `flutter_riverpod` | State management |
| `riverpod_annotation` | Code generation for Riverpod providers |
| `dio` | HTTP client with interceptors |
| `hive_flutter` | Offline-first local storage |
| `go_router` | Declarative routing with deep linking |
| `fl_chart` | Chart rendering for simulation graphs |
| `flutter_animate` | Declarative animation system |
| `flutter_secure_storage` | Secure token storage (Keychain / Keystore) |
| `connectivity_plus` | Network connectivity detection |
| `intl` | Internationalization support |
| `flutter_localizations` | Built-in Flutter localization delegates |

Add under `dev_dependencies`:

| Package | Purpose |
|---|---|
| `riverpod_generator` | Riverpod code generation |
| `build_runner` | Code generation runner |
| `flutter_test` | Widget testing framework (SDK) |
| `integration_test` | Integration testing framework (SDK) |
| `mocktail` | Mocking library for Dart tests |

### 6.3 App Architecture (Feature-First)

Conceptra uses a feature-first architecture where each feature is a self-contained folder with its own data, domain, and presentation layers:

`lib/features/auth/` — Authentication feature:
- `data/` — Supabase auth repository implementation
- `domain/` — Auth state models and repository interface
- `presentation/` — Login screen, register screen, profile screen, auth controller (Riverpod)

`lib/features/simulations/` — Simulation feature:
- `data/` — Simulation API repository implementation, Hive local repository
- `domain/` — Module and session models, repository interfaces
- `presentation/` — Module list screen, module detail screen, simulation screen (with sliders and chart), session history screen

`lib/features/dashboard/` — Student progress dashboard

`lib/features/teacher/` — Teacher content management (module creation and editing)

`lib/features/admin/` — Admin user management and audit log viewer

`lib/core/` — Shared infrastructure:
- `router/` — GoRouter configuration with authentication guards
- `theme/` — ThemeData definitions (light and dark)
- `network/` — Dio client factory and interceptors
- `env.dart` — Environment configuration
- `constants.dart` — App-wide constants

`lib/shared/` — Reusable widgets and utilities used across features

### 6.4 Supabase Flutter SDK Integration

Initialize Supabase in `main.dart` before `runApp()` by calling `Supabase.initialize()` with the project URL and anon key read from `env.dart`.

Create `lib/features/auth/data/supabase_auth_repository.dart` that wraps Supabase Flutter SDK methods:
- `signInWithOAuth()` — Triggers Google or GitHub OAuth flow
- `signInWithPassword()` — Email/password login
- `signUp()` — Email/password registration
- `signOut()` — Clears session
- `currentSession` — Returns the current session (JWT + user)
- `onAuthStateChange` stream — Emits auth events for reactive state updates

Implement `flutter_secure_storage` to persist the refresh token securely. The Supabase SDK handles refresh token storage internally on most platforms, but verify this for web (uses localStorage by default; consider overriding to sessionStorage or a secure cookie approach for web targets).

### 6.5 State Management with Riverpod

Use Riverpod 2 with code generation (`riverpod_annotation` + `riverpod_generator`) for a type-safe, compile-time-verified provider graph.

**Auth Providers:**
- `authRepositoryProvider` — Provides the Supabase auth repository instance
- `authStateProvider` — A `StreamProvider` over `onAuthStateChange`; drives the router's authentication guard
- `currentUserProfileProvider` — A `FutureProvider` that fetches the user profile from the API after authentication

**Simulation Providers:**
- `modulesProvider` — A `FutureProvider.family` parameterized by filter options; fetches from API or Hive cache
- `simulationControllerProvider` — A `StateNotifier` managing the simulation screen state (current parameter values, computation result, loading state, error state)
- `sessionHistoryProvider` — Fetches and caches the user's session history

**Offline Sync Provider:**
- `syncQueueProvider` — A Notifier managing the Hive-backed offline sync queue; triggers background sync when connectivity is restored

Run `dart run build_runner build` to generate all Riverpod provider boilerplate after defining providers with annotations.

### 6.6 API Client with Dio

Create `lib/core/network/api_client.dart`. Configure a Dio instance:

**Base Options:**
- `baseUrl`: Set from `env.dart`
- `connectTimeout`: 10 seconds
- `receiveTimeout`: 30 seconds

**Interceptors (applied in order):**

Auth Interceptor: Retrieves the current JWT from the Supabase session and adds it as the `Authorization: Bearer <token>` header. If the token is expired, triggers a Supabase session refresh before retrying the request.

Logging Interceptor: Logs all requests and responses in DEBUG mode. Sanitizes sensitive headers before logging.

Error Interceptor: Parses the structured error response envelope and converts it into typed Dart exceptions (e.g., `ApiException`, `AuthException`, `ValidationException`). Handles 401 responses by triggering a logout flow via the auth state provider.

Retry Interceptor: Retries failed requests (network errors, 5xx responses) up to 2 times with exponential backoff.

### 6.7 Offline Support with Hive

Initialize Hive in `main.dart` before the app starts. Register custom Hive type adapters for the domain models that need to be persisted (SimulationModule, SimulationSession, UserProgress).

**Hive Boxes:**
- `modules_box` — Stores simulation module definitions fetched from the API
- `sessions_box` — Stores the user's last 20 simulation sessions
- `sync_queue_box` — Stores pending simulation sessions created offline
- `progress_box` — Stores the user's progress records
- `user_profile_box` — Stores the current user's profile

**Offline Repository Pattern:**
Each data repository (`ModuleRepository`, `SessionRepository`) implements a cache-aside strategy:
- On read: return the Hive-cached value immediately, then fetch from the API in the background and update the cache
- On write (online): write to the API, then update the Hive cache
- On write (offline): write to the `sync_queue_box` and update the Hive cache optimistically

**Background Sync:**
Subscribe to the `connectivity_plus` connectivity stream. When connectivity is restored:
1. Read all pending entries from `sync_queue_box`
2. Attempt to replay each entry to the API in order
3. On success, remove the entry from the queue
4. On failure, retain the entry in the queue for the next connectivity restoration event

### 6.8 Theming and Animations

**Theme:**
Define `AppTheme` in `lib/core/theme/app_theme.dart`. Create separate `ThemeData` instances for light and dark themes. Key decisions:
- Use Material Design 3 (`useMaterial3: true`)
- Define a color scheme using `ColorScheme.fromSeed()` with Conceptra's brand color
- Define consistent text styles, icon sizes, border radii, and elevation values using the theme's `TextTheme` and `ComponentTheme` extensions
- Store the active theme preference in Hive and expose it as a Riverpod provider

**Animations:**
Use `flutter_animate` for declarative, chained animations. Apply animations:
- Simulation result appearance: `FadeEffect` + `SlideEffect` on the result card
- Chart rendering: `ScaleEffect` on chart container on first appearance
- Loading skeleton: Shimmer effect on module list while fetching
- Slider value change: Smooth value transition using `AnimatedSwitcher` for the output display

Implement a custom `SimulationAnimationWidget` that shows a moving object (e.g., a car on a track) whose position and speed update in real time as slider values change, using Flutter's `AnimationController` and `Tween`.

### 6.9 Localization (i18n)

**Setup:**
Add `flutter_localizations` SDK dependency and `intl` to `pubspec.yaml`. Enable code generation in `pubspec.yaml` under `flutter: generate: true`. Create `l10n.yaml` at the `frontend/` root specifying the ARB directory, template file, and output class name.

**ARB Files:**
Create `frontend/l10n/app_en.arb` (English — template), `app_hi.arb` (Hindi), and `app_te.arb` (Telugu). ARB files contain key-value pairs where keys are used in Dart code and values are the translated strings.

**Coverage Areas:**
- All screen titles and navigation labels
- All button labels and action text
- All error messages and validation messages
- Simulation explanation templates (formula names, unit labels, conclusion sentences)
- Number and unit formatting (locale-aware decimal separators)

Run `flutter gen-l10n` (or `dart run build_runner build`) to generate the `AppLocalizations` Dart class. Use `AppLocalizations.of(context)!.keyName` in widget code to retrieve localized strings.

**Locale Persistence:**
Store the user's selected locale in Hive and in the user profile (synced to the backend). The app reads the locale preference on startup before rendering any UI.

### 6.10 Accessibility (a11y)

Apply the following accessibility practices across all screens:

**Semantic Labels:**
Wrap all custom widgets in `Semantics()` widgets with descriptive `label` and `hint` properties. Sliders must include the parameter name, current value, unit, and range in their semantic description. Charts must have a text alternative describing the relationship shown.

**Keyboard Navigation:**
Ensure all interactive elements are reachable via tab navigation on web and desktop targets. Use `FocusTraversalGroup` to define logical tab order within complex screens.

**Color Contrast:**
Verify all text meets the WCAG 2.1 AA 4.5:1 contrast ratio against its background. Use the Flutter Color Contrast Analyzer or a browser-based tool for verification. Do not rely on color alone to convey information (use icons and text alongside color coding).

**Touch Target Size:**
All interactive elements (buttons, sliders, list items) must have a minimum touch target size of 48×48 logical pixels, per Material Design accessibility guidelines.

**Text Scaling:**
All text must scale correctly when the system font size is increased. Test with accessibility font sizes (1.5× and 2×). Avoid fixed-height containers that clip scaled text.

### 6.11 Frontend Testing

**Widget Tests (`test/`):**
Write widget tests for all complex custom widgets:
- `SimulationSlider` — Verifies slider renders with correct label, range, and value
- `SimulationResultCard` — Verifies result values and explanation text render correctly
- `SimulationChart` — Verifies chart renders with the expected number of data points
- `ModuleCard` — Verifies module metadata is displayed correctly

Use `mocktail` to mock Riverpod providers and API responses in widget tests.

**Integration Tests (`integration_test/`):**
Write integration tests that run on a real device or emulator against a mocked backend:
- End-to-end login flow
- Browse modules and open a simulation
- Adjust sliders and verify the result updates
- Complete a simulation and verify it appears in history
- Toggle theme and verify persistence

---

## Part 7 — CI/CD Pipeline Setup

### 7.1 GitHub Actions Overview

Create three workflow files in `.github/workflows/`:

**`ci.yml` — Continuous Integration (triggered on every PR and push to `main`):**

Jobs:
1. `backend-lint-and-test` — Checks out code, sets up Python 3.11, installs dependencies, runs `ruff` linter, runs `pytest` with coverage, fails if coverage drops below threshold, runs `pip-audit` security scan
2. `flutter-lint-and-test` — Checks out code, sets up Flutter stable, runs `flutter pub get`, runs `flutter analyze` (static analysis), runs `flutter test` with coverage
3. `docker-build-check` — Builds the backend Docker image to verify the Dockerfile is valid (does not push)

**`cd.yml` — Continuous Deployment (triggered on push to `main` only):**

Jobs:
1. `build-and-push` — Builds the backend Docker image for `linux/amd64` and `linux/arm64` using Docker Buildx, tags with the commit SHA and `latest`, pushes to GitHub Container Registry (GHCR — free for public repos)
2. `build-flutter-web` — Runs `flutter build web --release`, uploads the `build/web` artifact
3. `deploy-backend` — SSHes into the production server and runs `docker compose pull && docker compose up -d` (for single-server deployments), or updates a Kubernetes deployment (for k8s deployments)
4. `deploy-frontend` — Deploys the Flutter web build to the static hosting provider (Vercel, Netlify, or Nginx on the server)

**`security.yml` — Scheduled Security Scan (runs weekly on Sunday at midnight):**

Jobs:
1. `dependency-audit` — Runs `pip-audit` on backend and `flutter pub outdated` on frontend; creates a GitHub Issue if high-severity vulnerabilities are found
2. `docker-image-scan` — Scans the latest production Docker image using Trivy (free, open-source container scanner)

### 7.2 Secrets Configuration

In the GitHub repository's **Settings → Secrets and variables → Actions**, add:
- `SUPABASE_URL` — Supabase project URL (production)
- `SUPABASE_JWT_SECRET` — Supabase JWT secret (production)
- `DATABASE_URL` — Production PostgreSQL connection string
- `REDIS_URL` — Production Redis connection string
- `DEPLOY_SSH_KEY` — SSH private key for the production server (if using SSH deployment)
- `DEPLOY_HOST` — Production server hostname
- `GHCR_TOKEN` — GitHub personal access token with `write:packages` scope (for pushing to GHCR)

---

## Part 8 — Production Deployment

### 8.1 Option A: Single Server (Docker Compose)

This option deploys the entire stack on a single Linux server (e.g., a free-tier VPS, a school server, or a low-cost cloud VM).

**Server Preparation:**
- Provision a Linux server (Ubuntu 22.04 LTS recommended) with a minimum of 2 vCPU and 2GB RAM
- Install Docker Engine and Docker Compose plugin using the official Docker apt repository
- Create a non-root `Conceptra` user and add it to the `docker` group
- Install Certbot for free Let's Encrypt TLS certificates

**DNS Configuration:**
Point your domain's A record to the server's public IP address. Allow time for DNS propagation.

**TLS Certificate:**
Obtain a free certificate from Let's Encrypt using Certbot with the Nginx plugin. Configure automatic renewal (Certbot sets up a cron job automatically).

**Nginx Configuration:**
Create an Nginx site configuration that:
- Listens on port 443 (HTTPS) with the Let's Encrypt certificate paths
- Redirects all port 80 (HTTP) traffic to HTTPS
- Proxies `/api/v1/*` requests to the FastAPI backend container
- Serves the Flutter web build from its compiled static directory for all other paths
- Sets all security headers defined in spec.md Section 7.4
- Restricts access to `/metrics` to localhost only

**Production Docker Compose:**
The `docker-compose.prod.yml` differs from development in:
- Backend uses `gunicorn` with `uvicorn.workers.UvicornWorker` (4 workers recommended for 2 vCPU)
- No volume mount for hot reload (code is baked into the image)
- Resource limits defined for each container (`mem_limit`, `cpus`)
- Restart policy: `unless-stopped`
- Environment variables read from a `.env.prod` file that is never committed to the repository

**Deployment Steps:**
1. SSH into the server as the `Conceptra` user
2. Clone the repository or pull the latest changes
3. Create `.env.prod` with production values
4. Pull the latest Docker images from GHCR
5. Run `docker compose -f docker-compose.prod.yml up -d`
6. Run Alembic migrations against the production database
7. Verify the health endpoint returns 200
8. Verify the Flutter web app loads in a browser

### 8.2 Option B: Free Cloud Hosting (Fly.io + Supabase + Upstash)

This option uses free tiers of multiple cloud services for a fully managed, serverless deployment.

**Backend on Fly.io (Free Tier):**
- Install the `flyctl` CLI from fly.io
- In the `backend/` directory, run `fly launch` to initialize a Fly.io application
- Configure the generated `fly.toml` with the correct port, health check path, and environment variable references
- Set secrets using `fly secrets set KEY=VALUE` for all production environment variables
- Deploy using `fly deploy` which builds and pushes the Docker image to Fly's registry

**PostgreSQL on Supabase (Free Tier):**
- Use the Supabase-managed PostgreSQL from Part 4
- The connection string is available in Supabase dashboard under Settings → Database → Connection string (use the pooler URL for serverless deployments)

**Redis on Upstash (Free Tier):**
- Create a free Redis database at upstash.com
- Copy the `REDIS_URL` from the Upstash dashboard
- The free tier provides up to 10,000 commands per day — sufficient for development and small production loads

**Flutter Web on Vercel (Free Tier):**
- Build the Flutter web app: `flutter build web --release`
- Connect the GitHub repository to Vercel
- Configure the build command and output directory in Vercel's project settings
- Set the required environment variables (Supabase URL, anon key, backend URL) in Vercel's environment variable settings
- Deploy automatically on every push to `main`

### 8.3 Option C: Kubernetes

For production environments requiring high availability and horizontal scaling.

**Prerequisites:**
- A Kubernetes cluster (free options: k3s self-hosted on a VPS, or the free tier of some managed Kubernetes providers during trial periods)
- `kubectl` configured to connect to the cluster
- NGINX Ingress Controller installed in the cluster (free, from the Kubernetes community)
- cert-manager installed for automated TLS certificate management with Let's Encrypt (free)

**Kubernetes Manifests (`infra/k8s/`):**
- `namespace.yaml` — Creates the `Conceptra` namespace
- `configmap.yaml` — Non-sensitive configuration (allowed origins, log level, environment)
- `secret.yaml` — Template for secrets (actual values injected by CI/CD pipeline or external secret operator)
- `backend-deployment.yaml` — Deployment with 2 replicas, resource requests and limits, liveness and readiness probes pointing to the health endpoints
- `backend-service.yaml` — ClusterIP service exposing port 8000
- `redis-deployment.yaml` and `redis-service.yaml` — Redis deployment
- `postgres-statefulset.yaml` and `postgres-service.yaml` — PostgreSQL StatefulSet with a PersistentVolumeClaim
- `ingress.yaml` — Ingress resource routing `/api/v1/*` to the backend service and `/*` to the Flutter web Nginx service; annotated for cert-manager to issue a Let's Encrypt certificate
- `hpa.yaml` — HorizontalPodAutoscaler for the backend (scales 2–10 replicas based on CPU utilization)

**Deployment:**
Apply manifests using `kubectl apply -f infra/k8s/`. Run migrations as a Kubernetes Job before deploying the main application. Verify all pods reach the `Running` state.

---

## Part 9 — Post-Deployment Checklist

After deploying to production for the first time, verify the following before announcing the platform to users:

**Functional Verification:**
- Health endpoint returns HTTP 200
- A new user can register and log in via email/password
- A new user can log in via Google OAuth
- The module list loads for an authenticated student
- A student can run a simulation and see a result and graph
- Simulation sessions are persisted in the database
- A teacher can create and publish a module
- An admin can view the audit log

**Security Verification:**
- All HTTP traffic redirects to HTTPS
- Security response headers are present (verify with securityheaders.com — free)
- The `/metrics` endpoint is not accessible from the public internet
- JWT tokens expire after 1 hour (verify by waiting or decoding the JWT)
- An unauthenticated request to a protected endpoint returns 401

**Performance Verification:**
- Run a basic Locust load test from a separate machine
- Verify P95 latency is within the targets defined in spec.md
- Check Prometheus metrics for error rates

**Observability Verification:**
- Logs appear in the configured log destination in JSON format with correlation IDs
- Prometheus is scraping the `/metrics` endpoint (internal access only)
- Grafana dashboard shows live request metrics

---

## Part 10 — Observability and Monitoring Setup

### 10.1 Prometheus Setup

If self-hosting Prometheus (free):
- Deploy Prometheus in Docker Compose or Kubernetes using the official Prometheus Docker image
- Configure `prometheus.yml` with a scrape job targeting the backend's `/metrics` endpoint (internal network access only)
- Set a 15-day retention period

### 10.2 Grafana Setup

Deploy Grafana OSS (free) alongside Prometheus:
- Add Prometheus as a data source in Grafana
- Import the community dashboard for FastAPI metrics (search Grafana's dashboard marketplace — free)
- Create custom panels for Conceptra-specific metrics (simulation count, cache hit rate, active users)
- Configure alert rules with notification channels (email via SMTP or Slack webhook — both free)

### 10.3 Log Management

For development and small production, structured JSON logs written to stdout (captured by Docker) are sufficient. For larger production:
- Configure Docker logging driver to forward logs to a log aggregation service
- Loki (free, open-source) + Grafana provides a free ELK-alternative stack for log querying
- Alternatively, Vector (free, open-source) can ship logs to any destination

### 10.4 Alerting Thresholds (Recommended Baseline)

| Alert | Condition | Severity |
|---|---|---|
| High error rate | 5xx response rate > 1% over 5 minutes | Critical |
| High latency | P95 latency > 1 second over 5 minutes | Warning |
| Backend down | Health check fails for 2 consecutive minutes | Critical |
| Database connection failure | DB connectivity check fails | Critical |
| Redis connection failure | Redis PING fails for 5 minutes | Warning |
| Low cache hit rate | Cache hit rate < 50% over 15 minutes | Info |
| High memory usage | Container memory > 80% of limit | Warning |

---

## Part 11 — Security Hardening Checklist

Before the v1.0 production launch:

- All secrets are stored in environment variables and never in the repository
- `.gitignore` excludes `.env` files; verify with `git log -- .env` that no secrets have been committed
- The Supabase JWT secret is rotated after the initial development period
- Docker containers run as non-root users (verify with `docker inspect <container>`)
- Production dependencies are pinned to exact versions in `requirements.txt`
- `pip-audit` reports zero high-severity CVEs
- `flutter pub outdated` shows no critical security updates pending
- CORS is restricted to explicit production origins only
- Rate limiting is active and verified by sending rapid requests and observing 429 responses
- The admin audit log captures user role changes, module creation, and user deactivation
- TLS certificate is valid and auto-renews (verify with an expiry monitoring tool — UptimeRobot has a free tier)
- Database backups are running daily and a restore has been tested

---

## Part 12 — Common Troubleshooting

| Symptom | Likely Cause | Resolution |
|---|---|---|
| Backend returns 401 for all requests | Supabase JWT secret mismatch | Verify `SUPABASE_JWT_SECRET` in `.env` matches the value in Supabase dashboard Settings → API → JWT Settings |
| `asyncpg.InvalidCatalogNameError` | Database does not exist | Create the database manually or verify `POSTGRES_DB` in Docker Compose matches `DATABASE_URL` |
| Flutter app cannot reach backend API | CORS configuration | Verify the Flutter web origin is listed in `ALLOWED_ORIGINS` in the backend `.env` |
| Alembic migration fails with `relation already exists` | Migration applied twice or out of order | Check `alembic_version` table; use `alembic stamp head` cautiously after investigating |
| Redis connection refused | Redis service not started | Start Redis service; verify `REDIS_URL` is correct; check Docker network connectivity |
| Supabase OAuth redirect fails | Redirect URL not configured | Add the redirect URL to Supabase → Authentication → URL Configuration |
| Flutter web loads but API calls return 404 | API base URL configured incorrectly | Verify `apiBaseUrl` in `lib/core/env.dart` and that the backend is reachable at that URL |
| Prometheus metrics endpoint unreachable internally | Incorrect scrape target in `prometheus.yml` | Verify the backend service name and port in the Prometheus scrape configuration match the Docker Compose service name |
| Flutter `flutter_secure_storage` throws on web | Secure storage not supported on web without configuration | Use `flutter_secure_storage` with the `WebOptions` parameter configured for web-compatible storage |
| Offline sync queue not replaying | Connectivity provider not detecting reconnection | Verify `connectivity_plus` permissions are granted; test with a real device rather than an emulator |

---

*This implementation guide is a living document. Update it with new findings, additional troubleshooting steps, and refined instructions as the project evolves across phases.*
