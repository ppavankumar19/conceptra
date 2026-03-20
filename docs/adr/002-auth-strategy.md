# ADR 002 — Authentication Strategy: Delegate to Supabase Auth

| Field       | Value                          |
|-------------|-------------------------------|
| **Status**  | Accepted                       |
| **Date**    | 2025-01-20                     |
| **Deciders**| Engineering Lead, Security Lead|
| **Ticket**  | EDU-012                        |

---

## Context

Conceptra requires:

- Email/password registration and login.
- OAuth social login (Google, GitHub, Apple) for frictionless onboarding.
- Magic-link (passwordless) email login.
- Multi-factor authentication (TOTP) for teacher/admin accounts.
- Secure session management with refresh tokens.
- Role-based access control (student, teacher, admin).
- Password reset and email verification flows.
- Compliance: GDPR (EU), COPPA (US — student data under 13), FERPA (education records).

Building a custom auth system that satisfies all of the above correctly, securely, and maintainably is a significant engineering investment with high risk.

---

## Decision

**Delegate all authentication and identity management to Supabase Auth**, using it as an external identity provider. The Conceptra FastAPI backend validates Supabase-issued JWTs on every request rather than issuing its own tokens.

### How it works

```
User                Flutter App          Supabase Auth        FastAPI Backend
 |                      |                      |                     |
 |-- login (email/pw) ->|                      |                     |
 |                      |-- signInWithPassword->|                     |
 |                      |<--- access_token -----|                     |
 |                      |                      |                     |
 |                      |-- GET /api/v1/me ----|-------------------->|
 |                      |   Authorization: Bearer <access_token>     |
 |                      |                      |-- verify JWT ------>|
 |                      |                      |   (JWKS endpoint)   |
 |                      |<----- user data -----|---------------------|
```

1. Flutter uses `supabase_flutter` SDK for all auth flows (sign up, sign in, OAuth, magic link, MFA).
2. Supabase issues a short-lived JWT (1 hour) and a long-lived refresh token (stored in secure storage).
3. Every FastAPI request extracts the Bearer token from the `Authorization` header.
4. FastAPI validates the JWT signature using Supabase's public JWKS endpoint (cached with a 24-hour TTL).
5. The JWT `sub` claim (Supabase user UUID) is the canonical user identifier in the Conceptra database.
6. Custom claims in the JWT (e.g., `role`) are set via Supabase Auth Hooks and read by the backend for RBAC.

### Custom claims for RBAC

Supabase Auth Hooks (custom access token hook) inject `user_role` into the JWT:

```sql
-- Supabase custom access token hook
create or replace function custom_access_token_hook(event jsonb)
returns jsonb language plpgsql as $$
declare
  user_role text;
begin
  select role into user_role
  from public.user_profiles
  where id = (event->>'user_id')::uuid;

  return jsonb_set(
    event,
    '{claims,user_role}',
    to_jsonb(coalesce(user_role, 'student'))
  );
end;
$$;
```

The FastAPI `get_current_user` dependency reads `user_role` from the decoded token and enforces permissions without a database round-trip per request.

---

## Rationale

### Why Supabase Auth specifically?

| Criterion | Custom Auth | Supabase Auth |
|-----------|-------------|---------------|
| Time to implement | 4-8 weeks | 1-2 days |
| OAuth providers | Manual per-provider | 20+ built-in |
| MFA (TOTP) | Build from scratch | Built-in |
| Magic links | Build from scratch | Built-in |
| PKCE, CSRF protection | Must implement | Handled |
| Session rotation | Must implement | Handled |
| Breach monitoring | None | Supabase handles |
| SOC 2 compliance | Our responsibility | Supabase certified |
| GDPR data residency | Configure per cloud | EU region available |
| Cost | Engineering time | Free tier generous; ~$25/mo pro |

### Why not a third-party IdP (Auth0, Clerk, Firebase Auth)?

- **Auth0**: Expensive at scale ($240/mo for 7,000 MAU). Supabase Auth is included in the database plan.
- **Clerk**: Good DX but React-centric; Flutter SDK is not first-class.
- **Firebase Auth**: Google lock-in conflicts with our multi-cloud strategy; no Postgres-native integration.
- **Keycloak (self-hosted)**: Operational overhead of running another stateful service; overkill for MVP.

Supabase Auth is co-located with our PostgreSQL database (same platform), which simplifies Row Level Security policies and eliminates cross-service latency.

---

## Consequences

### Positive

- Auth flows (OAuth, magic link, MFA) available on day 1 with battle-tested security.
- JWKS-based validation is stateless — no database lookup required to authenticate a request.
- Supabase Row Level Security (RLS) can enforce data isolation at the database level for multi-tenant scenarios.
- Flutter `supabase_flutter` package provides ready-made UI widgets for login/signup.
- Reduces the attack surface we own; Supabase's security team monitors for vulnerabilities.

### Negative / Risks

- **Vendor dependency**: If Supabase changes pricing or deprecates Auth, migration is required. Mitigated by the fact that Supabase is open-source (self-hostable) and the JWT format is standard.
- **Custom auth flows are constrained**: Highly bespoke login experiences may require workarounds. Acceptable given Conceptra's standard requirements.
- **JWT leakage window**: Compromised access tokens are valid until expiry (1 hour). Mitigated by short expiry + token refresh + revocation via Supabase dashboard.
- **Network dependency in validation**: JWKS endpoint must be reachable. Mitigated by caching public keys with a long TTL; keys only change on rotation.

### Migration path if Supabase becomes unavailable

Because we use standard JWT (RS256), migration to a self-hosted Supabase instance or another OIDC-compatible provider requires:
1. Exporting users from Supabase (supported via management API).
2. Updating the JWKS URL in FastAPI config.
3. Reissuing tokens via the new provider.

This is a known, bounded migration — not a full auth rewrite.

---

## Implementation Notes

### FastAPI dependency

```python
# app/core/auth.py
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from app.core.config import settings

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    token = credentials.credentials
    try:
        payload = jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            options={"verify_aud": False},
        )
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return payload

def require_role(*roles: str):
    async def _check(user: dict = Depends(get_current_user)) -> dict:
        user_role = user.get("user_role", "student")
        if user_role not in roles:
            raise HTTPException(status_code=403, detail="Insufficient permissions")
        return user
    return _check
```

### Flutter integration

```dart
// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  Future<AuthResponse> signInWithEmail(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signInWithGoogle() =>
      _client.auth.signInWithOAuth(OAuthProvider.google);

  Future<void> signOut() => _client.auth.signOut();

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  String? get accessToken => _client.auth.currentSession?.accessToken;
}
```

---

## Review Date

Re-evaluate this decision at 10,000 MAU or if Supabase pricing changes significantly — whichever comes first.
