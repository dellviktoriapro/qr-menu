# Original application is the required baseline

Confirmed by user 2026-11-06. The smaller operations.js UI is transitional and must not become a new product baseline.

| Existing original feature | Actual server state | Transfer requirement |
|---|---|---|
| Waiter tabs/all/new/cooking/ready/tables, mine/history | subset implemented | preserve original renderers and navigation; All excludes tables per latest request |
| Edit/accept/send/reorder/comments | manual create/edit/send RPC, guest acceptance absent | atomic acceptance and per-check round history |
| Kitchen and bar, item ready, separate serving | supported | bind original controls to existing versioned commands |
| Split checks/payment/close table | schema and close RPC, full original UI absent | restore original check UI; one atomic payment/close command |
| Shift and ready notifications/escalation | original browser-only | persist shift/notification settings, authoritative timing; no closed-browser push claim |
| Employee requests/add/approval/role/block/remove/history | live scoped staff module installed; real owner onboarding E2E pending | scoped staff onboarding and audited owner commands, revoke immediately |
| Employee connection QR/reissue | live email-bound expiring invitation module installed | real expiring revocable cafe link, pending approval; do not use four-character demo code |
| Cafe payment QR, waiter tip QR | private storage and scoped upload module installed | storage + role-scoped access; preserve existing upload/compress/replace UI |
| Reviews links | server settings module installed | cafe settings and existing validators |
| Stop-list/search | server stop command available | bind original switch/list, owner all / station only for cooks/bar |
| Analytics periods today/yesterday/7/30/90/custom | original report renderer connected to detailed server report | reuse period controls, chart/table renderers and CSV |
| Revenue/bills/average/comparison/daily/hourly | detailed historical server aggregation installed and tested | authoritative complete historical aggregation, local cafe timezone |
| Waiter stats/top dishes/languages/payment mix | detailed server breakdown installed and tested | separate metric definitions; historical snapshots, no fabricated acceptance timing |
| Notifications/sound/light-dark/five palettes/languages | original UI exists | per-device preferences only; cafe theme/settings server-scoped |
| Guest QR order, requests and statuses | QR transport/intake tested in rollback; public activation and UI integration pending | real isolated guest gateway and receipts, no localStorage/BroadcastChannel transport |
| Admin cafe/inbox/aggregate stats | supported separately | retain admin boundary, no staff impersonation or raw orders in admin |

Readiness means every original feature has a real persistence/action contract and a cross-device test, not just matching colors. Unknown price must not turn into 0. No seedState/genDay/sample people in server mode. Existing real test data is preserved.


## 2026-11-09 — Original working UI and link-only staff onboarding
User approved guest service access and link-only staff onboarding. Installed guest-service.sql + enable-guest-service.sql, recorded-edit.sql, staff-links.sql + enable-staff-links.sql, then guest-lazy-visits.sql. guest-orders and staff-access Edge updated in Dashboard. New migrations record exact source only; remote history remains unreconciled: never db push baseline.
Original ops/tpl.html renderers compiled by build-flow.py: waiter cards/tabs/mine/history, editor, split checks/bill sheet, kitchen/bar, workbench and stop switches. Business writes use authenticated RPC; no local mutation fallback. Full-state adapter retains historical names/prices and exact line IDs. Source report/staff modules remain intact. New incoming queue, persistent guest service notices, independent station readiness and opt-in foreground sound. Palette changes retain navigation/status semantics. Guest per-item wishes, private payment/tip QR context and immutable service retries attached only to Chez Oanh. PWA shell caches no auth/order/payment data; no closed-browser push claim.
Server rollback tests PASS: link invite reserve/manual owner code approval/one-use/role/block, historical editor atomicity, guest service scope/private contact isolation/no automatic payment/idempotency, lazy financial bill (scan alone creates none, first order one shared bill, close invalidates visits). All 15 staff-platform CJS scripts pass with NODE_PATH platform-build dependency cache. Local original source UI/editor and 390px fixture checked; input survives polling, no horizontal overflow.
STATUS: frontend publication and real newly compiled UI/staff registration E2E pending at this entry. Prior real guest order #2 completed120000 VND on table3 with old UI; real table1 preserved. Staff password must be entered by user. Real cafe table numbers/payment QR not provided; configured1/2/3 are test tables. Waiter serving remains assigned-order scoped. Sun&Sea unchanged.


## 2026-11-09 — Live staff test and dialog repairs
User manually approved test waiter and signed in through personal link. Real order#3/table3:130000VND accepted/sent by waiter; owner marked stations separately; waiter served bar while kitchen still cooking, then kitchen; guest cash bill request persisted. Closed via the former service dialog, recorded cash only (no bank transaction). Owner report:2 paid checks250000=120000 earlier+130000; old table1/order1 retained. Guest reload correctly refuses closed visit. Personal waiter has no owner/staff/analytics access. No background push claim.
Live original bill sheet exposed missing overlay control lookups (null bX onclick): original markup uses unprefixed child IDs, compiler only searched prefixed overlay IDs or main root. Fixed overlay child lookup; actual local bill/editor UI checked. Two-check cash/card payload preserves check UUIDs; sheet stays open during delayed/failed receipt and closes only on success. Guest total falls back to authoritative submitted quote before acceptance; accepted table context remains authoritative; closed visits show zero. Personal staff login no longer reopens signup on initial Auth callback. Removed duplicate outer service banner, retaining original bill-request controls.30-second escalation constant aligned. Server tabs/manual action match approved blue/orange styling.18 CJS tests PASS;390px iframe has374/374 client/scroll width; one bill-request button. No server grants/schema changes.
Current fixes local verified; publication/live repaired-sheet verification pending at this entry. Temporary QA pages removed before commit. Remaining real launch inputs: actual table numbers and cafe bank QR, real staff invitations. Existing test totals are test records, not business revenue. Remote migration history still unreconciled: never db push baseline. Sun&Sea unchanged.
