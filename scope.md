# Conceptra — Project Scope Document

**Version:** 1.0.0  
**Status:** Approved  
**Last Updated:** 2026  
**Author:** Sandeep Bangaru  

---

## 📑 Table of Contents

- [1. Project Overview](#1-project-overview)
- [2. Goals and Objectives](#2-goals-and-objectives)
- [3. Stakeholders](#3-stakeholders)
- [4. In-Scope Items](#4-in-scope-items)
- [5. Out-of-Scope Items](#5-out-of-scope-items)
- [6. Phased Milestones](#6-phased-milestones)
  - [Phase 0 — Foundation (MVP)](#phase-0--foundation-mvp)
  - [Phase 1 — Beta (v0.5)](#phase-1--beta-v05)
  - [Phase 2 — General Availability (v1.0)](#phase-2--general-availability-v10)
  - [Phase 3 — Advanced (v1.5)](#phase-3--advanced-v15)
  - [Phase 4 — Scale (v2.0)](#phase-4--scale-v20)
- [7. Success Criteria](#7-success-criteria)
- [8. Assumptions and Constraints](#8-assumptions-and-constraints)
- [9. Risks and Mitigations](#9-risks-and-mitigations)
- [10. Acceptance Tests](#10-acceptance-tests)
- [11. Change Management](#11-change-management)

---

## 1. Project Overview

Conceptra is an interactive education visualization system for students in Classes 6–12 in India. The platform enables students to manipulate simulation parameters via sliders and observe real-time animated and graphical outputs, transforming passive formula memorization into active, experiential understanding.

The system is a full-stack product comprising a Flutter mobile and web frontend, a Python FastAPI backend, PostgreSQL for data persistence, Redis for caching, and Supabase as the authentication provider.

---

## 2. Goals and Objectives

### Primary Goals

- Increase student engagement with science and mathematics concepts by providing interactive, visual simulations.
- Reduce the effort required for teachers to create and manage simulation content.
- Provide administrators with usage analytics and audit capabilities.
- Deliver a secure, accessible, and production-ready platform that can be deployed on free or low-cost infrastructure.

### Measurable Objectives

| Objective | Target | Measurement |
|---|---|---|
| Student engagement rate | ≥ 70% of registered students complete at least 3 simulations per week | Analytics dashboard |
| Content availability | ≥ 10 published simulation modules at v1.0 launch | Module count in DB |
| Platform reliability | ≥ 99.5% uptime during school hours | Prometheus / Grafana |
| Accessibility compliance | WCAG 2.1 AA on all core screens | Accessibility audit |
| Test coverage | ≥ 80% backend, ≥ 70% frontend | CI coverage reports |

---

## 3. Stakeholders

| Stakeholder | Role | Interest |
|---|---|---|
| Students (Classes 6–12) | End Users | Engaging, understandable learning experience |
| Teachers | Content Creators + Supervisors | Easy content management, class analytics |
| School Administrators | Platform Administrators | User management, security, compliance |
| Developer (Sandeep Bangaru) | Product Owner + Engineer | Technical quality, feature delivery |
| Open Source Contributors | Engineers | Code quality, documentation clarity |

---

## 4. In-Scope Items

### Frontend (Flutter)

- Cross-platform Flutter application targeting Android, iOS, and web
- Authentication screens (login, register, password reset) via Supabase OAuth flows
- Simulation module browser (list, filter, search)
- Interactive simulation screen with slider controls and real-time output
- Animated output visualization (charts, motion graphics)
- Student progress dashboard (per module completion and history)
- Teacher content management screens (create/edit modules and parameters)
- Admin user management screen (list users, change roles, deactivate)
- Admin audit log viewer
- Light and dark theme support
- Offline mode with Hive local storage and background sync queue
- Localization support for English, Hindi, and Telugu
- Accessibility: semantic labels, screen reader support, keyboard navigation
- Push notification display (FCM, in-app only — not scheduling)

### Backend (FastAPI)

- RESTful API v1 as specified in `spec.md`
- JWT-based authentication middleware (Supabase JWT validation)
- RBAC enforcement via FastAPI dependency injection
- Simulation computation engine (Physics: Speed, Distance, Time; Force, Acceleration)
- Step-by-step explanation generator (template-based for MVP, AI-powered in v1.5)
- Graph data point generation for client-side chart rendering
- Redis-backed caching layer for module and computation responses
- Redis-backed rate limiting
- Structured JSON logging with correlation IDs
- Prometheus metrics endpoint
- OpenTelemetry tracing instrumentation
- Alembic database migrations
- Background tasks for analytics aggregation

### Infrastructure and DevOps

- Docker and Docker Compose configuration for local development
- Production Docker Compose configuration with Nginx reverse proxy
- GitHub Actions CI/CD pipelines (lint, test, build, deploy)
- Kubernetes manifests (provided but deployment is optional)
- Security scanning in CI (pip-audit, flutter pub outdated)
- Free-tier deployment guides for Fly.io (backend), Supabase (DB + Auth), Upstash (Redis)

### Documentation

- `readme.md` — Setup, architecture, deployment, contributing
- `spec.md` — System requirements, API surface, data schema, security model
- `scope.md` — This document
- `implementation.md` — Step-by-step build and deployment guide
- OpenAPI 3.x auto-generated docs via FastAPI's `/docs` endpoint
- Architecture Decision Records (ADRs) in `docs/adr/`

---

## 5. Out-of-Scope Items

The following items are explicitly excluded from the current project scope. They may be considered for future versions but must not be included in any phase without a formal scope change.

| Out-of-Scope Item | Reason / Notes |
|---|---|
| Native desktop application (macOS, Windows, Linux) | Flutter web covers desktop browser use; native apps are a future consideration |
| Video streaming or screen recording features | Infrastructure cost and complexity exceed current project constraints |
| In-platform video calling or live tutoring | Requires third-party video SDK integration; deferred to v3+ |
| Payment processing or subscription billing | Monetization is not a current project goal |
| Third-party advertising or ad networks | Incompatible with student data privacy requirements |
| Custom LMS integrations (Google Classroom, Moodle) | API connectors deferred to v2+ |
| Chemistry and Biology simulation modules | Only Physics and Mathematics are primary scope through v1.0; basic Chemistry (Ideal Gas Law) included as a preview |
| AI-generated simulation content creation | Teacher-created content only in v1.0; AI assistance planned for v1.5 |
| Multi-tenant / multi-school architecture | Single-tenant deployment in scope; multi-tenancy deferred to v2.0 |
| Native mobile push notification scheduling | Display only in scope; scheduling UI deferred |
| Blockchain-based credential or certificate issuance | Not applicable to current use case |
| Real-time collaborative simulation (multiple simultaneous users on one session) | Infrastructure complexity deferred to v2+ |
| Automated curriculum mapping | Deferred to v2+ |
| Parent / guardian portal | Deferred to v2+ |

---

## 6. Phased Milestones

### Phase 0 — Foundation (MVP)

**Target Duration:** 6 weeks  
**Goal:** Deliver a functional end-to-end prototype demonstrating the core interactive simulation experience with basic authentication.

**Deliverables:**

- Project repository initialized with monorepo structure
- Docker Compose local development stack (PostgreSQL, Redis, FastAPI, Flutter web)
- Supabase Auth integration (email/password login only)
- Basic user profile creation on first login
- One simulation module: **Speed Calculation** (Distance / Time) and additional Physics, Math, and Chemistry seed modules
- Slider-based input UI with computed output display
- Basic graph (Distance–Time curve) rendered client-side
- Step-by-step explanation display (static template)
- User's simulation history stored in PostgreSQL
- GitHub Actions CI pipeline (lint + unit tests)

**Exit Criteria:**

- A user can register, log in, run the Speed simulation, see a result and graph, and have the session stored in the database
- All CI checks pass on the main branch
- Backend test coverage ≥ 60%

---

### Phase 1 — Beta (v0.5)

**Target Duration:** 8 weeks after MVP  
**Goal:** Expand the subject module library, introduce teacher content management, and implement offline mobile support.

**Deliverables:**

- Additional Physics modules: **Acceleration**, **Force (Newton's Second Law)**
- Mathematics module: **Linear Equations** (graph of y = mx + c)
- Teacher role: module creation and parameter configuration UI
- Teacher role: class analytics dashboard (module usage, student completion)
- Admin role: user management and role assignment
- Offline support: Hive local storage + sync queue for simulation sessions
- Redis caching layer for module definitions and computation results
- Dark/light theme toggle
- Localization: English and Hindi
- Full Dockerfile and docker-compose.prod.yml for production
- GitHub Actions CD pipeline (build + push Docker image)

**Exit Criteria:**

- A teacher can create a new module and publish it
- A student can run simulations offline and see them synced on next connection
- Admin can change a user's role and view the audit log for that action
- Backend test coverage ≥ 75%

---

### Phase 2 — General Availability (v1.0)

**Target Duration:** 10 weeks after Beta  
**Goal:** Achieve production-readiness with full RBAC, audit logging, accessibility compliance, observability, and a polished UI.

**Deliverables:**

- Full RBAC enforcement across all API endpoints and UI screens
- Comprehensive audit logging (all write operations logged to `audit_logs`)
- Admin audit log viewer (filterable, paginated)
- Student progress tracking (per-module completion percentage, mastery threshold)
- Push notification display (in-app banners for module publication events)
- WCAG 2.1 AA accessibility audit and remediation
- Telugu language localization
- Prometheus metrics endpoint + Grafana dashboard configuration
- OpenTelemetry distributed tracing setup
- Structured JSON logging with correlation IDs
- Security scan integration in CI (pip-audit)
- Performance load test results documented (Locust, 500 concurrent users)
- Full OpenAPI documentation reviewed and published
- Kubernetes manifests provided (optional deployment)
- Complete `readme.md`, `spec.md`, `scope.md`, `implementation.md`

**Exit Criteria:**

- All acceptance tests in Section 10 pass
- Backend test coverage ≥ 80%, frontend coverage ≥ 70%
- WCAG 2.1 AA audit shows zero critical issues
- Load test demonstrates ≤ 200ms P95 latency at 500 concurrent users
- Security scan shows zero high-severity known vulnerabilities

---

### Phase 3 — Advanced (v1.5)

**Target Duration:** 12 weeks after v1.0  
**Goal:** Introduce AI-powered explanations, gamification, and advanced student analytics.

**Deliverables:**

- AI-powered step-by-step explanation engine (LLM API integration — free tier or open model)
- Student gamification: points, badges, leaderboard per class
- Advanced student analytics: learning velocity, mastery curves, time-on-task
- Teacher dashboard: class-level heatmaps and struggling-student alerts
- Full-text search across simulation modules
- Email notification system (welcome email, weekly progress digest) using free SMTP provider
- Module versioning (teachers can update modules without breaking existing session history)
- API v2 planning and deprecation notice for v1 features

**Exit Criteria:**

- AI explanation engine returns contextually accurate explanations for all Physics and Math modules
- Gamification elements are visible and functional for students
- Advanced analytics are accessible to teachers and admins

---

### Phase 4 — Scale (v2.0)

**Target Duration:** TBD  
**Goal:** Multi-tenant support, Chemistry simulations, LMS integrations, and real-time collaboration.

**Deliverables:**

- Multi-school / multi-tenant data isolation architecture
- Chemistry simulation module (Acid–Base reactions, periodic table)
- Google Classroom integration (optional module sync)
- Real-time collaborative simulation sessions (WebSocket, shared session state)
- Parent / guardian portal with read-only student progress view
- Native mobile push notification scheduling
- Custom curriculum mapping interface
- API v2 with cursor-based pagination and GraphQL exploration endpoint

**Exit Criteria:**

- Multi-tenant data isolation verified by penetration test
- Chemistry module passes teacher content review
- Real-time collaboration supports ≥ 10 simultaneous users per session without data inconsistency

---

## 7. Success Criteria

The project is considered successful when all of the following are true:

- The v1.0 platform is deployed and accessible to real students and teachers in at least one school
- ≥ 70% of active students complete at least 3 simulation sessions per week over a 4-week observation period
- Platform uptime is ≥ 99.5% over any rolling 30-day window during school hours
- No high-severity security vulnerabilities are identified in a third-party security review
- WCAG 2.1 AA compliance is confirmed by an accessibility audit
- The documentation set (readme, spec, scope, implementation) enables a new developer to set up a local development environment in under 60 minutes without external assistance

---

## 8. Assumptions and Constraints

### Assumptions

- Students have access to a smartphone (Android 6.0+) or a web browser on a school computer
- Schools have a minimum of 2G/3G mobile internet or school Wi-Fi connectivity
- Teachers have basic digital literacy and can learn the content management UI without formal training
- Supabase free tier limits (500MB DB, 50MB storage, 50,000 MAU) are sufficient through the beta phase
- GitHub Actions free tier (2,000 minutes/month for public repos) is sufficient for CI/CD

### Constraints

- All infrastructure services must have a free tier option to enable zero-cost development and small-scale deployment
- No paid third-party SDKs or APIs may be introduced without project owner approval
- The backend must be deployable on a single small VM (2 vCPU, 2GB RAM) for budget-constrained schools
- The Flutter app must not exceed 30MB download size for mobile (Android APK)
- All student data must be stored in India-region infrastructure where technically feasible

---

## 9. Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Supabase free tier limits exceeded during beta | Medium | High | Monitor MAU and DB size; upgrade to paid tier or self-host Supabase OSS if needed |
| Poor performance on low-end Android devices | High | High | Profile Flutter app on Android 6 device; implement lazy loading and reduce animation complexity |
| Redis unavailability causing API degradation | Low | Medium | Implement graceful cache bypass; backend computes directly from DB on cache miss |
| Database migration failure in production | Low | High | Test every migration on a staging environment before applying to production; maintain point-in-time recovery backups |
| JWT secret exposure via misconfigured environment | Low | Critical | Enforce `.gitignore` rules; rotate secrets immediately on exposure; use secret scanning in GitHub |
| Teacher adoption resistance | Medium | High | Conduct usability testing with teachers before v1.0; provide in-app guided tour |
| Scope creep extending MVP beyond 6 weeks | High | Medium | Enforce strict feature freeze after MVP scope is defined; defer new requests to Phase 1 |
| Flutter web performance on slow school computers | Medium | Medium | Profile web build; implement code splitting and deferred loading; test on minimum-spec hardware |
| LLM API costs for AI explanations (Phase 3) | Medium | Medium | Use open-weight model (Ollama/Mistral) self-hosted on the backend to avoid per-token costs |
| Student data breach | Low | Critical | Penetration test before v1.0 launch; implement all security measures in spec.md; regular dependency audits |

---

## 10. Acceptance Tests

The following tests must pass before a phase is considered complete and accepted.

### Authentication Acceptance Tests

- AT-AUTH-01: A new user can register with a valid email and password and receive a confirmation email.
- AT-AUTH-02: A registered user can log in with correct credentials and receive a valid JWT.
- AT-AUTH-03: A request to a protected endpoint without a JWT returns HTTP 401.
- AT-AUTH-04: A request with an expired JWT returns HTTP 401 with an `TOKEN_EXPIRED` error code.
- AT-AUTH-05: A student attempting to access a teacher-only endpoint returns HTTP 403.
- AT-AUTH-06: A user can log in via Google OAuth and have their profile created automatically on first login.

### Simulation Acceptance Tests

- AT-SIM-01: A student can open the Speed module, adjust the Distance slider to 100m and Time slider to 10s, and receive a computed result of 10 m/s within 200ms.
- AT-SIM-02: The simulation screen displays a Distance–Time graph with correct data points corresponding to the slider inputs.
- AT-SIM-03: The explanation section displays the formula, substituted values, and a plain-language conclusion.
- AT-SIM-04: A completed simulation session is retrievable from the `/simulate/history` endpoint after completion.
- AT-SIM-05: A simulation run with an invalid parameter value (e.g., time = 0) returns a structured HTTP 400 error, not a server crash.

### Offline Acceptance Tests

- AT-OFFLINE-01: A student with a previously loaded module list can browse modules with no internet connection.
- AT-OFFLINE-02: A simulation session completed offline is queued locally and automatically synced to the backend upon reconnection.
- AT-OFFLINE-03: The Flutter app displays a clear offline indicator when the device has no internet connectivity.

### RBAC Acceptance Tests

- AT-RBAC-01: A teacher can create, edit, and publish a simulation module. A student user cannot access the create or edit module API endpoints.
- AT-RBAC-02: An admin can change a user's role from student to teacher. The changed role takes effect on the user's next token refresh.
- AT-RBAC-03: An admin can view the audit log. A teacher cannot access the audit log endpoint.

### Performance Acceptance Tests

- AT-PERF-01: Under a simulated load of 500 concurrent users running the Speed simulation, P95 API response time does not exceed 200ms.
- AT-PERF-02: A module list response served from Redis cache returns within 50ms (P95).
- AT-PERF-03: The Flutter web application achieves a Lighthouse Performance score of ≥ 70 on a simulated 4G connection.

### Accessibility Acceptance Tests

- AT-A11Y-01: All interactive elements on the simulation screen are navigable via keyboard alone.
- AT-A11Y-02: All slider controls have descriptive ARIA/semantic labels readable by a screen reader.
- AT-A11Y-03: Text contrast ratios across all screens meet the WCAG 2.1 AA 4.5:1 minimum ratio.

### Security Acceptance Tests

- AT-SEC-01: The `pip-audit` scan in CI reports zero high-severity known vulnerabilities.
- AT-SEC-02: An attempt to access another user's simulation history returns HTTP 403.
- AT-SEC-03: All API responses in production are served exclusively over HTTPS; HTTP requests are redirected to HTTPS.
- AT-SEC-04: The `/metrics` endpoint is not accessible from the public internet (verified via external HTTP probe).

---

## 11. Change Management

Any request to add items to in-scope deliverables or to remove items from out-of-scope within an active phase must go through the following process:

1. **Change Request Submission** — The requestor documents the proposed change, its rationale, estimated effort, and impact on the current phase timeline.
2. **Impact Assessment** — The project owner assesses whether the change can be accommodated within the current phase without violating exit criteria, or must be deferred to the next phase.
3. **Decision** — The project owner approves or rejects the change. Approved changes are documented in the phase changelog. Rejected changes are logged for future phase consideration.
4. **Communication** — All stakeholders are notified of approved scope changes.

No changes to the project scope are effective until documented and communicated through this process.
