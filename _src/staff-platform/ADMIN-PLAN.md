# Platform administration implementation plan

Approved scope from conversation: platform administrator adds/views/archives cafes, manages owner invitations and sees aggregate statistics; no order list. Existing Supabase project and auth entry remain; Sun&Sea is independent. Use current warm neutral/copper visual language, responsive cards and dialogs. No alternative design approval needed: user explicitly asked to continue the described cabinet.

1. Add private platform-admin registry, email-bound invitation hashes and administrative audit. All access checked against auth.uid and current confirmed email, never user metadata. Install closed functions first.
2. Transaction tests under actual authenticated/anon roles: ordinary user cannot administer; wrong/unconfirmed email cannot redeem; expired/revoked/reused tokens fail; replay cafe creation safe; archiving preserves aggregates; no operational order rows in admin response.
3. Build admin list/detail/forms, server-only mutations, copyable one-use invite URL, archive/restore/revoke. Aggregate actual order/payments by date/currency; menu visits explicitly unavailable until instrumentation.
4. Integrate authenticated route and invitation acceptance after email confirmation. Show error/empty/loading independently, guard stale requests, no fake local success. Finish email-sent dialog already requested.
5. Build and browser-check. Obtain action-time approval for assigning first platform admin and enabling authenticated RPC, then verify using user's signed-in session. Publish and document remaining SMTP/operational app work. Do not claim live staff application complete.
