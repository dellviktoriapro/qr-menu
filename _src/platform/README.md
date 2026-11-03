# Supabase staff application foundation

Development project: `restaurant-platform-dev`, ref `vppgtrbewgqigfinknex`, Singapore. Owner organization: Restaurant Platform. This directory contains no credentials.

## Applied 2026-11-03

`bootstrap.sql` was applied once through the authenticated Supabase SQL Editor to the empty development project. It creates ten `public.rp_*` tables with RLS, tenant-constrained foreign keys, historical snapshots and no client grants. It is **not** a migration-history record. Do not rerun it on an existing database. Establish CLI-generated migration history before changing the schema or deploying production.

`verification.sql` is a transaction-only integration test. It inserts two fixture restaurants and three fixture Auth identities, temporarily grants reads, exercises actual `anon` / `authenticated` Postgres roles and JWT subject settings, then rolls everything back. No emails or credentials are created and no fixture identities remain. Run it only against development, never a live restaurant. No permanent permissions are widened.

Verified results:
- 10 RLS-protected tables; no anonymous/authenticated permanent read grants.
- Owner A reads only cafe A and its 100000 VND payment; owner B reads only cafe B and its 200000 VND payment.
- Waiter A reads cafe A operational bills and no financial payment history.
- Anonymous role reads no cafe/payment data even under transaction-only SELECT grants.
- Inactive membership loses reads without a refreshed JWT.
- Cross-tenant table/bill foreign key and duplicate open visit are rejected.
- After rollback: 0 cafes, 0 fixture auth users, 0 exposed tables. Logical database size 11 MB (not total disk usage).

## Not connected yet

The deployed `demo/` still uses local browser data. This bootstrap does not connect devices, implement sign-in, generate real reports or submit live orders. Application integration requires authenticated onboarding, transactional commands, idempotency/concurrency, Realtime and role-specific tests. No guest menu is connected to this backend.

Use `DESIGN.md` and `PLAN.md` for decisions and remaining tasks. Do not place service-role keys, database passwords, guest capabilities or private staff data in this public repository.

Security Advisor identified broad default EXECUTE on Dashboard-created public.rls_auto_enable(). Applied harden-auto-rls.sql to revoke direct PUBLIC/anon/authenticated calls while preserving the event trigger. Temporary CREATE TABLE + rollback confirmed automatic RLS still works.


Fresh Security Advisor after hardening: 0 errors, 0 warnings, 0 suggestions (2026-11-03). This is a linter result, not a complete application security audit.

