# Headless deployment of T3 Code (https://github.com/pingdotgg/t3code).
#
# T3 Code is a web GUI for coding agents (Claude, Codex, Cursor, OpenCode).
# The published `t3` npm package ships a prebuilt server bundle whose blessed
# headless entrypoint is `t3 serve` — it starts the HTTP/WebSocket server
# without opening a browser and prints a pairing token / URL / QR code.
#
# Native dependencies: `t3` depends on `node-pty` (which ships NO Linux
# prebuilt) and pulls in `msgpackr-extract` (no aarch64-linux prebuilt in this
# tree), so on Linux these are compiled from source via node-gyp. That needs a
# C/C++ toolchain + python + make.
#
# Install vs run are split deliberately:
#   * The package is installed (and native addons compiled) ONCE by a
#     home-manager activation step, which runs in the normal user environment
#     during `home-manager switch`. (A systemd `ExecStartPre` was tried first
#     but failed in a way that reproduced nowhere else — running the install at
#     activation time is both simpler and avoids that.)
#   * The systemd user service only runs the already-built bundle, bound to a
#     chosen interface (e.g. a Tailnet IP).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.t3code;

  # node-pty has no Linux prebuilt, so a C/C++ toolchain is mandatory to build
  # it. git/coreutils/etc. are needed at runtime; the profile is appended so the
  # installed agent CLIs (claude, codex, opencode, ...) are discoverable.
  toolchain = [
    cfg.package
    pkgs.git
    pkgs.coreutils
    pkgs.bash
    pkgs.python3
    pkgs.gnumake
    pkgs.gcc
    pkgs.binutils
  ];
  toolchainPath = lib.makeBinPath (toolchain ++ cfg.extraPackages);
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
        install directory and re-run `home-manager switch`.
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
        Extra packages to place on the install/runtime PATH, e.g. additional
        coding-agent CLIs T3 Code should be able to launch.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Keep node/npm in the interactive environment too, for `t3 auth`,
    # `t3 project`, and ad-hoc `npx t3 ...` invocations.
    home.packages = [ cfg.package ];

    # Install (and compile native addons) once, during activation, in the normal
    # user environment. Idempotent: only (re)installs when the version changes or
    # the install is missing. Non-fatal: a failed install (e.g. no network) warns
    # but does not abort `home-manager switch`; the service just won't start
    # until a later switch completes the install.
    home.activation.t3codeInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export PATH=${toolchainPath}:/usr/local/bin:/usr/bin:/bin''${PATH:+:$PATH}
      t3dir=${lib.escapeShellArg cfg.installDir}
      t3want=t3@${lib.escapeShellArg cfg.version}
      if [ -f "$t3dir/node_modules/t3/dist/bin.mjs" ] \
        && [ "$(cat "$t3dir/.t3-version" 2>/dev/null || true)" = ${lib.escapeShellArg cfg.version} ]; then
        echo "t3code: $t3want already installed in $t3dir"
      else
        echo "t3code: installing $t3want into $t3dir (compiling native addons) ..."
        $DRY_RUN_CMD mkdir -p "$t3dir"
        [ -f "$t3dir/package.json" ] || echo '{"private":true}' > "$t3dir/package.json"
        if ( cd "$t3dir" && $DRY_RUN_CMD npm install --no-audit --no-fund "$t3want" ); then
          printf '%s' ${lib.escapeShellArg cfg.version} > "$t3dir/.t3-version"
          echo "t3code: installed $t3want"
        else
          echo "t3code: WARNING install of $t3want failed; the service will not start until a future 'home-manager switch' completes it with network access." >&2
        fi
      fi
    '';

    systemd.user.services.t3code = {
      Unit = {
        Description = "T3 Code headless server (coding-agent web GUI)";
        Documentation = [ "https://github.com/pingdotgg/t3code" ];
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
        # Don't loop forever if the bind address or install isn't ready yet.
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };

      Service = {
        Environment = [
          "PATH=${toolchainPath}:${config.home.profileDirectory}/bin:/usr/local/bin:/usr/bin:/bin"
          "T3CODE_HOST=${cfg.host}"
          "T3CODE_PORT=${toString cfg.port}"
          "T3CODE_NO_BROWSER=1"
        ];
        WorkingDirectory = cfg.workingDirectory;
        ExecStart = lib.concatStringsSep " " (
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
        Restart = "on-failure";
        RestartSec = 15;
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
