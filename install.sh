#!/usr/bin/env bash
#
# Darkian Studio — runtime setup script
#
# Installs the DS toolchain (node, dsterm, git-pnp, code-server) for the
# current platform. DS invokes this from onboarding; users can also run it
# manually in Termux / a Linux shell / macOS.
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
  log "Installing nodejs, git, curl, code-server…"
  pkg install -y nodejs git curl code-server || die "Package install failed."
}

install_linux() {
  log "Detected Linux."
  if command -v apt-get >/dev/null 2>&1; then
    sudo -v >/dev/null 2>&1 || warn "sudo not available; some steps may fail."
    log "Installing via apt…"
    sudo apt-get update -y || warn "apt-get update returned non-zero."
    sudo apt-get install -y nodejs npm git curl || die "apt install failed."
    install_code_server_deb
  elif command -v pacman >/dev/null 2>&1; then
    log "Installing via pacman…"
    sudo pacman -Syu --noconfirm nodejs npm git curl code-server \
      || die "pacman install failed."
  elif command -v dnf >/dev/null 2>&1; then
    log "Installing via dnf…"
    sudo dnf install -y nodejs git curl code-server \
      || die "dnf install failed."
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
  log "Installing node, git, curl, code-server…"
  brew install node git curl code-server || die "brew install failed."
}

# ---- dsterm (DS-managed runtime helper) -----------------------------------
install_dsterm() {
  if command -v dsterm >/dev/null 2>&1; then
    ok "dsterm already installed ($(command -v dsterm))."
    return
  fi
  log "Installing dsterm (DS runtime helper)…"
  local dsterm_home="$HOME/.ds"
  mkdir -p "$dsterm_home"
  # dsterm is a small shell-based helper shipped with DS. When the DS-managed
  # distribution is present it is installed via the bundled asset; otherwise we
  # provision a minimal wrapper so node/git tooling is discoverable.
  cat > "$dsterm_home/dsterm" <<'EOF'
#!/usr/bin/env bash
# Minimal dsterm shim — delegates to the DS-managed runtime.
exec node "$HOME/.ds/dsterm.js" "$@"
EOF
  chmod +x "$dsterm_home/dsterm"
  ok "dsterm shim written to $dsterm_home/dsterm (replace with DS-managed bundle)."
}

# ---- verification --------------------------------------------------------
verify_runtime() {
  local missing=()
  for tool in node git curl; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      missing+=("$tool")
    fi
  done
  # code-server and dsterm are optional-but-recommended for full IDE features.
  for tool in code-server dsterm; do
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
