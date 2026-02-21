#!/usr/bin/env bash
# Bootstrap dotfiles with Nix + home-manager.
#
# Usage:
#   ./install.sh              # auto-detects OS, uses alex@linux or alex@darwin
#   ./install.sh alex@linux   # explicit profile
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="${1:-}"

# ── 1. Detect profile ────────────────────────────────────────────────────────
if [[ -z "$PROFILE" ]]; then
  if [[ "$(uname)" == "Darwin" ]]; then
    PROFILE="alex@darwin"
  else
    case "$(uname -m)" in
      aarch64|arm64) PROFILE="alex@linux-aarch64" ;;
      *)             PROFILE="alex@linux" ;;
    esac
  fi
fi
echo "==> Using profile: $PROFILE"

# ── 2. Install Nix (if missing) ──────────────────────────────────────────────
if ! command -v nix &>/dev/null; then
  echo "==> Installing Nix via Determinate Nix Installer..."
  curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix | sh -s -- install
  # Source nix into current shell
  # shellcheck disable=SC1091
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
else
  echo "==> Nix already installed: $(nix --version)"
fi

# ── 3. Warn if dotfiles are not at ~/dotfiles ────────────────────────────────
if [[ "$DOTFILES_DIR" != "$HOME/dotfiles" ]]; then
  echo "WARNING: dotfiles found at $DOTFILES_DIR, not ~/dotfiles."
  echo "         Out-of-store symlinks in neovim/zed/hyprland modules"
  echo "         assume ~/dotfiles. Consider re-cloning there."
fi

# ── 4. Apply home-manager configuration ─────────────────────────────────────
echo "==> Applying home-manager configuration for $PROFILE..."
nix run home-manager -- switch --flake "${DOTFILES_DIR}#${PROFILE}"

echo ""
echo "Done. Open a new shell to pick up fish and all installed tools."
echo ""
echo "  Rebuild:        nix run home-manager -- switch --flake ~/dotfiles#${PROFILE}"
echo "  Update inputs:  nix flake update ~/dotfiles"
