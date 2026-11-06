# Manual owner registration

Deployed to the development project on 2026-11-06 after explicit approval. Existing email flow remains active; SMTP is not configured.

Two invite modes. `email` retains confirmed-email redemption. `manual` uses an unguessable, email-bound, expiring invitation and creates a fresh unconfirmed Auth account through a server-only Edge Function. Password goes directly over HTTPS to the Edge Function and Auth Admin API, is not logged or stored by our code. An unconfirmed account cannot sign in. One registration reservation per invite limits abuse; failed or existing-email attempts require a new invitation or proper account recovery, never reset another person's password.

An eight-character request code is shown to the requester and platform admin. The admin must verify the person's identity via their established contact and compare code. Approval uses a verified admin JWT plus a live registry check, confirms only this account through Auth Admin API and then attaches cafe ownership. Database rechecks expiry/revocation/cafe state after the Auth call; failures leave no active membership. Replays cannot grant duplicate ownership.

Manual account confirmation means identity was approved by the administrator; it is not mailbox proof. A separate private manual_accounts registry blocks such accounts from automatic email-invite redemption, preventing an email-identity bypass. Do not globally disable email confirmation.

The function must deploy with gateway JWT verification disabled because registration precedes login; the registration branch authenticates with the secret invite and exact expected email, while approval explicitly validates the administrator JWT using Auth getUser. CORS is limited to the application origin, body capped at 8KB, raw credentials never logged. The built-in service-role secret stays only in the Edge Function environment. No service key is read, copied or embedded in the browser.

Required before enabling: real-role SQL tests, Edge handler tests (malformed/body cap/wrong token/no admin/duplicates/Auth errors), stale/revoked invite cases, password page user handoff, explicit approval for deploying this privileged endpoint and granting its service RPC. Owner operational screens and end-to-end Cafe Chez Oanh tests remain separate unfinished work.
