# Full original app to Supabase implementation plan

> Execute sequentially using executing-plans. No delegation. This supersedes rebuilding the UI inside operations.js.

**Goal:** Keep the complete original staff app and replace its local business data/actions with authenticated Supabase reads and commands.
**Architecture:** `_src/ops/tpl.html` remains the single UI source for demo and server builds. A server bootstrap provides mapped authoritative state and role-scoped commands. Browser preferences stay local; orders, staff, payments, shifts, settings and QR assets do not. The existing /app/ Auth/admin boundary remains.
**Tech stack:** existing static JS/build scripts, Supabase Auth/Postgres/RPC, private storage for uploaded QR assets.
**Spec:** user confirmation 2026-11-06 and FULL-APP-PARITY.md.

## Constraints
- Preserve the actual test owner, cafe, menu and saved orders. No resets/import of demo fixtures.
- Sun&Sea is independent; do not modify its menu/cart/service.
- /demo/ stays a clearly labelled local demonstration. /app/ is the single authenticated production entry.
- Never show seeded orders/history or manufacture unavailable metrics in the server build.
- Client role buttons do not grant roles or change the authenticated identity.
- Existing price snapshots, split checks, independent preparation/service, paid versus served distinctions are retained.
- New RPC grants/security changes require concrete review before activation; do all code/tests first.

## Review focus
- Membership revoked while a screen is open: hide sensitive data and reject commands.
- Retry after lost response: identical request UUID, never duplicate order/payment.
- Menu price change: historical order and analytics use the recorded price.
- Same user in multiple cafes: state, QR, staff and reports never leak between cafes.
- Empty station: not considered ready; serving bar never serves kitchen or closes payment.
- Missing historic data: explicit unavailable value, never demo generated history.

## Tasks
- [x] Inventory original UI and server gaps in FULL-APP-PARITY.md.
- [x] Add and test authoritative snapshot adapter full-state.js. No seedState fallback.
- [x] Build original UI in ISOLATED server integration mode (not activated in /app/): replace storage/importInbox/simulators with bootstrap and explicit action transport. Preserve renderers and CSS.
- [ ] Complete server contracts for all existing order actions, checks, shifts, settings, staff and QR assets; tests per tenant/role/action.
- [x] Owner analytics: daily aggregates/current+previous periods, hourly/language/dish/waiter/payment breakdowns, exact closed-bill revenue and CSV. Preserve original period/chart/table renderers.
- [ ] Staff joining: cafe-bound expiring/revocable QR, pending request, owner approval, exact account binding; no role from user metadata. Auth delivery limitation must be solved before declaring onboarding complete.
- [ ] Cafe payment QR, personal tip QR, reviews and notification settings: scoped storage/commands and existing UI.
- [ ] Guest route: isolated Chez Oanh test table, receipt-backed submit/retry, waiter acceptance and status. No Sun&Sea changes.
- [ ] Compile BOTH demo and server from original template. Remove simplified operations rendering after verified parity; keep the reusable Auth/RPC core.
- [ ] Run full lifecycle from incognito/second staff session, roles, reconnect, phone/desktop, all palettes.
- [ ] Publish /app/ only after backend contracts are enabled and the complete original flows work. No half-functional replacement screen.

## Verified first integration build
`build-full-runtime.py --output <outside app>` compiles the existing demo template; it does not write a second production app. Requires original demo build first. It removes seedState, genDay, load, storage business transport and simulators. Original owner periods/charts/tables/CSV/staff/QR/stop controls render on mapped server-shaped fixtures. Existing supported preparation/service commands use the transport contract. Other original business mutations deliberately throw SERVER_ACTION_NOT_PORTED, so no local success can be confused with persistence. Do not activate until those functions are ported. Analytics fixtures are explicitly test data, not real stats.


## Execution ledger — 2026-11-07
- Detailed original owner report installed and published in 89a19ba; calendar DST refinement installed this session. No grants changed.
- Staff/QR/settings backend + original renderers are staged; actual Postgres rollback, service-role wrapper and Edge/client tests PASS. Desktop and mobile 390px fixture checked.
- Security activation confirmation requested via async question; pending. No staff schema/Edge/flag deployment yet.
- Ruling: keep staff UI gated on server staff_enabled until the reviewed backend is active; do not publish an apparent working invitation before it exists.
- Guest ordering, original remaining order/check/history actions and cross-device E2E still to implement/verify. Existing test cafe owner/orders preserved. No Sun&Sea changes.


## 2026-11-09 — Original working UI and link-only staff onboarding
User approved guest service access and link-only staff onboarding. Installed guest-service.sql + enable-guest-service.sql, recorded-edit.sql, staff-links.sql + enable-staff-links.sql, then guest-lazy-visits.sql. guest-orders and staff-access Edge updated in Dashboard. New migrations record exact source only; remote history remains unreconciled: never db push baseline.
Original ops/tpl.html renderers compiled by build-flow.py: waiter cards/tabs/mine/history, editor, split checks/bill sheet, kitchen/bar, workbench and stop switches. Business writes use authenticated RPC; no local mutation fallback. Full-state adapter retains historical names/prices and exact line IDs. Source report/staff modules remain intact. New incoming queue, persistent guest service notices, independent station readiness and opt-in foreground sound. Palette changes retain navigation/status semantics. Guest per-item wishes, private payment/tip QR context and immutable service retries attached only to Chez Oanh. PWA shell caches no auth/order/payment data; no closed-browser push claim.
Server rollback tests PASS: link invite reserve/manual owner code approval/one-use/role/block, historical editor atomicity, guest service scope/private contact isolation/no automatic payment/idempotency, lazy financial bill (scan alone creates none, first order one shared bill, close invalidates visits). All 15 staff-platform CJS scripts pass with NODE_PATH platform-build dependency cache. Local original source UI/editor and 390px fixture checked; input survives polling, no horizontal overflow.
STATUS: frontend publication and real newly compiled UI/staff registration E2E pending at this entry. Prior real guest order #2 completed120000 VND on table3 with old UI; real table1 preserved. Staff password must be entered by user. Real cafe table numbers/payment QR not provided; configured1/2/3 are test tables. Waiter serving remains assigned-order scoped. Sun&Sea unchanged.
