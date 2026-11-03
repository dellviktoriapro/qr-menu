# Staff platform: Supabase foundation

Approved direction: one multi-tenant staff application for multiple restaurants, Supabase, owner-visible persistent analytics. Sun&Sea guest menu remains separate. Development project vppgtrbewgqigfinknex, Singapore, Free. No subscription change authorized.

## Decisions
- Relational cafe_id boundaries and composite foreign keys prevent connecting an order in one restaurant to a bill/menu item in another.
- Auth user identities reference Supabase Auth; membership status and role are database records, not editable JWT metadata. Removing a membership revokes reads on subsequent queries.
- Bootstrap installs closed tables: RLS enabled, no anon/authenticated table privileges. Select policies are prepared and exercised using transaction-only temporary grants in tests. Client writes and live application integration come later through reviewed atomic commands.
- Financial records and full audit history readable only by owner/manager; staff see operational records only for active memberships. Membership read policy is self-only to avoid recursive authorization.
- Historical item names, station, unit price, currency and waiter are snapshots. Prices use integer minor units. Payments are manually recorded tender, not bank-verified payment confirmation.
- No deleting history on closing a visit. Corrections/refunds must use explicit transactions and audit events in the command layer, not rewriting old totals.
- No persistent test identities or financial data: all verification fixtures and grants are rolled back.
- Schema source bootstrap.sql is an initial, one-shot, transactional SQL bootstrap, not a fabricated CLI migration. Adopt CLI-generated migration history before subsequent schema changes.

## Follow-on work
Authenticated onboarding, owner creation/membership invitations, role-specific atomic commands, idempotent client mutations, optimistic concurrency, station readiness, payments/refunds, realtime permissions, durable pending mutations and reconnect, analytics queries/daily aggregates, SMTP, backup/restore drill and load tests. Until completed the existing demo remains browser-local and must not be sold as a connected production app.

## Capacity
Initial planning assumption 10–20 KB/order including line items, events and indexes, not measured. Measure database size on representative fixtures and test concurrency before choosing production compute. Disk allocation includes system/WAL space; row size estimates are not disk guarantees. Free is for development, Pro pricing and backup scope must be reviewed again before launch.
