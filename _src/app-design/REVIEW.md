# Design review

Framed-sheet, seed 547027360. Explicit user palette overrides the normal achromatic/neutral-dark style budget; no unrelated colors added. Manrope handles Cyrillic/Vietnamese UI; Lora is restricted to the wordmark. Typeface and palette choices are intentional rather than inherited from existing UI.

Largest object in the queue is the actionable table ticket. Separate station progress is visible on every ticket. Labels, money and controls align to the same 16px inner edges; card rows reserve identical content space. Phone: redundant role dropdown removed; four labelled destinations replace a horizontal scrollbar; action targets stay 44px or taller. Tablet and phone overflow checks passed after opening dedicated responsive tabs.

First review fixed three issues: native horizontal/vertical scrollbars around navigation/tabs; a filtered queue occupying only one narrow column; low secondary-text contrast on the dusty-blue ground. All five text/action palette checks now meet 4.5:1 (minimums in check-palettes.cjs). Source lint: 0 failures and 0 warnings. The skill's terminal browser inspector was not used because browser interaction must use the CUA browser; rendered inspection and screenshots were performed there at desktop/tablet/mobile widths.

Interactions checked: independent bar completion changes exactly the eligible order to ready; waiter counts update from 2 cooking/2 ready to 1/3; analytics remains 660000 VND paid, 3 closed bills and 220000 VND average; mobile admin approval changes only its fixture; gallery switches palette/role and 390px preview. Fonts loaded locally; console has no prototype failures. All totals derive from sample lines, not live Supabase data.

The board has five palette directions and four role views. It is a visual choice, not a replacement for the unfinished server staff UI. No Auth, tokens, service keys, localStorage bridge or external requests to restaurant servers are included. Do not promote the chosen appearance into the running application until the user selects a direction.
