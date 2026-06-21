# Headless deployment of T3 Code (https://github.com/pingdotgg/t3code).
#
# T3 Code is a web GUI for coding agents (Claude, Codex, Cursor, OpenCode).
# The published `t3` npm package ships a prebuilt server bundle whose blessed
# headless entrypoint is `t3 serve` — it starts the HTTP/WebSocket server
# without opening a browser and prints a pairing token / URL / QR code.
#
# This module runs `npx t3@<version> serve` as a systemd *user* service and
# binds it to a chosen interface (e.g. a Tailnet IP), so it is reachable from
# the desktop/mobile/web clients over a trusted network.
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
        Node.js package providing the `node`/`npx` used to fetch and run T3 Code.
        The `t3` package requires Node `^22.16 || ^23.11 || >=24.10`.
      '';
    };

    version = lib.mkOption {
      type = lib.types.str;
      default = "latest";
      example = "0.0.27";
      description = ''
        npm dist-tag or exact version of the `t3` package to run via `npx`.
        T3 Code is very early and changes fast, so `latest` is the default; pin
        to a concrete version for a reproducible deployment.
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
    # Keep node/npx in the interactive environment too, for `t3 auth`,
    # `t3 project`, and ad-hoc `npx t3 ...` invocations.
    home.packages = [ cfg.package ];

    systemd.user.services.t3code = {
      Unit = {
        Description = "T3 Code headless server (coding-agent web GUI)";
        Documentation = [ "https://github.com/pingdotgg/t3code" ];
        # network-online.target is a no-op for some user managers; the Restart
        # loop below is the real safety net for a not-yet-ready bind address.
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service =
        let
          # Toolchain T3 Code needs at runtime: node for the bundle, git for repo
          # operations, and a build fallback in case node-pty has no prebuilt
          # binary for this platform. The home-manager profile is appended so the
          # installed agent CLIs (claude, codex, opencode, ...) are discoverable.
          servePath = lib.makeBinPath (
            [
              cfg.package
              pkgs.git
              pkgs.coreutils
              pkgs.bash
              pkgs.python3
              pkgs.gnumake
              pkgs.gcc
            ]
            ++ cfg.extraPackages
          );
          command = [
            "${cfg.package}/bin/npx"
            "--yes"
            "t3@${cfg.version}"
            "serve"
            "--host"
            cfg.host
            "--port"
            (toString cfg.port)
          ]
          ++ cfg.extraArgs;
        in
        {
          Environment = [
            "PATH=${servePath}:${config.home.profileDirectory}/bin"
            "T3CODE_HOST=${cfg.host}"
            "T3CODE_PORT=${toString cfg.port}"
            "T3CODE_NO_BROWSER=1"
          ];
          WorkingDirectory = cfg.workingDirectory;
          ExecStart = lib.concatStringsSep " " command;
          Restart = "always";
          RestartSec = 5;
        };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
