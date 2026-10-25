# Sun&Sea: restore the complete ordering mode

The customer explicitly requested a reversible standalone sales mode on 24 October 2026.

## Restore when the customer asks

1. Change only `mode` in `_src/sunsea/service-mode.json` from `menu_only` to `full`.
2. Rebuild `_src/sunsea/build_web.py ../../sun-sea` from its source directory with PYTHONUTF8=1.
3. Verify and publish. Do not rebuild or rewrite the shared Chez Oanh engine.

This restores the original order sending, table selection, shared/separate check flow, live order statuses, bill requests, payment acknowledgements, tips and connection to the staff app. Full-mode UI and logic reference commit: `dba133a2e8f1fc1db9616b9c91b5d6e9bbe563c7`. Do not roll back the whole repository: the configuration switch preserves newer photos, design and loading improvements.

The original shared engine remains unmodified in `_src/chez/tpl.html`. Standalone behavior is isolated in `menu-only.js`, `shared-cart.js` and `menu-only.css` and is omitted entirely from full builds. `SUNSEA_SERVICE_MODE=full` is an optional build-time override for verification.

## Data separation

Full mode retains its original ss_cart/ss_wish/ss_ck/ss_guest/ss_tbl keys. Standalone mode uses ss_menu_cart/ss_menu_wish/ss_menu_ck/ss_menu_guest/ss_menu_tbl, so earlier full-mode state is not deleted or overwritten. Language and currency preferences remain shared. Standalone mode must never write to ss_inbox or send order/bill/payment notifications.

## Standalone QR setup

There is currently NO configured payment QR. The button honestly shows that it has not been added; it never displays a fake code or confirms a payment.

To attach the restaurant's real bank QR without the staff app, put its image into `_src/sunsea/amb/payment-qr.png` and set `paymentQr` in service-mode.json to `payment-qr.png`, then rebuild. An HTTPS image URL is also supported. Confirm the intended recipient before adding a real payment image. The amount is confirmed with the waiter; no basket estimate is presented as a final bill.

## Current standalone cart

+/- updates quantity/total locally. Selection survives reload on the same browser. Show the waiter opens a read-only bilingual list and keeps the cart. Clear uses the existing explicit confirmation. No shared cart across phones or server integration is implied.


## Shared table carts (activation pending)

The client requested a shared cart for all phones scanning one table QR, with optional separate named checks. This is implemented as a menu-only overlay in shared-cart.js, backed by a Sites D1 service. It activates only when `room` is present in the table QR; ordinary links retain local cart behavior. No staff app sending is restored.

Public server access was explicitly approved by the user on25October2026. The deployed server is now public, with access to each cart restricted by its table QR capability. Direct browser CORS and five-client synchronization checks against the hosted service pass. See AGENTS.md for exact Site ID, source checkout and remaining release steps.

Switching mode to full omits BOTH standalone client layers and restores the earlier full workflow, rather than migrating shared-server carts into staff orders. Existing cart data must not be sent to staff automatically during restoration.
