#!/usr/bin/env bash
set -euo pipefail

TODAY=$(date +%Y-%m-%d)
OUT="/home/archer/Sync/obsidian_vault/til/raw/${TODAY}-rss.md"

echo "# RSS Fetch - $TODAY" > "$OUT"

echo "## Arxiv CS.AI (Top 5)" >> "$OUT"
curl -s "https://export.arxiv.org/rss/cs.AI" | grep -oP '(?<=<title>).*?(?=</title>)' | head -6 | tail -5 | sed 's/^/- /' >> "$OUT" || true

echo "" >> "$OUT"
echo "## Hacker News (Top 5)" >> "$OUT"
curl -s "https://hnrss.org/frontpage" | grep -oP '(?<=<title><!\[CDATA\[).*?(?=\]\]></title>)' | head -6 | tail -5 | sed 's/^/- /' >> "$OUT" || \
curl -s "https://news.ycombinator.com/rss" | grep -oP '(?<=<title>).*?(?=</title>)' | head -6 | tail -5 | sed 's/^/- /' >> "$OUT" || true

echo "Fetched RSS into $OUT"
