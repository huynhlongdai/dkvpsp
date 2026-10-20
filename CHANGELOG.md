# DKVPS changelog

Each `## X.Y.Z` section is shown before an update (`dkvps update`, get.sh on an installed server, DKVPS Hub).

## 2.1.4 (2026-10-20)
- Updates never run by themselves: `dkvps update` shows the version change and this changelog first and asks for confirmation (`-y` to skip).
- `dkvps update preview` shows what would be updated without changing anything.
- get.sh on an installed server shows the same preview and asks before updating (`--yes` for scripts).
- DKVPS Hub: update dialogs list each server's current -> new version and the changes before anything is queued.

## 2.1.3 (2026-10-20)
- Fix: `dkvps help` and unknown commands crashed (show_help defined too late).

## 2.1.2 (2026-10-20)
- New `dkvps check`: license refresh with the hub + new version lookup (`--json` supported). Only checks, never updates.
- Main menu shows the version and license state; a daily cron refreshes that cached check.
- DKVPS Hub: latest release, servers needing an update, license problems, per-server check.

## 2.1.1 (2026-10-20)
- License is entered from the menu (`dkvps` -> 24 License); the installer no longer takes `--license`/`--hub`.

## 2.1.0 (2026-10-20)
- DKVPS Hub (license server + fleet manager), `dkvps license`, swap priority, install summary shows the real SSH user.

## 2.0.6 (2026-10-20)
- Apps: managed Node.js, pnpm/yarn/bun, build-time env, persistent data, native module build tools.

## 2.0.5 (2026-10-20)
- Lite profile masks PackageKit, node apps run without a resident npm, no first-visit 502 after adding a domain.

## 2.0.4 (2026-10-19)
- Domain rename, subfolder sites, IP-based domain, phpMyAdmin update, referrer spam blocking.

## 2.0.3 (2026-10-19)
- Laravel install, SSH port change with rollback, swap checks, rclone cloud backup.
