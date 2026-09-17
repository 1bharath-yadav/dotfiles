# datui
> High-performance terminal UI for inspecting, filtering, querying, and charting large tabular datasets.

## Last Refreshed
2026-09-17

## Why I Use It
Datui provides Polars-backed lazy data exploration directly in the terminal, eliminating the need to launch Python notebooks or heavy desktop spreadsheet tools just to inspect CSV, TSV, Parquet, JSONL, and Arrow datasets.

## Config Choices
- `file_loading.parse_dates = true` — automatically detects and parses date/datetime strings for instant chronological sorting (upstream docs).
- `file_loading.parse_strings = true` — trims whitespace and infers numeric/boolean types for cleaner schema detection (upstream docs).
- `file_loading.infer_schema_length = 10000` — samples 10k rows instead of default 1k to prevent type mismatches on heterogeneous columns (personal).
- `display.row_numbers = true` — 1-indexed row numbers visible by default; toggleable with `N` (personal).
- `display.dtype_row = true` — displays column type markers `[str]`, `[i64]`, `[f64]` beneath column headers; toggleable with `D` (upstream docs).
- `display.number_format.grouping = "thousands"` — groups large integers and floats with commas (`1,234,567`) while exempting identifiers, years, and codes (upstream docs).
- `display.pages_lookahead/lookback = 4` — smoother buffer scrolling without lag (personal).
- `performance.event_poll_interval_ms = 16` — ~60 FPS event loop polling for snappy keyboard interaction (personal).
- `performance.polars_streaming = true` — uses streaming engine to reduce RAM footprint on large tables (upstream docs).
- `performance.sampling_threshold = 2000000` — preserves full dataset analysis up to 2M rows before sampling (personal).
- `templates.auto_apply = true` — automatically applies saved sort/filter/freeze templates when matching datasets are opened (upstream docs).
- `theme.colors` — dark terminal theme harmonized with Kitty.

## 20% That Matters (daily usage)
| What | How |
|---|---|
| Open file or directory | `datui [path]` |
| Trending GitHub repos | `trending-repos` |
| Navigation (Vim keys) | `h` / `j` / `k` / `l` or Arrows |
| Page up / down | `PgUp` / `PgDn` or `Ctrl-b` / `Ctrl-f` |
| Half page up / down | `Ctrl-u` / `Ctrl-d` |
| Jump to top / bottom | `Home` / `End` or `G` |
| Jump to row number | `:` |
| Search / Query (SQL, Fuzzy) | `/` |
| Sort & filter menu | `s` |
| Reset sort/filter/columns | `R` |
| Toggle number formatting | `F` |
| Toggle row numbers | `N` |
| Toggle column types row | `D` |
| Open Chart view | `c` |
| Open Summary analysis | `a` |
| Home screen | `Ctrl-o` |
| Quit | `q` or `Ctrl-q` |

## Known Quirks
- Standard input pipes do not provide a TUI tty; use temporary files or process substitution via helper scripts like `trending-repos`.
- Datui is read-only by design; transformation and reshaped views are exported via `e`.

## Skipped / Rejected Options
- `file_loading.decompress_in_memory`: Kept `false` to avoid memory exhaustion on multi-gigabyte compressed files.
- `data.search.cross_filesystems`: Kept `false` to avoid slow walks across network mounts or autofs triggers.

## Sources
- https://derekwisong.github.io/datui/
- https://github.com/derekwisong/datui
