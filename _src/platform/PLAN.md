# Restaurant platform foundation Implementation Plan

> Execute sequentially in this chat. No delegated work.

**Goal:** Create and verify a closed multi-tenant database foundation without changing the public menus or existing demo.

**Architecture:** Supabase Postgres with tenant-scoped relational tables and RLS. All application grants remain closed until authentication and atomic commands are implemented.

**Tech Stack:** Hosted Supabase Postgres, SQL, existing static staff application in subsequent stages.

**Spec:** DESIGN.md

## Global constraints
- Keep Sun&Sea guest menu separate; do not reset existing carts or demo data.
- Do not expose secret/service-role credentials or invent confirmed bank payments.
- Preserve history and tenant boundaries; do not publish live credentials to GitHub.

## Review focus
- Cross-tenant foreign-key substitution.
- Inactive memberships and anonymous access.
- Waiter access to owner financial history.
- Price edits altering historical orders.
- Unintended persistent test data or permission grants.

### Task 1: Closed schema and repeatable security test
- [x] Write verification.sql assertions for tables, RLS, default privileges and composite FK rejection.
- [x] Run preflight against empty project and demonstrate missing foundation.
- [x] Implement bootstrap.sql transaction with cafes, memberships, tables, menu, bills, checks, orders, items, payments and events.
- [x] Apply to development project through SQL Editor; do not grant client access.
- [x] Run rollback-only verification for anonymous, active owner/waiter, inactive and cross-tenant access.
- [x] Save SQL and result evidence in repository; commit only foundation and docs.

### Task 2: Auth and command layer (next stage)
- [ ] Implement actual sign-in and owner/invited memberships; test revoked membership and stale roles.
- [ ] Implement atomic commands with explicit role checks, idempotency and version checks.
- [ ] Test station completion independently, duplicate submissions and historical price snapshots.
- [ ] Open only reviewed permissions after access review; integrate existing demo through adapter.

### Task 3: Production readiness
- [ ] Test multi-device synchronization, reconnect and pending state; load-test representative restaurants.
- [ ] Implement owner reports, daily summaries, exports and usage monitoring.
- [ ] Configure production email delivery, backup/restore and production environment separately.
- [ ] Review current tariff, spending controls and paid launch approval before real shift.
