# Sun&Sea print files

The table plan in `_src/sunsea/table-layout.json` is the source of truth: **1–8, 10–12, 14, 15, 18, 19, 22, 23** (17 tables).

`sunsea.py --links <private-table-links.json> --output-dir <directory>` creates five A4 sheets (four 90×130 mm cards per sheet) and a 17-page A6 PDF. The links JSON is a list of `{table, url}` records. Each URL contains `?t=<number>&room=<64 hex capability>`. Never commit these capability URLs or the print PDFs to the public source repository. Table tokens are provisioned in the existing Sites `TABLE_CAPABILITIES` secret as SHA-256(token) → table number. Preserve links for existing valid tables when updating numbering; do not clear their carts.

`sunsea-banner.py --art <background.png> --output-dir <directory>` creates the six-language A3 poster. Its public QR always points to `https://dellviktoriapro.github.io/qr-menu/sun-sea/?view=preview` (browse and reserve, no cart).

Python dependencies: Pillow, ReportLab, qrcode. Windows fonts: Georgia, Arial, Malgun Gothic, Microsoft YaHei. `SUNSEA_QR_LIB` optionally identifies an existing local qrcode dependency directory.

PDFs use vector QR modules, medium error correction and a full four-module white quiet zone. Never place art or a logo over the QR. Table-card instructions are RU / EN / VI / DE / KO / ZH. Artwork reuses the menu's hero and right-side coastal silhouette.

Current print outputs are in the task workspace `outputs/`, with stable filenames `sunsea-table-qr.pdf`, `sunsea-table-qr-A6.pdf`, `sunsea-table-qr-images.zip`, `sunsea-menu-languages-A3.pdf` and its 300 dpi PNG. Print at actual size / 100%. All 17 A4 codes and 17 exported A6 PNGs were decoded and compared to their exact table URLs; all 17 live API responses matched their printed table number. The A3 QR was independently decoded and checked for public-preview mode.
