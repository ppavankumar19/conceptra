# Conceptra — System Specification

**Version:** 1.0.0  
**Status:** Draft  
**Last Updated:** 2026  
**Author:** Sandeep Bangaru  

---

## 📑 Table of Contents

- [1. Purpose and Scope](#1-purpose-and-scope)
- [2. System Architecture](#2-system-architecture)
- [3. Authentication and Authorization](#3-authentication-and-authorization)
- [4. Data Models and Schema](#4-data-models-and-schema)
- [5. API Surface Overview](#5-api-surface-overview)
- [6. Caching Strategy](#6-caching-strategy)
- [7. Security Model](#7-security-model)
- [8. Non-Functional Requirements](#8-non-functional-requirements)
- [9. Performance Targets](#9-performance-targets)
- [10. Compliance and Data Privacy Notes](#10-compliance-and-data-privacy-notes)
- [11. Error Handling Standards](#11-error-handling-standards)
- [12. Versioning Strategy](#12-versioning-strategy)

---

## 1. Purpose and Scope

This document specifies the technical requirements of the Conceptra Interactive Education Visualization System. It is intended for backend engineers, frontend engineers, DevOps personnel, and security reviewers. It defines the contract between system components and establishes the non-negotiable quality gates for production readiness.

The specification covers:
- System-level architecture and component responsibilities
- Authentication flows and authorization model
- Database schema and data model definitions
- Full API endpoint inventory with request/response shape summaries
- Caching architecture and invalidation rules
- Security requirements and threat model
- Non-functional and performance requirements
- Compliance considerations

---

## 2. System Architecture

### 2.1 Component Overview

| Component | Technology | Role |
|---|---|---|
| Flutter App | Flutter 3.x | Primary client (mobile + web) |
| FastAPI Backend | Python 3.11+ / FastAPI 0.110+ | REST API and computation engine |
| PostgreSQL | PostgreSQL 15+ | Persistent, relational data store |
| Redis | Redis 7+ | Caching, rate limiting, session data |
| Supabase Auth | Supabase (free tier) | OAuth 2.0 identity provider, JWT issuance |
| Nginx | Nginx stable | Reverse proxy, TLS termination, static hosting |
| Prometheus | Prometheus 2.x | Metrics collection |
| Grafana | Grafana OSS | Metrics visualization and alerting |
| OpenTelemetry Collector | OTEL 0.x | Distributed trace aggregation |

### 2.2 Communication Protocols

- **Client ↔ Backend:** HTTPS (REST) for all data operations; WebSocket (WSS) for real-time simulation updates where required
- **Backend ↔ PostgreSQL:** TCP via SQLAlchemy async driver (asyncpg)
- **Backend ↔ Redis:** TCP via aioredis async client
- **Backend ↔ Supabase:** HTTPS for token verification (JWKS endpoint)
- **Internal services:** Docker internal network (bridge mode in dev, ClusterIP in Kubernetes)

### 2.3 Deployment Topology

```
Internet
    │
    ▼
[Nginx — TLS Termination + Reverse Proxy]
    │
    ├──► /api/v1/*  ──► [FastAPI — Uvicorn/Gunicorn Workers]
    │                         │
    │                    ┌────┴───────┐
    │                    │            │
    │               [PostgreSQL]  [Redis]
    │
    └──► /*  ──► [Flutter Web (Static Build — Nginx)]
```

---

## 3. Authentication and Authorization

### 3.1 Identity Provider — Supabase

Conceptra delegates all authentication to Supabase Auth (free tier). Supabase handles:
- User registration and login (email/password)
- OAuth 2.0 social login (Google, GitHub)
- JWT issuance and refresh token rotation
- Password reset and email verification flows

The backend does **not** store passwords. It only stores the Supabase `user_id` (UUID) as a foreign key reference.

### 3.2 Authentication Flow

**Standard OAuth / Email Login Flow:**

1. Flutter app initiates login via Supabase Flutter SDK.
2. Supabase authenticates the user and returns an access token (JWT) and a refresh token.
3. The JWT is stored securely in Flutter's secure storage (flutter_secure_storage).
4. Every API request to the FastAPI backend includes the JWT in the `Authorization: Bearer <token>` header.
5. FastAPI middleware validates the JWT signature using Supabase's JWKS public key endpoint.
6. On validation success, the middleware injects the decoded user payload (user_id, role) into the request context.
7. The refresh token is used by the Flutter Supabase SDK to obtain new access tokens transparently before expiry.

**Token Expiry:** Access tokens expire after 1 hour. Refresh tokens expire after 7 days with rotation enabled.

### 3.3 Role-Based Access Control (RBAC)

Roles are stored in the `user_profiles` table and embedded in the JWT via Supabase custom claims (configured through Supabase database hooks).

| Role | Permissions |
|---|---|
| `student` | View simulations, run computations, view own progress |
| `teacher` | All student permissions + manage content, view class analytics |
| `admin` | All teacher permissions + manage users, view audit logs, configure system |

**RBAC Enforcement:** FastAPI route handlers use dependency injection to enforce role requirements. A request failing RBAC returns HTTP 403 with a structured error body.

### 3.4 OAuth Scopes

The application requests the minimum required OAuth scopes:
- `openid` — Identity claims
- `email` — Email address (required for account creation)
- `profile` — Display name and avatar

No write scopes to external services are requested. The platform does not post on behalf of users to any connected OAuth provider.

---

## 4. Data Models and Schema

### 4.1 Entity Relationship Summary

```
user_profiles (1) ──────── (M) simulation_sessions
user_profiles (1) ──────── (M) progress_records
user_profiles (1) ──────── (M) audit_logs
simulation_modules (1) ─── (M) simulation_sessions
simulation_modules (1) ─── (M) module_parameters
```

### 4.2 Table Definitions

#### `user_profiles`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Internal user identifier |
| `supabase_user_id` | UUID | UNIQUE, NOT NULL | Supabase Auth user ID (foreign reference) |
| `display_name` | VARCHAR(100) | NOT NULL | User's display name |
| `email` | VARCHAR(255) | UNIQUE, NOT NULL | User's email address |
| `role` | VARCHAR(20) | NOT NULL, DEFAULT 'student' | RBAC role (student/teacher/admin) |
| `class_grade` | SMALLINT | NULLABLE | Student class grade (6–12) |
| `preferred_language` | VARCHAR(10) | DEFAULT 'en' | Locale code for i18n |
| `is_active` | BOOLEAN | DEFAULT TRUE | Soft delete / deactivation flag |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Account creation timestamp |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Last profile update timestamp |

#### `simulation_modules`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Module identifier |
| `title` | VARCHAR(200) | NOT NULL | Human-readable title |
| `description` | TEXT | NULLABLE | Module description |
| `subject` | VARCHAR(50) | NOT NULL | Subject category (physics/math/chemistry) |
| `topic` | VARCHAR(100) | NOT NULL | Topic name (e.g., speed, acceleration) |
| `difficulty` | VARCHAR(20) | NOT NULL, DEFAULT 'beginner' | Difficulty level (beginner/intermediate/advanced) |
| `grade_min` | INTEGER | NOT NULL, DEFAULT 6 | Minimum recommended grade |
| `grade_max` | INTEGER | NOT NULL, DEFAULT 12 | Maximum recommended grade |
| `is_published` | BOOLEAN | DEFAULT FALSE | Controls visibility to students |
| `created_by` | UUID | FK → user_profiles.id, NULLABLE | Author (teacher/admin) |
| `module_metadata` | JSONB | NULLABLE | Additional metadata (formulas, config, etc.) |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Module creation timestamp |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Last modification timestamp |

#### `module_parameters`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Parameter identifier |
| `module_id` | UUID | FK → simulation_modules.id, CASCADE | Parent module |
| `name` | VARCHAR(100) | NOT NULL | Parameter name (e.g., distance, time) |
| `label` | VARCHAR(200) | NOT NULL | Display label (supports i18n key) |
| `unit` | VARCHAR(50) | NULLABLE | Unit of measurement (m, s, N, etc.) |
| `param_type` | VARCHAR(20) | NOT NULL, DEFAULT 'float' | Parameter type (float/int/select) |
| `min_value` | FLOAT | NULLABLE | Slider minimum value |
| `max_value` | FLOAT | NULLABLE | Slider maximum value |
| `step` | FLOAT | NULLABLE | Slider step increment |
| `default_value` | FLOAT | NULLABLE | Default slider value |
| `is_required` | BOOLEAN | NOT NULL, DEFAULT TRUE | Whether parameter is required |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Parameter creation timestamp |

#### `simulation_sessions`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Session identifier |
| `user_id` | UUID | FK → user_profiles.id, CASCADE | User who ran the session |
| `module_id` | UUID | FK → simulation_modules.id, CASCADE | Module executed |
| `input_parameters` | JSONB | NOT NULL | Snapshot of slider values at execution |
| `result` | JSONB | NOT NULL | Computed output values |
| `explanation` | JSONB | NULLABLE | Generated explanation (formula, substitution, conclusion) |
| `graph_data` | JSONB | NULLABLE | Computed data points for chart rendering |
| `locale` | VARCHAR(10) | NOT NULL, DEFAULT 'en' | Locale used for explanation text |
| `duration_ms` | INTEGER | NULLABLE | Time spent in the session (milliseconds) |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Timestamp of session execution |

#### `progress_records`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Record identifier |
| `user_id` | UUID | FK → user_profiles.id, CASCADE | Student user |
| `module_id` | UUID | FK → simulation_modules.id, CASCADE | Completed module |
| `sessions_count` | INTEGER | NOT NULL, DEFAULT 0 | Number of sessions on this module |
| `completion_percentage` | FLOAT | NOT NULL, DEFAULT 0.0 | Percentage completion |
| `last_session_at` | TIMESTAMPTZ | NULLABLE | Most recent session timestamp |
| `extra_data` | JSONB | NULLABLE | Additional progress metadata |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Record creation timestamp |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Last update timestamp |

#### `audit_logs`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Log entry identifier |
| `actor_id` | UUID | FK → user_profiles.id, NULLABLE | User who performed the action |
| `action` | VARCHAR(100) | NOT NULL | Action identifier (e.g., USER_CREATED) |
| `resource_type` | VARCHAR(100) | NULLABLE | Affected resource type |
| `resource_id` | VARCHAR(255) | NULLABLE | Affected resource identifier |
| `log_metadata` | JSONB | NULLABLE | Additional context (diff, old/new values) |
| `ip_address` | VARCHAR(45) | NULLABLE | Requester IP address |
| `user_agent` | VARCHAR(500) | NULLABLE | Requester user agent string |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Event timestamp |

### 4.3 Indexes

| Table | Columns | Type | Purpose |
|---|---|---|---|
| `user_profiles` | `supabase_user_id` | UNIQUE B-Tree | JWT-to-profile lookup |
| `user_profiles` | `email` | UNIQUE B-Tree | Email uniqueness check |
| `simulation_sessions` | `user_id` | B-Tree | User history queries |
| `simulation_sessions` | `module_id` | B-Tree | Module usage analytics |
| `simulation_sessions` | `created_at` | B-Tree | Chronological session queries |
| `audit_logs` | `actor_id` | B-Tree | Audit queries by user |
| `audit_logs` | `action` | B-Tree | Audit queries by action type |
| `audit_logs` | `created_at` | B-Tree | Chronological audit log |
| `audit_logs` | `action, created_at` | Composite B-Tree | Action + time queries |
| `progress_records` | `user_id, module_id` | UNIQUE B-Tree | Progress upsert operations |

---

## 5. API Surface Overview

All endpoints are prefixed with `/api/v1`. Authentication is required for all endpoints unless marked as **Public**.

### 5.1 Authentication Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/auth/me` | Required | Returns authenticated user's profile |
| PUT | `/auth/me` | Required | Updates authenticated user's profile |
| POST | `/auth/refresh` | Public | Requests a new access token (handled by Supabase SDK) |

### 5.2 Simulation Module Endpoints

| Method | Path | Auth | Role | Description |
|---|---|---|---|---|
| GET | `/modules` | Required | Any | List all published modules (paginated, filterable) |
| GET | `/modules/{module_id}` | Required | Any | Get module detail including parameters |
| POST | `/modules` | Required | teacher, admin | Create a new simulation module |
| PUT | `/modules/{module_id}` | Required | teacher, admin | Update a module |
| DELETE | `/modules/{module_id}` | Required | admin | Soft-delete a module |
| POST | `/modules/{module_id}/publish` | Required | admin | Publish or unpublish a module |

### 5.3 Simulation Computation Endpoints

| Method | Path | Auth | Role | Description |
|---|---|---|---|---|
| POST | `/simulate` | Required | Any | Run a computation with given parameters, returns result + explanation |
| GET | `/simulate/history` | Required | Any | List current user's simulation session history |
| GET | `/simulate/{session_id}` | Required | Any | Get a specific simulation session |

**POST `/simulate` — Request Shape:**

The request body contains the `module_id` and a map of `parameters` (key-value pairs matching the module's defined parameter names and their slider values). It also accepts an optional `locale` field to request a localized explanation.

**POST `/simulate` — Response Shape:**

The response returns the `session_id`, all `input_parameters` echoed back, the `result` object (computed output values with labels and units), a human-readable `explanation` broken into `formula`, `substitution`, and `conclusion` fields, and a `graph_data` object containing an array of computed data points suitable for rendering a live chart.

### 5.4 Progress Endpoints

| Method | Path | Auth | Role | Description |
|---|---|---|---|---|
| GET | `/progress` | Required | student | Get current user's progress across all modules |
| GET | `/progress/{module_id}` | Required | student | Get progress for a specific module |
| PUT | `/progress/{module_id}` | Required | student | Upsert progress for a module |

### 5.5 Analytics Endpoints

| Method | Path | Auth | Role | Description |
|---|---|---|---|---|
| GET | `/analytics/summary` | Required | teacher, admin | Overall platform usage summary |
| GET | `/analytics/module/{module_id}` | Required | teacher, admin | Per-module usage and completion analytics |
| GET | `/analytics/user/{user_id}` | Required | teacher, admin | Per-student analytics |

### 5.6 Admin Endpoints

| Method | Path | Auth | Role | Description |
|---|---|---|---|---|
| GET | `/admin/users` | Required | admin | List all users (paginated) |
| PUT | `/admin/users/{user_id}/role` | Required | admin | Update a user's role |
| POST | `/admin/users/{user_id}/deactivate` | Required | admin | Deactivate a user account |
| GET | `/admin/audit-logs` | Required | admin | Query the audit log (filterable, paginated) |

### 5.7 Health and Observability Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/health` | Public | Liveness check — returns 200 if service is up |
| GET | `/health/ready` | Public | Readiness check — validates DB and Redis connectivity |
| GET | `/metrics` | Internal | Prometheus metrics scrape endpoint (not exposed publicly) |

### 5.8 Standard Response Envelope

All API responses follow a consistent envelope structure:

**Success Response:**
Contains a `success: true` flag, a `data` object or array with the response payload, and a `meta` object for paginated responses (containing `page`, `page_size`, `total`, `total_pages`).

**Error Response:**
Contains a `success: false` flag, an `error` object with a machine-readable `code` string, a human-readable `message` string, and an optional `details` array for validation errors listing affected `field` and `message` per item.

### 5.9 Pagination

All list endpoints support `page` (default: 1) and `page_size` (default: 20, max: 100) query parameters. Cursor-based pagination may be introduced in v2 for high-volume endpoints.

### 5.10 Filtering and Sorting

The `/modules` endpoint supports query parameters: `subject`, `difficulty_level`, `grade`, `is_published`, `sort_by` (default: `created_at`), and `sort_order` (`asc` or `desc`).

---

## 6. Caching Strategy

### 6.1 Cache Layers

| Layer | Tool | Scope | Description |
|---|---|---|---|
| L1 — In-Process | Python `lru_cache` | Single process | Cache computation function results for identical inputs during a request |
| L2 — Distributed | Redis 7 | All backend instances | Cross-process cache for API responses and expensive computations |
| L3 — Client-Side | Flutter Hive | Device | Offline-first local storage for module definitions and last-known results |

### 6.2 Cache Policies

| Resource | Cache Key Pattern | TTL | Invalidation Trigger |
|---|---|---|---|
| Module list | `modules:list:{filter_hash}` | 5 minutes | Module created, updated, or published |
| Module detail | `modules:detail:{module_id}` | 10 minutes | Module updated or deleted |
| Simulation result | `sim:result:{module_id}:{params_hash}` | 30 minutes | Rarely invalidated (computation is deterministic) |
| User profile | `user:profile:{user_id}` | 5 minutes | User profile updated |
| Analytics summary | `analytics:summary` | 15 minutes | Background job invalidates on schedule |
| Rate limit counter | `ratelimit:{user_id}:{endpoint}` | 60 seconds | Sliding window expiry |

### 6.3 Cache Invalidation

Active invalidation is performed by the FastAPI service layer on write operations. Write operations call Redis `DEL` or `UNLINK` on affected keys immediately after a successful database commit. Background jobs handle invalidation for scheduled refresh cases (e.g., analytics).

### 6.4 Cache Miss Behavior

On a cache miss, the backend computes the result from PostgreSQL or the computation engine, stores the result in Redis with the defined TTL, and then returns the result. Stale-while-revalidate patterns are not used in v1 to maintain simplicity; they may be introduced in v2.

### 6.5 Offline Cache (Flutter — Hive)

The Flutter app persists the following in Hive boxes for offline access:
- All module definitions (refreshed on app foreground with connectivity)
- The last 20 simulation sessions per user
- User profile and progress data

Pending simulation runs created offline are queued in a local Hive sync queue and replayed to the backend once connectivity is restored.

---

## 7. Security Model

### 7.1 Threat Model Summary

| Threat | Mitigation |
|---|---|
| Unauthorized API access | JWT validation on every request; 401 on missing or invalid token |
| Privilege escalation | RBAC enforced server-side; role embedded in JWT custom claim and verified against DB |
| SQL injection | SQLAlchemy parameterized queries exclusively; no raw SQL string formatting |
| XSS | Flutter's rendering model eliminates DOM-based XSS; API responses are JSON only |
| CSRF | Stateless JWT API inherently immune; OAuth state parameter protects redirect flows |
| Token theft | Short-lived access tokens (1h); refresh token rotation; secure storage on device |
| Brute-force / DoS | Redis-backed rate limiting per user per endpoint; Nginx connection rate limiting |
| Man-in-the-middle | TLS required in production; HSTS headers enforced |
| Dependency vulnerabilities | `pip-audit` and `flutter pub outdated` in CI; Dependabot alerts on GitHub |
| Insecure data exposure | No sensitive fields in API responses; audit logs for all admin actions |
| Container vulnerabilities | Non-root users in all containers; minimal base images (python:3.11-slim) |

### 7.2 JWT Validation

The backend uses the `python-jose` library to validate incoming JWTs against the Supabase JWKS endpoint. The validation checks:
- Signature validity using the RS256 public key
- Token expiry (`exp` claim)
- Audience (`aud` claim) matching the configured Supabase project
- Issuer (`iss` claim) matching the Supabase project URL

The JWKS public key is fetched once at startup and cached in-process, with a refresh triggered on key rotation events.

### 7.3 Secrets Management

- In local development, secrets are stored in `.env` files (excluded from Git via `.gitignore`).
- In production (Docker Compose), secrets are injected via environment variables defined outside of version control.
- In Kubernetes deployments, Kubernetes Secrets are used with RBAC restrictions on secret access. The free-tier Doppler CLI may optionally be used to synchronize secrets.
- The `.env.example` file is committed to the repository with placeholder values only, to document required variables without exposing real secrets.

### 7.4 Security Headers

Nginx is configured to set the following response headers in production:

| Header | Value |
|---|---|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` |
| `X-Content-Type-Options` | `nosniff` |
| `X-Frame-Options` | `DENY` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=()` |
| `Content-Security-Policy` | Defined to restrict script/style sources |

---

## 8. Non-Functional Requirements

### 8.1 Reliability

- The backend service must achieve ≥ 99.5% uptime in production during school hours (7:00 AM – 9:00 PM IST).
- Database connection pooling must be configured to handle burst traffic without exhausting connections.
- Redis failures must degrade gracefully — the system must continue functioning (with lower performance) if Redis is temporarily unavailable.
- Database backups must run daily with a minimum retention of 7 days.

### 8.2 Scalability

- The FastAPI backend must be stateless, enabling horizontal scaling by adding more instances behind a load balancer.
- Database reads must be offloaded to a read replica in production if the query volume exceeds the primary's capacity.
- Redis must support cluster mode configuration for high-availability in Kubernetes deployments.

### 8.3 Maintainability

- All public API changes must be versioned and backward-compatible within a major version.
- Database schema changes must be managed exclusively through Alembic migrations — no manual schema changes in production.
- Code coverage must be maintained above 80% for backend and 70% for frontend.
- All API endpoints must be documented in OpenAPI 3.x format (auto-generated by FastAPI).

### 8.4 Usability

- The Flutter UI must support both light and dark themes, switchable by the user.
- All interactive elements must be reachable by keyboard and screen reader.
- The application must function on devices with a minimum screen width of 320px (mobile) and 1024px (desktop/web).
- First meaningful paint on the web target must occur within 3 seconds on a 4G connection.

### 8.5 Portability

- The backend Docker image must run on AMD64 and ARM64 architectures.
- The Flutter app must target Android 6.0+, iOS 13.0+, and modern web browsers (Chrome, Firefox, Safari, Edge latest two major versions).

---

## 9. Performance Targets

| Metric | Target | Measurement Method |
|---|---|---|
| Simulation computation latency (P95) | < 200ms | Prometheus histogram |
| API response time — cached (P95) | < 50ms | Prometheus histogram |
| API response time — uncached (P95) | < 500ms | Prometheus histogram |
| Database query time (P95) | < 100ms | SQLAlchemy instrumentation |
| Flutter app cold start (mobile) | < 2 seconds | Manual testing |
| Flutter web First Contentful Paint | < 3 seconds on 4G | Lighthouse |
| Cache hit rate (Redis) | ≥ 70% | Prometheus counter |
| Concurrent users supported (single backend instance) | 500 | Load test (Locust) |

---

## 10. Compliance and Data Privacy Notes

- **Student Data:** Student simulation sessions and progress records are associated with user IDs. No personally identifying information beyond email and display name is stored.
- **Data Residency:** The PostgreSQL instance should be hosted in the same geographic region as the primary user base to minimize latency and address data residency considerations.
- **Data Retention:** Simulation session records are retained indefinitely for analytics. Audit logs are retained for a minimum of 1 year. User accounts may be deactivated (soft-deleted) and fully deleted on request.
- **COPPA / DPDP Consideration:** As the platform may be used by minors, no third-party advertising trackers or analytics SDKs that profile users are permitted. The India Digital Personal Data Protection Act (DPDP) 2023 requirements for minor users should be reviewed before production launch.
- **OAuth Data Minimization:** Only the minimum required OAuth scopes are requested. Social provider data (avatar, name) is stored only if explicitly provided by the user.

---

## 11. Error Handling Standards

- All unhandled exceptions in FastAPI are caught by a global exception handler that logs the full traceback (with correlation ID) and returns a sanitized 500 response to the client.
- Validation errors (HTTP 422) return a structured list of field-level errors using the standard response envelope.
- The client must never receive raw Python tracebacks, database error messages, or internal system paths.
- Network errors in the Flutter client are caught by Dio interceptors and presented to the user via a standardized error widget with an appropriate retry option.

---

## 12. Versioning Strategy

- The API is versioned via URL path prefix: `/api/v1`, `/api/v2`, etc.
- A new major version is introduced only for breaking changes (removed fields, changed response shapes, authentication model changes).
- Both the current and previous major versions are supported simultaneously for a minimum of 3 months after a new major version is released.
- Deprecation notices are communicated via a `Deprecation` response header and in the OpenAPI documentation.
- The Flutter app checks the minimum supported API version at startup and prompts the user to update if the installed version is below the supported threshold.
