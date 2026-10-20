# DKVPS changelog

Each `## X.Y.Z` section is shown before an update (`dkvps update`, get.sh on an installed server, DKVPS Hub).

## 2.2.0 (2026-10-20)
- DKVPS Free (no key, forever): 1 domain + basic features. A license key unlocks unlimited domains + Pro. Register to get a 7-day Pro trial key (enter it in menu > License); when it ends the server goes back to Free.
- Servers that already have more domains keep all of them running; only adding new ones needs a key.
- Pro features: unlimited domains, encrypted cloud backup + schedule, migrate, staging, per-site CPU/RAM limits, private Redis per site, apps (Node/Bun/Python), webhook deploy, daily malware scan, Telegram bot, Cloudflare Under Attack/auto shield. Things already set up keep running.
- New `dkvps scan`: webshell/backdoor signatures, PHP files in uploads, modified WordPress core files; `--quarantine`, `scan restore`.
- New `dkvps doctor`: health check of services, configs, disk, RAM, OOM kills, SSL expiry, DNS, sites; `--md` writes a report to paste to an AI or support.
- New `dkvps admin open [hours]` (or `dkvps pma open`): phpMyAdmin on a random port with one-time login that closes itself; `dkvps admin lock` closes the permanent port 8080.
- New `dkvps db link <db> [minutes]`: one-off download link for a database dump, deleted after 15 minutes.
- New `dkvps hook on <domain>`: deploy on git push (GitHub/GitLab/Gitea), no resident process.
- New `dkvps guard`: nginx and MariaDB are protected when RAM runs out, PHP workers go first; enabled on update.
- New `dkvps nginx brotli on|off` (on by default for new installs).
- The daily license refresh cron is removed: the license refreshes when you use dkvps.
- Menu: new "Security & Tools" item; License menu lists what Pro adds.

## 2.1.5 (2026-10-20)
- No background checks: the daily check cron and the login update notice are removed.
- Version + license are checked only when you open `dkvps` (once per launch, a few seconds at most) or run `dkvps check`.

## 2.1.4 (2026-10-20)
- Updates never run by themselves: `dkvps update` shows the version change and this changelog first and asks for confirmation (`-y` to skip).
- `dkvps update preview` shows what would be updated without changing anything.
- get.sh on an installed server shows the same preview and asks before updating (`--yes` for scripts).
- DKVPS Hub: update dialogs list each server's current -> new version and the changes before anything is queued.

## 2.1.3 (2026-10-20)
- Fix: `dkvps help` and unknown commands crashed (show_help defined too late).

## 2.1.2 (2026-10-20)
- New `dkvps check`: license refresh with the hub + new version lookup (`--json` supported). Only checks, never updates.
- Main menu shows the version and license state.
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
