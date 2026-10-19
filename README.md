# MyVPS installer

Install on a fresh Ubuntu 20/22/24, Debian 11/12/13, AlmaLinux/Rocky 8/9 VPS:

```bash
curl -fsSL https://raw.githubusercontent.com/huynhlongdai/dkvpsp/main/get.sh | sudo bash
```

Options: `--profile lite|standard`, `--php 8.3`, `--ssh-port 2222`, `--no-firewall`,
`--no-sshd`, `--no-https`, `--skip-upgrade`, `--version X.Y.Z`, `--dry-run`.

Already installed? Run the same line (or `myvps update`) to update.
Every release is checked against its sha256 before it is installed.
