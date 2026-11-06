# Original application is the required baseline

Confirmed by user 2026-11-06. The smaller operations.js UI is transitional and must not become a new product baseline.

| Existing original feature | Actual server state | Transfer requirement |
|---|---|---|
| Waiter tabs/all/new/cooking/ready/tables, mine/history | subset implemented | preserve original renderers and navigation; All excludes tables per latest request |
| Edit/accept/send/reorder/comments | manual create/edit/send RPC, guest acceptance absent | atomic acceptance and per-check round history |
| Kitchen and bar, item ready, separate serving | supported | bind original controls to existing versioned commands |
| Split checks/payment/close table | schema and close RPC, full original UI absent | restore original check UI; one atomic payment/close command |
| Shift and ready notifications/escalation | original browser-only | persist shift/notification settings, authoritative timing; no closed-browser push claim |
| Employee requests/add/approval/role/block/remove/history | original browser-only; membership table exists | scoped staff onboarding and audited owner commands, revoke immediately |
| Employee connection QR/reissue | original browser-only | real expiring revocable cafe link, pending approval; do not use four-character demo code |
| Cafe payment QR, waiter tip QR | original browser-only | storage + role-scoped access; preserve existing upload/compress/replace UI |
| Reviews links | original browser-only | cafe settings and existing validators |
| Stop-list/search | server stop command available | bind original switch/list, owner all / station only for cooks/bar |
| Analytics periods today/yesterday/7/30/90/custom | current server aggregate only | reuse period controls, chart/table renderers and CSV |
| Revenue/bills/average/comparison/daily/hourly | only aggregate subset | authoritative complete historical aggregation, local cafe timezone |
| Waiter stats/top dishes/languages/payment mix | absent in server report | separate metric definitions; historical snapshots, no fabricated acceptance timing |
| Notifications/sound/light-dark/five palettes/languages | original UI exists | per-device preferences only; cafe theme/settings server-scoped |
| Guest QR order, requests and statuses | not connected | real isolated guest gateway and receipts, no localStorage/BroadcastChannel transport |
| Admin cafe/inbox/aggregate stats | supported separately | retain admin boundary, no staff impersonation or raw orders in admin |

Readiness means every original feature has a real persistence/action contract and a cross-device test, not just matching colors. Unknown price must not turn into 0. No seedState/genDay/sample people in server mode. Existing real test data is preserved.
