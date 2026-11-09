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
