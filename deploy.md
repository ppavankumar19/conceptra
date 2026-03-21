# Conceptra — Deployment Guide

**Last Updated:** 2026  
**Author:** Sandeep Bangaru  

> Step-by-step instructions for deploying Conceptra in every environment — from local development to production.

---

## 📑 Table of Contents

- [1. Local Development (Docker Compose)](#1-local-development-docker-compose)
- [2. Production — Single Server (Docker Compose)](#2-production--single-server-docker-compose)
- [3. Production — Cloud Free Tier (Fly.io + Supabase + Upstash)](#3-production--cloud-free-tier-flyio--supabase--upstash)
- [4. Production — Kubernetes](#4-production--kubernetes)
- [5. Environment Variables Reference](#5-environment-variables-reference)
- [6. Database Migrations](#6-database-migrations)
- [7. SSL / TLS Setup](#7-ssl--tls-setup)
- [8. Health Checks & Monitoring](#8-health-checks--monitoring)
- [9. Backup & Recovery](#9-backup--recovery)
- [10. Troubleshooting](#10-troubleshooting)
- [11. Production Incident Log (March 21, 2026)](#11-production-incident-log-march-21-2026)

---

## 1. Local Development (Docker Compose)

### Prerequisites

- **Docker Desktop** 24+ installed and running  
- **Docker Compose** v2 (bundled with Docker Desktop)
- Ports `3000`, `5432`, `6379`, `8000` available

### Quick Start

```bash
cd d:\Conceptra
docker-compose up --build
```

That's it. This single command starts **all 4 services**:

| Service | Container Name | Port | URL |
|---------|---------------|------|-----|
| PostgreSQL 15 | `conceptra-postgres` | 5432 | — |
| Redis 7 | `conceptra-redis` | 6379 | — |
| FastAPI Backend | `conceptra-backend` | 8000 | http://localhost:8000/docs |
| Flutter Frontend (Nginx) | `conceptra-frontend` | 3000 | http://localhost:3000 |

### What Happens Automatically

1. PostgreSQL and Redis start first (health checks ensure readiness)
2. Backend starts after DB is healthy
3. Backend's `lifespan` function runs Alembic migrations automatically
4. Backend seeds the database with 21 simulation modules if empty
5. Frontend builds Flutter web app and serves via Nginx
6. Nginx proxies `/api/*` requests to the backend

### Common Commands

```bash
# Start everything
docker-compose up --build

# Start in background (detached)
docker-compose up --build -d

# View logs
docker-compose logs -f backend
docker-compose logs -f frontend

# Stop everything
docker-compose down

# Stop and remove data volumes (full reset)
docker-compose down -v

# Restart a single service
docker-compose restart backend

# Rebuild only the backend
docker-compose up --build backend
```

### Verify It's Working

```bash
# Check all containers are running
docker ps

# Test the API
curl http://localhost:8000/api/v1/modules?page=1&page_size=5

# Test through Nginx proxy
curl http://localhost:3000/api/v1/modules?page=1&page_size=5

# Open the app
start http://localhost:3000
```

---

## 2. Production — Single Server (Docker Compose)

Best for: small deployments, school servers, budget-friendly VPS.

### Server Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 vCPU | 4 vCPU |
| RAM | 2 GB | 4 GB |
| Disk | 20 GB SSD | 40 GB SSD |
| OS | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |

### Step 1 — Prepare the Server

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | bash
sudo usermod -aG docker $USER

# Install Docker Compose plugin
sudo apt install docker-compose-plugin -y

# Create app user
sudo useradd -m -s /bin/bash conceptra
sudo usermod -aG docker conceptra
su - conceptra
```

### Step 2 — Clone the Repository

```bash
cd /home/conceptra
git clone https://github.com/your-repo/Conceptra.git
cd Conceptra
```

### Step 3 — Create Production Environment File

```bash
cp backend/.env.example infra/.env.prod
nano infra/.env.prod
```

Fill in production values (see [Section 5](#5-environment-variables-reference) for full list):

```env
DATABASE_URL=postgresql+asyncpg://conceptra:<STRONG_PASSWORD>@postgres:5432/conceptra
REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379/0
ENVIRONMENT=production
LOG_LEVEL=INFO
SECRET_KEY=<RANDOM_64_CHAR_STRING>
ALLOWED_ORIGINS=https://yourdomain.com
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_JWT_SECRET=your-jwt-secret
SUPABASE_ANON_KEY=your-anon-key
POSTGRES_PASSWORD=<STRONG_PASSWORD>
REDIS_PASSWORD=<STRONG_PASSWORD>
DOMAIN=yourdomain.com
```

### Step 4 — Set Up SSL (Let's Encrypt)

```bash
# Install Certbot
sudo apt install certbot -y

# Get certificate (make sure DNS A record points to your server)
sudo certbot certonly --standalone -d yourdomain.com

# Certificates are stored at:
#   /etc/letsencrypt/live/yourdomain.com/fullchain.pem
#   /etc/letsencrypt/live/yourdomain.com/privkey.pem

# Auto-renewal is set up automatically by Certbot
```

### Step 5 — Deploy

```bash
cd /home/conceptra/Conceptra

# Build and start in production mode
docker compose -f infra/docker-compose.prod.yml --env-file infra/.env.prod up --build -d
```

### Step 6 — Run Migrations

```bash
docker exec conceptra-backend-prod alembic upgrade head
```

### Step 7 — Verify

```bash
# Check containers
docker ps

# Check backend health
curl https://yourdomain.com/api/v1/health

# Check logs
docker compose -f infra/docker-compose.prod.yml logs -f backend
```

### Production Architecture

```
Internet
    │
    ▼
[ Nginx (port 80/443) — TLS + Reverse Proxy ]
    │
    ├──► /api/*     ──► [ FastAPI — Gunicorn + 4 Uvicorn Workers ]
    │                         │
    │                    ┌────┴───────┐
    │                    │            │
    │               [ PostgreSQL ] [ Redis ]
    │
    └──► /*         ──► [ Flutter Web (static build) ]
```

### Production Docker Compose Details

The `infra/docker-compose.prod.yml` differs from development:

| Feature | Development | Production |
|---------|-------------|------------|
| Backend server | Uvicorn with `--reload` | Gunicorn + 4 Uvicorn workers |
| Hot reload | ✅ Volume mount | ❌ Code baked into image |
| Ports exposed | All services | Only Nginx (80/443) |
| Restart policy | `unless-stopped` | `unless-stopped` |
| SSL/TLS | None | Let's Encrypt via Nginx |
| Redis auth | None | Password required |
| DB password | Hardcoded `2002` | From environment variable |

### Updating Production

```bash
cd /home/conceptra/Conceptra
git pull origin main

# Rebuild and restart
docker compose -f infra/docker-compose.prod.yml --env-file infra/.env.prod up --build -d

# Run new migrations if any
docker exec conceptra-backend-prod alembic upgrade head
```

---

## 3. Production — Cloud Free Tier (Fly.io + Supabase + Upstash)

Best for: zero-cost hosting, demos, small user bases.

### Service Mapping

| Component | Service | Free Tier Limits |
|-----------|---------|-----------------|
| Backend (FastAPI) | Fly.io | 3 shared VMs, 256MB RAM each |
| PostgreSQL | Supabase | 500MB storage, 50,000 MAU |
| Redis | Upstash | 10,000 commands/day |
| Frontend (Flutter Web) | Vercel or Netlify | Unlimited static hosting |
| Auth | Supabase Auth | 50,000 MAU |

### Step 1 — Deploy Backend to Fly.io

```bash
# Install Fly CLI
curl -L https://fly.io/install.sh | sh

# Login
fly auth login

# Initialize (from backend/ directory)
cd backend
fly launch --name conceptra-api --region bom  # bom = Mumbai

# Set secrets
fly secrets set \
  DATABASE_URL="postgresql+asyncpg://..." \
  REDIS_URL="rediss://...@...upstash.io:6379" \
  SUPABASE_URL="https://xxx.supabase.co" \
  SUPABASE_JWT_SECRET="your-secret" \
  SUPABASE_ANON_KEY="your-key" \
  ENVIRONMENT="production" \
  SECRET_KEY="your-random-key" \
  ALLOWED_ORIGINS="https://conceptra.vercel.app"

# Deploy
fly deploy
```

### Step 2 — Set Up Supabase (PostgreSQL + Auth)

1. Go to [supabase.com](https://supabase.com) → Create project
2. Copy the **connection string** from Settings → Database → Connection string (use pooler URL)
3. Copy **Project URL**, **Anon Key**, and **JWT Secret** from Settings → API
4. Set these as Fly.io secrets (see above)

### Step 3 — Set Up Upstash Redis

1. Go to [upstash.com](https://upstash.com) → Create Redis database
2. Select the region closest to your Fly.io region
3. Copy the `REDIS_URL` and set it as a Fly.io secret

### Step 4 — Deploy Frontend to Vercel

```bash
# Build Flutter web
cd frontend
flutter build web --release --dart-define=API_BASE_URL=https://conceptra-api.fly.dev/api/v1

# Connect to Vercel
npx -y vercel --prod
```

Or connect GitHub repo to Vercel and configure:
- **Build Command:** `flutter build web --release --dart-define=API_BASE_URL=https://conceptra-api.fly.dev/api/v1`
- **Output Directory:** `build/web`

---

## 4. Production — Kubernetes

Best for: high availability, auto-scaling, large user bases.

### Prerequisites

- Kubernetes cluster (k3s, EKS, GKE, AKS)
- `kubectl` configured
- NGINX Ingress Controller installed
- cert-manager installed (for Let's Encrypt)

### Available Manifests

All Kubernetes manifests are in `infra/k8s/`:

| File | Purpose |
|------|---------|
| `namespace.yaml` | Creates `conceptra` namespace |
| `configmap.yaml` | Non-sensitive configuration |
| `backend-deployment.yaml` | Backend deployment (2 replicas) with health probes |
| `backend-service.yaml` | ClusterIP service (port 8000) |
| `postgres-statefulset.yaml` | PostgreSQL StatefulSet with PVC |
| `redis-deployment.yaml` | Redis deployment |
| `ingress.yaml` | Ingress with TLS (cert-manager) |

### Deploy

```bash
# Create namespace
kubectl apply -f infra/k8s/namespace.yaml

# Create secrets (edit values first!)
kubectl create secret generic conceptra-secrets \
  --namespace=conceptra \
  --from-literal=DATABASE_URL="postgresql+asyncpg://..." \
  --from-literal=REDIS_URL="redis://..." \
  --from-literal=SUPABASE_JWT_SECRET="..." \
  --from-literal=SECRET_KEY="..."

# Apply all manifests
kubectl apply -f infra/k8s/

# Run migrations as a job
kubectl exec -it deployment/conceptra-backend -n conceptra -- alembic upgrade head

# Verify
kubectl get pods -n conceptra
kubectl get ingress -n conceptra
```

---

## 5. Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DATABASE_URL` | ✅ | `postgresql+asyncpg://conceptra:conceptra_password@localhost:5432/conceptra` | PostgreSQL connection string |
| `REDIS_URL` | ✅ | `redis://localhost:6379/0` | Redis connection string |
| `SUPABASE_URL` | ✅ | — | Supabase project URL |
| `SUPABASE_JWT_SECRET` | ✅ | — | JWT secret from Supabase dashboard |
| `SUPABASE_ANON_KEY` | ✅ | — | Supabase anon/public key |
| `ALLOWED_ORIGINS` | ✅ | `http://localhost:3000,http://localhost:8080` | Comma-separated CORS origins |
| `ENVIRONMENT` | ❌ | `development` | `development`, `production`, or `testing` |
| `LOG_LEVEL` | ❌ | `INFO` | `DEBUG`, `INFO`, `WARNING`, `ERROR` |
| `SECRET_KEY` | ✅ | `change-me-in-production` | App secret key (change in production!) |
| `POSTGRES_DB` | ❌ | `conceptra` | PostgreSQL database name |
| `POSTGRES_USER` | ❌ | `conceptra` | PostgreSQL username |
| `POSTGRES_PASSWORD` | ✅ | — | PostgreSQL password |
| `REDIS_PASSWORD` | ❌ | — | Redis password (required in production) |
| `DOMAIN` | ❌ | — | Domain name (for SSL cert paths in production) |

---

## 6. Database Migrations

### Automatic (Default)

The backend's `lifespan` function in `app/main.py` automatically runs:
1. `alembic upgrade head` — applies any pending migrations
2. `seed_data.py` logic — seeds 21 modules if the database is empty

This happens every time the backend starts. No manual intervention needed for local development.

### Manual

```bash
# Run inside the backend container
docker exec -it conceptra-backend alembic upgrade head

# Create a new migration after model changes
docker exec -it conceptra-backend alembic revision --autogenerate -m "describe your change"

# Check current migration status
docker exec -it conceptra-backend alembic current

# Rollback one migration
docker exec -it conceptra-backend alembic downgrade -1
```

---

## 7. SSL / TLS Setup

### Let's Encrypt (Free, Recommended)

```bash
# Install Certbot
sudo apt install certbot -y

# Get certificate
sudo certbot certonly --standalone -d yourdomain.com

# Auto-renewal runs automatically via systemd timer
# Verify with:
sudo certbot renew --dry-run
```

The production `docker-compose.prod.yml` mounts the certificates into Nginx:

```yaml
volumes:
  - /etc/letsencrypt/live/${DOMAIN}/fullchain.pem:/etc/nginx/ssl/fullchain.pem:ro
  - /etc/letsencrypt/live/${DOMAIN}/privkey.pem:/etc/nginx/ssl/privkey.pem:ro
```

### Self-Signed (Testing Only)

```bash
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout privkey.pem \
  -out fullchain.pem \
  -subj "/CN=localhost"
```

---

## 8. Health Checks & Monitoring

### Built-in Health Endpoints

| Endpoint | Purpose | Expected Response |
|----------|---------|-------------------|
| `GET /api/v1/health` | Liveness check | `200 OK` |
| `GET /api/v1/health/ready` | Readiness check (DB + Redis) | `200 OK` |
| `GET /docs` | API documentation (Swagger UI) | HTML page |

### Docker Health Checks

The `docker-compose.yml` includes health checks for PostgreSQL and Redis:
- **PostgreSQL:** `pg_isready` every 10 seconds
- **Redis:** `redis-cli ping` every 10 seconds

### Monitoring Stack (Optional)

For production monitoring, deploy Prometheus + Grafana:

```bash
# The backend exposes /metrics for Prometheus scraping
curl http://localhost:8000/metrics

# Deploy Grafana (free, self-hosted)
docker run -d -p 3001:3000 --name grafana grafana/grafana-oss
```

---

## 9. Backup & Recovery

### Database Backup

```bash
# Create a backup
docker exec conceptra-postgres pg_dump -U conceptra conceptra > backup_$(date +%Y%m%d).sql

# Automated daily backup (add to crontab)
0 2 * * * docker exec conceptra-postgres pg_dump -U conceptra conceptra > /backups/conceptra_$(date +\%Y\%m\%d).sql

# Restore from backup
docker exec -i conceptra-postgres psql -U conceptra conceptra < backup_20260319.sql
```

### Redis Backup

Redis persists data using RDB snapshots in the `redis_data` volume. For manual backup:

```bash
docker exec conceptra-redis redis-cli BGSAVE
docker cp conceptra-redis:/data/dump.rdb ./redis_backup.rdb
```

### Full System Backup

```bash
# Stop services
docker-compose down

# Backup volumes
docker run --rm -v conceptra_postgres_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/postgres_data.tar.gz /data

docker run --rm -v conceptra_redis_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/redis_data.tar.gz /data

# Restart services
docker-compose up -d
```

---

## 10. Troubleshooting

| Symptom | Cause | Solution |
|---------|-------|----------|
| `port 3000 already in use` | Another process on port 3000 | `netstat -ano \| findstr :3000` → kill the process |
| `port 5432 already in use` | Local PostgreSQL running | Stop local PostgreSQL or change port in `docker-compose.yml` |
| Backend returns `500` on first request | Migrations haven't run yet | Wait ~10 seconds for auto-migration, or run `docker exec conceptra-backend alembic upgrade head` |
| Frontend shows "No modules found" | Cached empty response | Press `Ctrl+Shift+R` (hard refresh) or clear site data |
| `ModuleNotFoundError` in backend | Missing Python dependency | Add package to `requirements.txt` and rebuild: `docker-compose up --build backend` |
| `connection refused` to PostgreSQL | DB not ready yet | Check health: `docker exec conceptra-postgres pg_isready -U conceptra` |
| Redis `NOAUTH` error | Redis password required | Set `REDIS_PASSWORD` in `.env` and update `REDIS_URL` |
| Flutter build fails in Docker | Disk space or memory | Ensure Docker has ≥ 4GB RAM allocated in Docker Desktop settings |
| Nginx returns 502 Bad Gateway | Backend not running | Check backend logs: `docker-compose logs backend` |
| SSL certificate expired | Let's Encrypt renewal failed | Run `sudo certbot renew` manually |

### Useful Debug Commands

```bash
# View all container logs
docker-compose logs -f

# Enter the backend container shell
docker exec -it conceptra-backend bash

# Check database connectivity
docker exec conceptra-backend python -c "from app.db.session import engine; print('DB OK')"

# Inspect a container
docker inspect conceptra-backend

# Check resource usage
docker stats
```

---

## 11. Production Incident Log (March 21, 2026)

This section records the production deployment issues fixed during the March 21, 2026 rollout (Vercel frontend + Render backend + Supabase DB/Auth).

### Final Live Endpoints

- Frontend: `https://conceptra-webapp.vercel.app`
- Backend API base: `https://conceptra-api.onrender.com/api/v1`
- Backend readiness: `https://conceptra-api.onrender.com/api/v1/health/ready`

### What Was Fixed

1. Vercel frontend build failure (`pubspec.yaml duplicate mapping key`)
- Cause: `build.sh` appended a second `flutter:` block to `frontend/pubspec.yaml`.
- Fix: removed pubspec mutation from `build.sh`.

2. Flutter SDK mismatch on Vercel
- Cause: build script used old Flutter while lockfile required newer SDK.
- Fix: pinned compatible Flutter in build process and improved build script reliability.

3. Render backend CORS mismatch
- Cause: development-mode CORS only allowed localhost regex and ignored configured origins.
- Fix: backend now always honors `ALLOWED_ORIGINS`; localhost regex remains extra in non-production.

4. Supabase connection and pooler compatibility
- Cause: incorrect DB URL format/parameters and pooler mode mismatch generated runtime failures.
- Fixes:
  - normalized DB URL to `postgresql+asyncpg://...`
  - used Supabase IPv4 pooler session endpoint and SSL
  - ensured asyncpg compatibility options for Supabase pooler flows

5. Missing DB schema/data in Supabase
- Cause: target `public` schema had no app tables, producing `/modules` 500 errors.
- Fix:
  - ran migrations against Supabase
  - verified tables exist
  - seeded simulation module data

6. Render startup stability
- Cause: backend container command hardcoded multiple workers, increasing startup race risk.
- Fix: backend Docker startup changed to configurable workers with safe default (`WEB_CONCURRENCY=1`) and Render `PORT` support.

### Final Required Runtime Configuration

#### Render (`conceptra-api`)

- `DATABASE_URL` (asyncpg + SSL + encoded password):
  - `postgresql+asyncpg://<user>:<url-encoded-password>@<supabase-pooler-host>:5432/postgres?ssl=require`
- `REDIS_URL`: Upstash/Redis URL
- `ALLOWED_ORIGINS`:
  - `https://conceptra-webapp.vercel.app,https://conceptra-webapp-git-master-pavan-kumar-s-projects-a55a3b6a.vercel.app,http://localhost:3000,http://localhost:8080`
- `ENVIRONMENT=production`

#### Supabase Auth

- Site URL:
  - `https://conceptra-webapp.vercel.app`
- Redirect URLs:
  - `http://localhost:3000/**` (optional local)
  - `https://conceptra-webapp.vercel.app/**`
  - `https://conceptra-webapp-git-master-pavan-kumar-s-projects-a55a3b6a.vercel.app/**`
  - `io.supabase.conceptra://login-callback/` (mobile deep link)
- Google OAuth redirect URI (Google Cloud Console):
  - `https://lvgsombxkoedcgznqnge.supabase.co/auth/v1/callback`

### Verification Checklist (Current)

- `GET /api/v1/health` returns 200
- `GET /api/v1/health/ready` returns DB/Redis `ok`
- `OPTIONS /api/v1/modules` returns CORS headers for Vercel origin
- `GET /api/v1/modules?page=1&page_size=20` returns 200 with module data
- Google login redirects to Vercel domain (not localhost)

*This deployment guide covers all supported deployment targets for Conceptra. Update it as new infrastructure options are added.*
