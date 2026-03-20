# ADR 001 — Technology Stack Selection

| Field       | Value                          |
|-------------|-------------------------------|
| **Status**  | Accepted                       |
| **Date**    | 2025-01-15                     |
| **Deciders**| Engineering Lead, Product Lead |
| **Ticket**  | EDU-001                        |

---

## Context

Conceptra is an interactive education visualisation platform that must deliver:

1. **Rich, animated visualisations** of complex concepts (data structures, algorithms, physics simulations, maths).
2. **Cross-platform reach** — web-first, with a path to native iOS/Android without a separate codebase.
3. **A collaborative backend** — user progress tracking, lesson authoring, real-time multiplayer sessions.
4. **Fast iteration** in a small team during MVP, then scalable to thousands of concurrent users.

We evaluated multiple stacks before settling on the choices documented here.

---

## Decision

### Frontend: Flutter (Web + Mobile)

**Chosen over:** React + TypeScript, Vue.js, SwiftUI + Jetpack Compose (separate codebases).

**Rationale:**

- Flutter's Skia/Impeller rendering engine runs at 60 fps on web via CanvasKit, which is essential for smooth animation of visualisations (sorting algorithms, graph traversal, physics bodies).
- A single Dart codebase targets web, iOS, Android, and desktop — reducing maintenance surface.
- Flutter's widget-tree mental model aligns well with composable visualisation scenes.
- `flutter_animate`, `fl_chart`, `rive`, and custom `CustomPainter` give us a rich animation toolkit without a JavaScript bundle size penalty.
- Dart's sound null-safety reduces runtime crashes in complex state management.

**Trade-offs accepted:**

- CanvasKit WASM initial load (~2 MB gzipped) is larger than a typical JS SPA. Mitigated with a loading screen and HTTP/2 push.
- The Dart ecosystem is smaller than JS/Python. Mitigated by leveraging the mature `pub.dev` ecosystem and wrapping JS interop where needed.
- SEO is limited for Flutter web. Conceptra's authenticated content does not require search indexing, so this is acceptable.

### Backend: FastAPI (Python 3.11)

**Chosen over:** Django REST Framework, Node.js/Express, Go (Gin/Echo), Ruby on Rails.

**Rationale:**

- Python is the lingua franca for the scientific/educational content domain (numpy, sympy, matplotlib for server-side computation).
- FastAPI's async-first design (asyncio + asyncpg + SQLAlchemy 2.0 async) handles many concurrent WebSocket connections for real-time sessions.
- Automatic OpenAPI/Swagger docs accelerate frontend-backend integration.
- Pydantic v2 provides fast validation and clear contracts between layers.
- The team has existing Python expertise; ramp-up time is minimal.
- `pytest-asyncio` + `httpx` give a first-class async testing story.

**Trade-offs accepted:**

- Python is slower than Go or Rust. Mitigated by async I/O, connection pooling, Redis caching, and the ability to offload CPU-heavy computation to Celery workers.
- GIL limits CPU parallelism. Addressed with gunicorn multi-process deployment.

### Database: PostgreSQL 15

**Chosen over:** MySQL 8, MongoDB, CockroachDB.

**Rationale:**

- PostgreSQL's JSONB columns let us store flexible lesson/visualisation config alongside structured relational data (users, progress, courses).
- ACID guarantees are essential for financial transactions (subscriptions) and progress tracking.
- pgvector extension enables future semantic search over lesson content.
- Alembic provides robust schema migrations with rollback support.
- Deep support in Supabase (chosen for auth — see ADR 002) means shared infrastructure.

**Trade-offs accepted:**

- Operational overhead of a stateful database. Mitigated by managed Postgres via Supabase (or RDS in AWS) for production.

### Cache / Message Broker: Redis 7

**Chosen over:** Memcached, RabbitMQ (for queueing), in-process LRU.

**Rationale:**

- Redis serves double duty: session/response caching and Celery task broker for async jobs (email, PDF generation, compute-heavy simulations).
- Redis Pub/Sub is used for real-time presence and collaborative session state.
- Redis Streams provide a durable event log for user activity analytics.
- Persistent AOF + RDB snapshots protect against data loss.

### Hosting / Infrastructure: Docker + Kubernetes (production), Docker Compose (development)

**Rationale:**

- Docker Compose gives every developer a reproducible local stack with a single `docker compose up`.
- Kubernetes provides horizontal scaling, self-healing, and rolling deployments without downtime.
- GitHub Actions CI/CD pipelines build and push images to GHCR, then deploy via SSH (MVP) or `kubectl` (scale phase).

---

## Consequences

### Positive

- Single Flutter codebase ships web + mobile simultaneously.
- FastAPI + async PostgreSQL scales to high concurrency without vertical scaling first.
- Docker-based workflow means production parity in development.
- All chosen tools have active maintenance and commercial backing.

### Negative / Risks

- **Flutter web CanvasKit load time** requires a loading screen and CDN delivery strategy.
- **Team must learn Dart** if they have a JavaScript background; estimated 2-week ramp.
- **Kubernetes operational complexity** deferred to scale phase; MVP uses Docker Compose on a VM.
- **Python performance ceiling**: if visualisation server-side computation becomes a bottleneck, a dedicated microservice in Go or Rust may be needed.

---

## Alternatives Considered

| Option | Rejected Because |
|--------|-----------------|
| React + TypeScript (frontend) | Canvas/WebGL animation requires additional libraries (Three.js, Konva) with larger bundle; no mobile path |
| Django REST Framework | Sync-first; WebSocket support bolted on; heavier than needed for an API-only backend |
| MongoDB | Lack of ACID transactions complicates progress tracking; joins are awkward |
| Serverless (Lambda/Cloud Run) | Cold starts unacceptable for real-time sessions; WebSocket lifetime limits |
| Next.js (SSR) | SEO not required; adds complexity without benefit for authenticated SPA |
