#!/usr/bin/env bash
#
# MyVPS one-line installer / updater
#
#   curl -fsSL https://raw.githubusercontent.com/huynhlongdai/dkvpsp/main/get.sh | sudo bash
#   curl -fsSL https://raw.githubusercontent.com/huynhlongdai/dkvpsp/main/get.sh | sudo bash -s -- --profile lite --ssh-port 2222
#
# Already installed?  The same line updates MyVPS in place (no secrets rotated).
#
# Options (each also has an env var, handy for fleets / cloud-init):
#   --profile lite|standard   MYVPS_PROFILE     (default: auto from RAM, <=1.5 GB = lite)
#   --php 8.3                 MYVPS_PHP_VERSION
#   --ssh-port N              MYVPS_SSH_PORT    (default: keep current port)
#   --no-firewall             MYVPS_SKIP_FIREWALL=1
#   --no-sshd                 MYVPS_SKIP_SSHD=1 (do not touch sshd_config)
#   --no-https                MYVPS_NGINX_HTTPS=0 (auto when :443 is taken)
#   --skip-upgrade            MYVPS_SKIP_UPGRADE=1 (no full apt/dnf upgrade)
#   --version X.Y.Z           MYVPS_RELEASE     (default: latest)
#   --mirror URL              MYVPS_MIRROR      (where get.sh, latest, myvps-*.tar.gz live)
#   --reinstall               MYVPS_FORCE_REINSTALL=1 (full reinstall, new secrets)
#   --dry-run                 only run the pre-flight checks
#
set -Eeuo pipefail

MIRROR="${MYVPS_MIRROR:-https://raw.githubusercontent.com/huynhlongdai/dkvpsp/main}"
RELEASE="${MYVPS_RELEASE:-latest}"
DRY_RUN=0
LOG=/var/log/myvps-install.log

c_red='\033[0;31m'; c_grn='\033[0;32m'; c_yel='\033[1;33m'; c_cyn='\033[0;36m'; c_off='\033[0m'
say()  { echo -e "${c_cyn}==>${c_off} $*"; }
ok()   { echo -e "${c_grn}[OK]${c_off} $*"; }
warn() { echo -e "${c_yel}[WARN]${c_off} $*"; }
die()  { echo -e "${c_red}[ERROR]${c_off} $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)      export MYVPS_PROFILE="${2:?}"; shift ;;
        --php)          export MYVPS_PHP_VERSION="${2:?}"; shift ;;
        --ssh-port)     export MYVPS_SSH_PORT="${2:?}"; shift ;;
        --no-firewall)  export MYVPS_SKIP_FIREWALL=1 ;;
        --no-sshd)      export MYVPS_SKIP_SSHD=1 ;;
        --no-https)     export MYVPS_NGINX_HTTPS=0 ;;
        --skip-upgrade) export MYVPS_SKIP_UPGRADE=1 ;;
        --version)      RELEASE="${2:?}"; shift ;;
        --mirror)       MIRROR="${2:?}"; shift ;;
        --reinstall)    export MYVPS_FORCE_REINSTALL=1 ;;
        --dry-run)      DRY_RUN=1 ;;
        -y|--yes)       ;;
        -h|--help)      sed -n '2,24p' "$0" 2>/dev/null || true; exit 0 ;;
        *) die "Unknown option: $1 (see --help)" ;;
    esac
    shift
done
MIRROR="${MIRROR%/}"
[[ "$MIRROR" == *"__MIR""ROR__"* ]] && die "No mirror configured: pass --mirror URL or MYVPS_MIRROR"
[[ "$RELEASE" == latest || "$RELEASE" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Bad --version: $RELEASE"
[[ -z "${MYVPS_PROFILE:-}" || "$MYVPS_PROFILE" =~ ^(lite|standard)$ ]] || die "--profile must be lite or standard"
[[ -z "${MYVPS_SSH_PORT:-}" || "$MYVPS_SSH_PORT" =~ ^[0-9]+$ ]] || die "--ssh-port must be a number"

# ------------------------------------------------------------------
# Pre-flight: fail in seconds, not after 5 minutes of apt
# ------------------------------------------------------------------
[[ $EUID -eq 0 ]] || die "Run as root: curl -fsSL $MIRROR/get.sh | sudo bash"
[[ -r /etc/os-release ]] || die "Cannot detect OS (/etc/os-release missing)"
# shellcheck disable=SC1091
. /etc/os-release
OS="$ID"; VER="${VERSION_ID%%.*}"
case "$OS:$VER" in
    ubuntu:20|ubuntu:22|ubuntu:24|debian:11|debian:12|debian:13|almalinux:8|almalinux:9|rocky:8|rocky:9) ;;
    *) die "Unsupported OS: ${PRETTY_NAME:-$OS $VERSION_ID}. Supported: Ubuntu 20/22/24, Debian 11/12/13, AlmaLinux/Rocky 8/9" ;;
esac
ok "OS: ${PRETTY_NAME:-$OS $VERSION_ID}"

case "$(uname -m)" in x86_64|amd64|aarch64|arm64) ;; *) die "Unsupported CPU arch: $(uname -m)" ;; esac
[[ "$(ps -p 1 -o comm= 2>/dev/null)" == systemd ]] || die "systemd is required as PID 1 (OpenVZ/plain docker are not supported)"

VIRT=$(systemd-detect-virt 2>/dev/null || echo none)
if systemd-detect-virt -cq 2>/dev/null; then
    export MYVPS_ZRAM="${MYVPS_ZRAM:-0}"   # containers share the host kernel: no zram
    warn "Container detected ($VIRT): zram disabled, swap left to the host"
fi

RAM_MB=$(( $(awk '/MemTotal/{print $2}' /proc/meminfo) / 1024 ))
# honour cgroup limits (LXC/KVM-in-container VPS report host RAM in /proc/meminfo)
_cg="/sys/fs/cgroup$(awk -F: '$1=="0"{print $3}' /proc/self/cgroup 2>/dev/null || true)"
while [[ "$_cg" == /sys/fs/cgroup* ]]; do
    _l=$(cat "$_cg/memory.max" 2>/dev/null || true)
    [[ "$_l" =~ ^[0-9]+$ ]] && (( _l / 1048576 < RAM_MB )) && RAM_MB=$(( _l / 1048576 ))
    [[ "$_cg" == /sys/fs/cgroup ]] && break
    _cg="${_cg%/*}"
done
DISK_MB=$(df -Pm / | awk 'NR==2{print $4}')
CPUS=$(nproc)
(( RAM_MB >= 450 )) || die "Need at least 512 MB RAM (found ${RAM_MB} MB)"
(( DISK_MB >= 2500 )) || die "Need at least 2.5 GB free on / (found ${DISK_MB} MB)"
ok "Resources: ${CPUS} vCPU, ${RAM_MB} MB RAM, ${DISK_MB} MB free disk, virt=${VIRT}"

INSTALLED=0
[[ -f /etc/myvps/.myvps.conf ]] && INSTALLED=1
[[ "${MYVPS_FORCE_REINSTALL:-0}" == 1 ]] && INSTALLED=0

port_owner() { { ss -Hltnp "sport = :$1" 2>/dev/null || true; } | sed -n 's/.*users:(("\([^"]*\)".*/\1/p' | head -1; }
if (( ! INSTALLED )); then
    for p in apache2 httpd lsws cpanel plesk-php83-fpm cyberpanel aapanel bt; do
        systemctl is-active -q "$p" 2>/dev/null && die "Another web stack/panel is running ($p). Use a fresh VPS."
    done
    [[ -d /usr/local/cpanel || -d /www/server/panel || -d /usr/local/CyberCP ]] && die "Another control panel is installed. Use a fresh VPS."
    if command -v ss >/dev/null; then
        o=$(port_owner 80);  [[ -z "$o" || "$o" == nginx ]] || die "Port 80 is used by '$o'. Free it first."
        o=$(port_owner 443)
        if [[ -n "$o" && "$o" != nginx ]]; then
            export MYVPS_NGINX_HTTPS=0
            warn "Port 443 is used by '$o': nginx will not bind :443 (MYVPS_NGINX_HTTPS=0)"
        fi
    fi
    # Keep the current SSH port unless told otherwise (no interactive prompt over a pipe)
    if [[ -z "${MYVPS_SSH_PORT:-}" ]]; then
        cur=$( { sshd -T 2>/dev/null || true; } | awk '/^port /{print $2; exit}')
        export MYVPS_SSH_PORT="${cur:-22}"
    fi
fi

if (( DRY_RUN )); then
    ok "Pre-flight passed ($([[ $INSTALLED == 1 ]] && echo 'would update' || echo 'would install'))"
    exit 0
fi

exec 9>/run/myvps-get.lock
flock -n 9 || die "Another MyVPS install/update is already running"

# ------------------------------------------------------------------
# Tools needed to fetch + verify
# ------------------------------------------------------------------
need=()
for b in curl tar sha256sum flock; do command -v "$b" >/dev/null || need+=("$b"); done
if (( ${#need[@]} )); then
    say "Installing prerequisites: ${need[*]}"
    if command -v apt-get >/dev/null; then
        DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=600 update -qq </dev/null
        DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=600 install -y -qq curl tar coreutils util-linux </dev/null >/dev/null
    else
        dnf install -y -q curl tar coreutils util-linux </dev/null
    fi
fi

fetch() { curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 15 ${MYVPS_TOKEN:+-H "Authorization: Bearer $MYVPS_TOKEN"} "$1" -o "$2"; }

# ------------------------------------------------------------------
# Download + verify release
# ------------------------------------------------------------------
TMP=$(mktemp -d /tmp/myvps-get.XXXXXX)
trap 'rm -rf "$TMP"' EXIT

if [[ "$RELEASE" == latest ]]; then
    fetch "$MIRROR/latest" "$TMP/latest" || die "Cannot reach $MIRROR/latest"
    read -r RELEASE SUM < "$TMP/latest"
else
    fetch "$MIRROR/myvps-$RELEASE.tar.gz.sha256" "$TMP/sum" || die "Release $RELEASE not found on mirror"
    read -r SUM _ < "$TMP/sum"
fi
[[ "$RELEASE" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$SUM" =~ ^[0-9a-f]{64}$ ]] || die "Mirror returned a malformed release index"

say "Downloading MyVPS $RELEASE"
fetch "$MIRROR/myvps-$RELEASE.tar.gz" "$TMP/myvps.tar.gz" || die "Download failed"
echo "$SUM  $TMP/myvps.tar.gz" | sha256sum -c --quiet - || die "Checksum mismatch: refusing to install"
ok "Checksum verified"

DEST=/opt/myvps/releases/$RELEASE
rm -rf "$DEST.new" && mkdir -p "$DEST.new"
tar -xzf "$TMP/myvps.tar.gz" -C "$DEST.new" --strip-components=1 --no-same-owner
[[ -f "$DEST.new/install.sh" && -f "$DEST.new/cli/myvps" ]] || die "Release archive is incomplete"
rm -rf "$DEST" && mv "$DEST.new" "$DEST"
ln -sfn "$DEST" /opt/myvps/src
# keep the 3 newest releases
ls -1d /opt/myvps/releases/*/ 2>/dev/null | sort -V | head -n -3 | xargs -r rm -rf

mkdir -p /etc/myvps
printf 'mirror=%s\nrelease=%s\n' "$MIRROR" "$RELEASE" > /etc/myvps/release

if (( INSTALLED )); then
    say "MyVPS is already installed: updating to $RELEASE"
    rm -rf "$TMP"; trap - EXIT
    exec bash "$DEST/cli/myvps" update --from "$DEST"
fi

say "Installing MyVPS $RELEASE (log: $LOG). This takes ~5 minutes on a small VPS."
umask 077; : > "$LOG"; umask 022
START=$(date +%s)
set +e
bash "$DEST/install.sh" < /dev/null 2>&1 | tee -a "$LOG"
rc=${PIPESTATUS[0]}
set -e
(( rc == 0 )) || die "Install failed (exit $rc). Last lines are above; full log: $LOG"
ok "Installed in $(( $(date +%s) - START ))s. Credentials: /etc/myvps/.info.conf  |  Menu: myvps"
