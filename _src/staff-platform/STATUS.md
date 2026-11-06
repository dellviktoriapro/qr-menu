# Staff server integration — 2026-11-06

Dedicated app route: `/app/`. `/demo/` remains a browser-local demonstration; Sun&Sea remains independent.

Implemented and verified in development: `connected.sql` installs CLOSED RPC wrappers, private authenticated membership-checked commands, per-cafe serialization, idempotency receipts, version checks, immutable line-price snapshots, separate bar/kitchen completion and manual bill settlement. `commands-test.sql` passed using actual authenticated roles and JWT subjects; fixtures and temporary grants were rolled back. Fixed an invalid PL/pgSQL variable qualifier found in the first run. No permanent client access has been enabled.

`login.html` / `login.js` use self-hosted Supabase SDK 2.119.0 and a publishable key. Sessions are saved in sessionStorage for this tab, not persistent localStorage. No secret/service-role key. Password registration and login are real Supabase Auth calls; the owner must enter and submit their own password. The login page intentionally does not imply that operational screens are connected yet.

Before registration: configure Auth Site URL and an exact allowed redirect `https://dellviktoriapro.github.io/qr-menu/app/` (currently localhost:3000). This browser security configuration requires action-time approval. Do not disable email confirmation. Default Supabase mail is development-only and rate-limited; configure custom SMTP before inviting external staff.

Still required: owner registration/email confirmation, cafe membership provisioning; real server adapter for existing operational UI; server analytics queries (never use demo genDay); persistent access grants only after approval and tests; multi-device end-to-end test with distinct staff; reconnect/retry and revocation tests; production backups/SMTP/monitoring. The app is not ready for live restaurant operation.

## Reproduce

Install exact packages using the committed package-lock.json, then `node bundle-sdk.cjs`; `python build.py` outputs only `/app/`. `node --check login.js` passes. Never run fixture SQL on a live restaurant.

The CLI-created baseline and staff_commands files under supabase/migrations record source for the previously manually applied development schema. Remote migration history has NOT been registered. Do not `db push` this baseline onto the current database. Reconcile history via reviewed CLI repair before using migrations. Dashboard-specific rls_auto_enable hardening remains in `_src/platform/harden-auto-rls.sql`.
