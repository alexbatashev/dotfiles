{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.aiAgents;

  skillDirs = [ ../agents/skills ] ++ cfg.extraSkillDirs;

  skillsIn =
    dir:
    lib.mapAttrs (name: _: dir + "/${name}") (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir)
    );

  skills = lib.foldl' (acc: dir: acc // skillsIn dir) { } skillDirs;

  linkSkills =
    prefix: lib.mapAttrs' (name: src: lib.nameValuePair "${prefix}/${name}" { source = src; }) skills;
in
{
  options.programs.aiAgents = {
    instructions = lib.mkOption {
      type = lib.types.path;
      default = ../agents/AGENTS.md;
      description = "Shared agent instructions, linked as CLAUDE.md for Claude Code and AGENTS.md elsewhere.";
    };

    extraSkillDirs = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      example = lib.literalExpression "[ ../agents/skills-work ]";
      description = ''
        Extra directories holding machine-local skills. Each immediate subdirectory
        is linked individually, so a later directory can also shadow a shared skill
        of the same name.
      '';
    };
  };

  config = {
    # Installation is mise's job, and only where nix manages mise. Omarchy
    # installs and upgrades the agents itself, so this config limits itself to
    # placing the instructions and skills below. See ./mise.nix.
    programs.mise.globalConfig = lib.optionalAttrs (!config.os.shipsUserTools) {
      tools = {
        claude = "latest";
        codex = "latest";
        opencode = "latest";
      };
    };

    home.file = {
      ".claude/CLAUDE.md".source = cfg.instructions;
      ".codex/AGENTS.md".source = cfg.instructions;
    }
    // linkSkills ".claude/skills"
    // linkSkills ".codex/skills";

    xdg.configFile = {
      "opencode/AGENTS.md".source = cfg.instructions;
    }
    // linkSkills "opencode/skills";

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
  };
}
