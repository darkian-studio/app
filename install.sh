#!/usr/bin/env bash
#
# Darkian Studio — runtime setup script
#
# Installs the DS toolchain (node, dsterm, git-pnp, code-server, netcat,
# python) for the current platform. DS only shows this command during
# onboarding — it does not run or manage this script. Run it yourself in
# Termux / a Linux shell / macOS.
#
#   curl -fsSL https://raw.githubusercontent.com/darkian-studio/app/main/install.sh | bash
#
# Design goals:
#   * Runtime aware: picks the correct package manager / commands per OS.
#   * Clear progress and error messages at every step.
#   * Idempotent: re-running skips already-installed components.
#   * Verifies the runtime is usable before reporting success.
#
set -euo pipefail

# ---- colors ---------------------------------------------------------------
if [ -t 1 ]; then
  C_RESET='\033[0m'; C_BOLD='\033[1m'; C_DIM='\033[2m'
  C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_RED='\033[31m'; C_BLUE='\033[34m'
else
  C_RESET=''; C_BOLD=''; C_DIM=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_BLUE=''
fi

log()  { printf "${C_BLUE}[DS]${C_RESET} %s\n" "$*"; }
ok()   { printf "${C_GREEN}[OK]${C_RESET} %s\n" "$*"; }
warn() { printf "${C_YELLOW}[WARN]${C_RESET} %s\n" "$*" >&2; }
err()  { printf "${C_RED}[ERR]${C_RESET} %s\n" "$*" >&2; }
die()  { err "$*"; exit 1; }

# ---- platform detection ---------------------------------------------------
detect_platform() {
  local uname_os
  uname_os="$(uname -s 2>/dev/null || echo unknown)"
  case "$uname_os" in
    Linux*)  PLATFORM='linux' ;;
    Darwin*) PLATFORM='macos' ;;
    *)       PLATFORM='unknown' ;;
  esac

  # Termux presents as Linux but is a distinct, package-managed environment.
  if [ "$PLATFORM" = 'linux' ] && command -v termux-info >/dev/null 2>&1; then
    PLATFORM='termux'
  fi
}

# ---- per-platform installers ---------------------------------------------
install_termux() {
  log "Detected Termux — using pkg + tur-repo."
  log "Refreshing package lists…"
  pkg update -y || warn "pkg update returned non-zero; continuing."
  # tur-repo provides code-server on Termux.
  if ! pkg list-installed 2>/dev/null | grep -q '^tur-repo/'; then
    log "Installing tur-repo…"
    pkg install -y tur-repo || die "Failed to install tur-repo."
  fi
  pkg update -y || warn "pkg update (post tur-repo) returned non-zero."
  log "Installing nodejs, git, curl, code-server, netcat, python…"
  pkg install -y nodejs git curl code-server netcat-openbsd python || die "Package install failed."
  install_git_pnp
}

install_linux() {
  log "Detected Linux."
  if command -v apt-get >/dev/null 2>&1; then
    sudo -v >/dev/null 2>&1 || warn "sudo not available; some steps may fail."
    log "Installing via apt…"
    sudo apt-get update -y || warn "apt-get update returned non-zero."
    sudo apt-get install -y nodejs npm git curl netcat-openbsd python3 python3-pip || die "apt install failed."
    install_code_server_deb
    install_git_pnp
  elif command -v pacman >/dev/null 2>&1; then
    log "Installing via pacman…"
    sudo pacman -Syu --noconfirm nodejs npm git curl code-server gnu-netcat python python-pip \
      || die "pacman install failed."
    install_git_pnp
  elif command -v dnf >/dev/null 2>&1; then
    log "Installing via dnf…"
    sudo dnf install -y nodejs git curl code-server nmap-ncat python3 python3-pip \
      || die "dnf install failed."
    install_git_pnp
  else
    warn "No supported package manager found (apt/pacman/dnf)."
    warn "Install node, git, curl, and code-server manually, then re-run."
  fi
}

install_code_server_deb() {
  if command -v code-server >/dev/null 2>&1; then return; fi
  log "code-server not in apt repos — fetching the latest release…"
  local url
  url="$(curl -fsSL https://api.github.com/repos/coder/code-server/releases/latest \
    | grep -o 'https://github.com/coder/code-server/releases/download/[^"]*linux-amd64.deb' \
    | head -n1)" || true
  if [ -z "${url:-}" ]; then
    warn "Could not resolve code-server .deb URL; skipping code-server."
    return
  fi
  local tmp; tmp="$(mktemp --suffix=.deb)"
  curl -fsSL "$url" -o "$tmp" || { warn "code-server download failed; skipping."; return; }
  sudo apt-get install -y "$tmp" || warn "code-server install failed; skipping."
  rm -f "$tmp"
}

install_macos() {
  log "Detected macOS."
  if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
      || die "Homebrew install failed."
  fi
  log "Installing node, git, curl, code-server, netcat, python…"
  brew install node git curl code-server netcat python || die "brew install failed."
  install_git_pnp
}

# ---- git-pnp (git push & publish CLI) -------------------------------------
install_git_pnp() {
  if command -v git-pnp >/dev/null 2>&1 || python3 -m pip show git-pnp >/dev/null 2>&1; then
    ok "git-pnp already installed."
    return
  fi
  log "Installing git-pnp (pip)…"
  if command -v pip >/dev/null 2>&1; then
    pip install --user git-pnp || pip install git-pnp || warn "pip install git-pnp failed."
  elif command -v pip3 >/dev/null 2>&1; then
    pip3 install --user git-pnp || pip3 install git-pnp || warn "pip3 install git-pnp failed."
  elif command -v python3 >/dev/null 2>&1; then
    python3 -m pip install --user git-pnp || python3 -m pip install git-pnp \
      || warn "python3 -m pip install git-pnp failed."
  else
    warn "No pip/python available — skipping git-pnp. Install it manually: pip install git-pnp"
  fi
}

# ---- dsterm (local PTY / bridge server DS connects to) ---------------------
install_dsterm() {
  if command -v dsterm >/dev/null 2>&1; then
    ok "dsterm already installed ($(command -v dsterm))."
    return
  fi
  log "Installing dsterm (must be running locally for DS to connect)…"
  curl -L https://raw.githubusercontent.com/darkian-studio/dsterm/main/install.sh | bash \
    || warn "dsterm install failed; run it manually: curl -L https://raw.githubusercontent.com/darkian-studio/dsterm/main/install.sh | bash"
  ok "dsterm install invoked."
}

# ---- verification --------------------------------------------------------
verify_runtime() {
  local missing=()
  for tool in node git curl; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      missing+=("$tool")
    fi
  done
  # code-server, dsterm, python and git-pnp are recommended for full DS features.
  for tool in code-server dsterm python3 python git-pnp; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      warn "$tool not found — some DS features may be limited."
    fi
  done

  if [ "${#missing[@]}" -gt 0 ]; then
    die "Missing required tools: ${missing[*]}. Setup incomplete."
  fi

  log "Verifying node runtime…"
  node --version | sed 's/^/  node /'
  ok "Runtime verification passed."
}

# ---- main -----------------------------------------------------------------
main() {
  printf "${C_BOLD}Darkian Studio runtime setup${C_RESET}\n"
  detect_platform

  case "$PLATFORM" in
    termux) install_termux ;;
    linux)  install_linux ;;
    macos)  install_macos ;;
    *)      die "Unsupported platform: $(uname -s 2>/dev/null). Supported: Termux, Linux, macOS." ;;
  esac

  install_dsterm
  verify_runtime

  printf "\n${C_GREEN}Setup complete.${C_RESET} Open Darkian Studio and start coding.\n"
  printf "${C_DIM}Report issues at https://github.com/darkian-studio/app/issues${C_RESET}\n"
}

main "$@"
