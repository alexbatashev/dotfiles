# Headless deployment of T3 Code (https://github.com/pingdotgg/t3code).
#
# T3 Code is a web GUI for coding agents (Claude, Codex, Cursor, OpenCode).
# The published `t3` npm package ships a prebuilt server bundle whose blessed
# headless entrypoint is `t3 serve` — it starts the HTTP/WebSocket server
# without opening a browser and prints a pairing token / URL / QR code.
#
# Native dependencies: the `t3` package depends on `node-pty` (which ships NO
# Linux prebuilt binary) and pulls in `msgpackr-extract` (no aarch64-linux
# prebuilt in this tree), so on Linux these are compiled from source via
# node-gyp at install time. That requires a C/C++ toolchain + python + make.
#
# This module installs the package ONCE into a fixed directory (compiling the
# native addons a single time), then runs the resulting bundle as a systemd
# *user* service bound to a chosen interface (e.g. a Tailnet IP).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.t3code;
in
{
  options.services.t3code = {
    enable = lib.mkEnableOption "the T3 Code headless coding-agent server";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nodejs;
      defaultText = lib.literalExpression "pkgs.nodejs";
      description = ''
        Node.js package providing the `node`/`npm` used to install and run T3
        Code. The `t3` package requires Node `^22.16 || ^23.11 || >=24.10`.
      '';
    };

    version = lib.mkOption {
      type = lib.types.str;
      default = "latest";
      example = "0.0.27";
      description = ''
        npm dist-tag or exact version of the `t3` package to install. T3 Code
        is very early and changes fast, so `latest` is the default; pin to a
        concrete version for a reproducible deployment. The package is only
        (re)installed when this value changes — to refresh `latest`, delete the
        install directory and restart the service.
      '';
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "100.86.155.54";
      description = ''
        Host/interface to bind the server to. Prefer a trusted private address
        such as a Tailnet IP instead of exposing the server broadly. The
        address must already be assigned to a local interface when the service
        starts (the service restarts on failure to ride out interface bring-up).
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3773;
      description = "TCP port for the HTTP/WebSocket server.";
    };

    installDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.local/share/t3code";
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/.local/share/t3code"'';
      description = ''
        Directory the `t3` npm package is installed into. Native addons are
        compiled here once. Delete it to force a clean reinstall.
      '';
    };

    workingDirectory = lib.mkOption {
      type = lib.types.str;
      default = config.home.homeDirectory;
      defaultText = lib.literalExpression "config.home.homeDirectory";
      description = ''
        Default working directory for provider/agent sessions. Add projects on
        the server with `t3 project ...` once it is running.
      '';
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "--tailscale-serve"
      ];
      description = "Extra arguments appended to `t3 serve`.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        Extra packages to place on the service PATH, e.g. additional
        coding-agent CLIs T3 Code should be able to launch.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Keep node/npm in the interactive environment too, for `t3 auth`,
    # `t3 project`, and ad-hoc `npx t3 ...` invocations.
    home.packages = [ cfg.package ];

    systemd.user.services.t3code =
      let
        # Runtime + native-build toolchain. node-pty ships no Linux prebuilt, so
        # a C/C++ toolchain is mandatory here, not just a fallback. The
        # home-manager profile is appended so installed agent CLIs (claude,
        # codex, opencode, ...) are discoverable by the server.
        servePath = lib.makeBinPath (
          [
            cfg.package
            pkgs.git
            pkgs.coreutils
            pkgs.bash
            pkgs.python3
            pkgs.gnumake
            pkgs.gcc
            pkgs.binutils
          ]
          ++ cfg.extraPackages
        );

        environment = [
          "PATH=${servePath}:${config.home.profileDirectory}/bin"
          # Compile one translation unit at a time: native addons (node-pty,
          # msgpackr-extract) pull in heavy V8 headers and parallel g++ can
          # exhaust RAM on small ARM boxes.
          "JOBS=1"
          "npm_config_jobs=1"
          "T3CODE_HOST=${cfg.host}"
          "T3CODE_PORT=${toString cfg.port}"
          "T3CODE_NO_BROWSER=1"
        ];

        # Install (and compile native addons) once. Idempotent: re-runs only
        # when the requested version changes or the install is missing. Its
        # output streams to the journal, so build failures are visible via
        # `journalctl --user -u t3code`.
        installScript = pkgs.writeShellScript "t3code-install" ''
          set -euo pipefail
          dir=${lib.escapeShellArg cfg.installDir}
          want=t3@${lib.escapeShellArg cfg.version}
          mkdir -p "$dir"
          cd "$dir"
          [ -f package.json ] || echo '{"private":true}' > package.json
          if [ -f "$dir/node_modules/t3/dist/bin.mjs" ] \
            && [ "$(cat "$dir/.t3-version" 2>/dev/null || true)" = ${lib.escapeShellArg cfg.version} ]; then
            echo "t3@${cfg.version} already installed in $dir"
          else
            echo "Installing $want into $dir (compiling native addons) ..."
            npm install --no-audit --no-fund --loglevel=info "$want"
            printf '%s' ${lib.escapeShellArg cfg.version} > "$dir/.t3-version"
          fi
        '';

        serveCommand = lib.concatStringsSep " " (
          [
            "${cfg.package}/bin/node"
            "${cfg.installDir}/node_modules/t3/dist/bin.mjs"
            "serve"
            "--host"
            cfg.host
            "--port"
            (toString cfg.port)
          ]
          ++ cfg.extraArgs
        );
      in
      {
        Unit = {
          Description = "T3 Code headless server (coding-agent web GUI)";
          Documentation = [ "https://github.com/pingdotgg/t3code" ];
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
          # Don't melt the box if startup keeps failing: give up after a few
          # rapid failures instead of looping forever.
          StartLimitIntervalSec = 300;
          StartLimitBurst = 5;
        };

        Service = {
          Environment = environment;
          WorkingDirectory = cfg.workingDirectory;
          ExecStartPre = "${installScript}";
          ExecStart = serveCommand;
          Restart = "on-failure";
          RestartSec = 15;
          # First start may need to download deps and compile native addons.
          TimeoutStartSec = "1200";
        };

        Install.WantedBy = [ "default.target" ];
      };
  };
}
