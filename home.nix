{
  pkgs,
  username,
  lib,
  inputs,
  ...
}:
{
  home.username = username;
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";

  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    wget
    curl
    unzip
    ripgrep
    fd
    bat
    eza
    fzf
    zoxide
    btop
    yazi
    lazygit
    bloaty

    git-lfs
    gh

    mermaid-cli

    cmake
    ninja
    pnpm
    starpls
    bazelisk
    (pkgs.writeShellScriptBin "bazel" ''
      exec ${lib.getExe pkgs.bazelisk} "$@"
    '')

    nodejs
    python3

    graphviz

    nil
    nixd

    inputs.codex-cli-nix.packages.${pkgs.system}.default
    claude-code
    opencode
  ];

  programs.home-manager.enable = true;

  home.activation.migrateLegacyDarwinAppsLink = lib.mkIf pkgs.stdenv.isDarwin (
    lib.hm.dag.entryBefore [ "installPackages" ] ''
      target="$HOME/Applications/Home Manager Apps"
      if [ -L "$target" ] && [[ "$(readlink "$target")" == /nix/store/* ]]; then
        run rm "$target"
      fi
    ''
  );

  home.activation.configureAiProviders = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        codex_dir="$HOME/.codex"
        codex_cfg="$codex_dir/config.toml"
        mkdir -p "$codex_dir"

        if [ -L "$codex_cfg" ]; then
          run rm "$codex_cfg"
          if [ -f "$codex_cfg.bak" ]; then
            run cp "$codex_cfg.bak" "$codex_cfg"
          fi
        fi

        if [ ! -f "$codex_cfg" ]; then
          touch "$codex_cfg"
        fi

        if ! grep -q '^\[model_providers\.aperture\]$' "$codex_cfg"; then
          cat >> "$codex_cfg" <<'EOF'

    [model_providers.aperture]
    name = "Tailscale Aperture"
    baseURL = "http://ai.siren-pollux.ts.net/v1"
    envKey = "TAILSCALE_APERTURE_API_KEY"
    EOF
        fi

        opencode_dir="$HOME/.config/opencode"
        opencode_cfg="$opencode_dir/opencode.json"
        mkdir -p "$opencode_dir"

        if [ -L "$opencode_cfg" ]; then
          run rm "$opencode_cfg"
        fi

        ${pkgs.python3}/bin/python3 <<'PY'
    import json
    import os
    from pathlib import Path

    path = Path(os.path.expanduser("~/.config/opencode/opencode.json"))

    try:
        data = json.loads(path.read_text()) if path.exists() else {}
    except Exception:
        data = {}

    data.setdefault("$schema", "https://opencode.ai/config.json")
    providers = data.setdefault("provider", {})
    providers["aperture"] = {
        "name": "Tailscale Aperture",
        "id": "aperture",
        "npm": "@ai-sdk/openai-compatible",
        "api": "http://ai.siren-pollux.ts.net/v1",
        "env": ["TAILSCALE_APERTURE_API_KEY"],
        "models": {
            "anthropic/claude-sonnet-4.6": {
                "id": "anthropic/claude-sonnet-4.6",
                "name": "Claude Sonnet 4.6"
            },
            "deepseek/deepseek-v3.2": {
                "id": "deepseek/deepseek-v3.2",
                "name": "DeepSeek V3.2"
            },
            "google/gemini-3-flash-preview": {
                "id": "google/gemini-3-flash-preview",
                "name": "Gemini 3 Flash Preview"
            },
            "google/gemini-3.1-pro-preview": {
                "id": "google/gemini-3.1-pro-preview",
                "name": "Gemini 3.1 Pro Preview"
            },
            "minimax/minimax-m2.7": {
                "id": "minimax/minimax-m2.7",
                "name": "MiniMax M2.7"
            },
            "moonshotai/kimi-k2.5": {
                "id": "moonshotai/kimi-k2.5",
                "name": "Kimi K2.5"
            },
            "moonshotai/kimi-k2.6": {
                "id": "moonshotai/kimi-k2.6",
                "name": "Kimi K2.6"
            },
            "openai/gpt-5.4": {
                "id": "openai/gpt-5.4",
                "name": "GPT-5.4"
            },
            "openai/gpt-oss-120b": {
                "id": "openai/gpt-oss-120b",
                "name": "GPT OSS 120B"
            },
            "xiaomi/mimo-v2-pro": {
                "id": "xiaomi/mimo-v2-pro",
                "name": "MiMo V2 Pro"
            },
            "z-ai/glm-5": {
                "id": "z-ai/glm-5",
                "name": "GLM-5"
            },
            "z-ai/glm-5.1": {
                "id": "z-ai/glm-5.1",
                "name": "GLM-5.1"
            }
        },
        "options": {
            "baseURL": "http://ai.siren-pollux.ts.net/v1"
        }
    }

    path.write_text(json.dumps(data, indent=2) + "\n")
    PY
  '';

  home.sessionPath = [
    "$HOME/dotfiles/bin"
    "$HOME/.local/bin"
  ];

  imports = [
    ./modules/fish.nix
    ./modules/git.nix
    ./modules/ghostty.nix
    ./modules/helix.nix
    ./modules/tmux.nix
    ./modules/nas-mount.nix
  ];
}
