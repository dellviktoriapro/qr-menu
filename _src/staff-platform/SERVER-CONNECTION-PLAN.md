# Restaurant server rollout Implementation Plan

> Execute sequentially with executing-plans; no delegated work.

**Goal:** Connect Chez Oanh test guests and staff through Supabase, with verified tenant isolation and persistent owner analytics.
**Architecture:** Existing /app/ Auth and admin cabinet; membership-scoped RPCs for staff; a separate capability-scoped guest gateway for table QR. Never bridge through browser storage. Keep /demo/ local and Sun&Sea independent.
**Tech Stack:** Static JS, Supabase Auth/Postgres, private SQL commands, Edge Functions for guests.
**Spec:** _src/platform/DESIGN.md and current user requirements, 2026-11-06.

## Global constraints
- Development project vppgtrbewgqigfinknex; no paid plan change.
- No service keys in browser/repo. Do not disable RLS or expose raw tables.
- Existing data/carts are preserved. Test fixtures roll back.
- Owner role is current membership; platform admin receives aggregates only.
- Do not call a browser-local fixture or design mock a connected operational app.

## Review focus
- Cross-cafe IDs, revoked memberships and stale versions must be rejected.
- Retry after response loss must reuse the same request UUID and avoid duplicates.
- Kitchen/bar readiness and service are independent; service never means paid.
- Server determines prices; menu edits never rewrite order history.
- Offline/stale data and unconfirmed submissions must be visibly distinguished from success.

## 1. Authenticated staff vertical slice
Files: _src/staff-platform/operations.js, operations.css, operations-core.js, admin.js, build.py, operational-change.sql, operational-test.sql.
- [ ] Add owner routing and real membership selection after login.
- [ ] Add scoped snapshot rendering, visible server timestamp, foreground refresh and stale warning.
- [ ] Add per-item served_at/served_by and station-aware serve command; reject undoing served preparation.
- [ ] Add owner-only persisted aggregate report RPC; no demo history.
- [ ] Test SQL with two cafes, waiter/kitchen/bar/owner/revoked/anonymous, price history, stale and repeated requests.
- [ ] Review exact access grants separately from schema; enable only after approval.
- [ ] Verify real owner login and create/prepare/serve/close across separate sessions.

## 2. Guest test table
Files: new guest gateway/schema/client adapter and isolated /test-menu/ output.
- [ ] Capability tokens hashed on server, revocable per cafe/table; do not reuse Sun&Sea capabilities.
- [ ] Guest submits external catalog keys/quantities/notes, server loads authoritative prices/stations.
- [ ] Bound request IDs, limits and rate control; guest cannot list other tables or access staff/report RPCs.
- [ ] Server receipt before cart clears; pending retry survives reload; old visit writes rejected.
- [ ] Unassigned guest order accepted by waiter, then sent to stations; serialize concurrent acceptance.
- [ ] Test incognito guest -> normal owner/staff, two guests, retry/network interruption and cross-table denial.

## 3. Staff onboarding and financial/report completion
- [ ] Cafe-bound employee join invitation, pending approval by owner; role changes and revocation audited.
- [ ] Multiple named checks, atomic item transfer, per-item wishes/comments and manual unknown-price approval.
- [ ] Separate served/paid state; exact close/payment retry; corrections/refunds append-only.
- [ ] Owner daily/period reports, exports and platform aggregate consistency.

## 4. Launch gate and installation
- [ ] Cross-device E2E, reconnect and revocation tests; no demo shortcut in operational flows.
- [ ] Installable PWA with update strategy; do not cache authenticated API responses in service worker.
- [ ] Notifications tested for foreground/background and limitations documented.
- [ ] Production email, backup/restore, monitoring and measured capacity before real shift.

## Current blocker
Supabase dashboard session expired; CLI has no login token. User asked to sign in on dashboard while code/tests are prepared. No password/token requested in chat. Live schema/API enablement not yet applied.
