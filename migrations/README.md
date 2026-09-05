# Dotfiles migrations

One-shot, idempotent fixups for machines running an older state of this repo.
Chezmoi keeps *files* in sync, but has no concept of "run this once to repair
a machine" — that's what this folder is for. The pattern is ported from
Omarchy's `migrations/` + `omarchy-migrate` (basecamp/omarchy), adapted onto
chezmoi instead of a package-managed install.

## Convention

- One script per migration: `<unix-timestamp>_<slug>.sh`.
- Migrations run in filename (timestamp) order, oldest first.
- Each script MUST be idempotent: check whether its change is already in
  place before doing anything, and exit 0 if so.
- Once a migration's filename is recorded in
  `~/.local/state/dotfiles/migrations-applied`, it never runs again on that
  machine, even if the script itself changes later.
- Migrations are plain `bash`, run directly (`bash "$script"`) — they do not
  need to be executable and are not materialized into `$HOME` by chezmoi
  (this whole directory is chezmoi-ignored).

## Running them

```bash
dots-migrate          # run any pending migrations now
dots-update           # also runs dots-migrate at the end, after syncing end4dots
```

## Adding one

```bash
ts=$(date +%s)
$EDITOR ~/.dotfiles/migrations/${ts}_short-description.sh
```

Write it defensively — assume it may run on a machine that's already correct,
and assume `set -euo pipefail` is on unless you have a reason to opt out.
