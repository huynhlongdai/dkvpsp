# DKVPS installer

Install on a fresh Ubuntu 20/22/24, Debian 11/12/13, AlmaLinux/Rocky 8/9 VPS:

```bash
curl -fsSL https://raw.githubusercontent.com/huynhlongdai/dkvpsp/main/get.sh | sudo bash
```

Then run `dkvps` (works from a sudo user too; `myvps` is kept as an alias).

Options: `--profile lite|standard`, `--php 8.3`, `--ssh-port 2222`, `--no-firewall`,
`--no-sshd`, `--no-https`, `--skip-upgrade`, `--version X.Y.Z`, `--dry-run`, `--reinstall`.

Already installed? Run the same line (or `dkvps update`) to update.
Coming from MyVPS 1.x (the old name)? Add `--reinstall` (new secrets; sites and databases stay).
Every release is checked against its sha256 before it is installed.
