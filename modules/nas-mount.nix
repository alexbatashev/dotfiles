# Rootless SMB mount for the NAS `home` share, for standalone home-manager on
# non-NixOS Linux hosts (orion and friends).
#
# Why rclone (FUSE) instead of a kernel CIFS mount: these boxes are not NixOS
# and home-manager cannot create a privileged `mount.cifs` mount without root.
# `rclone mount` runs entirely in user space as a `systemd --user` service, so
# the whole thing is owned by home-manager with no sudo and no /etc changes.
#
# Secrets (repo is public): the SMB password is never committed. It is pulled
# from Bitwarden with `rbw` during `home-manager switch`, obscured with
# `rclone obscure`, and written to a 0600 rclone config file OUTSIDE the nix
# store (default ~/.config/nas/rclone.conf). The service reads that file at
# start, so the mount is reboot-safe and needs no unlocked agent at boot.
#
# Bootstrap once per machine (over SSH is fine):
#   rbw config set email <you@example.com>
#   rbw config set pinentry pinentry-curses   # headless-friendly prompt
#   rbw login                                  # unlock, then `home-manager switch`
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.nasMount;

  # rclone finds `fusermount3` on PATH to (un)mount; coreutils for mkdir.
  runtimePath = lib.makeBinPath [
    cfg.package
    cfg.fusePackage
    pkgs.coreutils
  ];

  # Password fetch/obscure at activation time needs rbw + rclone + coreutils.
  credentialPath = lib.makeBinPath [
    cfg.bitwarden.package
    cfg.package
    pkgs.coreutils
  ];

  mountArgs = lib.concatStringsSep " " (
    [
      "mount"
      "--config"
      (lib.escapeShellArg cfg.configFile)
      "${cfg.remoteName}:${cfg.share}"
      (lib.escapeShellArg cfg.mountPoint)
    ]
    ++ cfg.extraMountFlags
  );
in
{
  options.services.nasMount = {
    enable = lib.mkEnableOption "the rootless rclone SMB mount of the NAS home share";

    host = lib.mkOption {
      type = lib.types.str;
      default = "nas.siren-pollux.ts.net";
      description = "SMB server host (reachable over the tailnet).";
    };

    share = lib.mkOption {
      type = lib.types.str;
      default = "home";
      description = "SMB share to mount (the first path component under the host).";
    };

    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/mnt/nas";
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/mnt/nas"'';
      description = ''
        Directory the share is mounted at. Defaults to a path under $HOME so it
        is the same on every machine (the `home` share is per-user anyway).
      '';
    };

    remoteName = lib.mkOption {
      type = lib.types.str;
      default = "nas";
      description = "Name of the rclone remote written into the generated config.";
    };

    configFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.configHome}/nas/rclone.conf";
      defaultText = lib.literalExpression ''"''${config.xdg.configHome}/nas/rclone.conf"'';
      description = ''
        Path to the rclone config file holding the (obscured) SMB credentials.
        Written at activation with mode 0600, outside the world-readable nix
        store. Not managed if `bitwarden.enable = false` (provide it yourself).
      '';
    };

    extraMountFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--vfs-cache-mode"
        "writes"
        "--dir-cache-time"
        "1m"
      ];
      description = "Extra flags appended to `rclone mount`.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.rclone;
      defaultText = lib.literalExpression "pkgs.rclone";
      description = "rclone package providing `rclone mount`/`rclone obscure`.";
    };

    fusePackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.fuse3;
      defaultText = lib.literalExpression "pkgs.fuse3";
      description = "FUSE package providing `fusermount3` for (un)mounting.";
    };

    bitwarden = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Fetch the SMB password from Bitwarden with `rbw` during
          `home-manager switch` and write the obscured rclone config. Disable to
          manage `configFile` entirely by hand.
        '';
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.rbw;
        defaultText = lib.literalExpression "pkgs.rbw";
        description = "Bitwarden CLI (rbw) package used to fetch the password.";
      };

      pinentryPackage = lib.mkOption {
        type = lib.types.package;
        default = pkgs.pinentry-curses;
        defaultText = lib.literalExpression "pkgs.pinentry-curses";
        description = "pinentry program installed for `rbw` to prompt for the master password.";
      };

      item = lib.mkOption {
        type = lib.types.str;
        default = "nas-smb";
        description = "Name of the Bitwarden item whose password is the SMB password.";
      };
    };
  };

  config = lib.mkMerge [
    # Guard rail: the option namespace exists on every host (imported globally),
    # but the implementation is Linux-only.
    {
      warnings = lib.optional (cfg.enable && !pkgs.stdenv.isLinux) (
        "services.nasMount is enabled but only supported on Linux "
        + "(systemd user service); it is a no-op on this platform."
      );
    }

    (lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
      home.packages =
        [
          cfg.package
          cfg.fusePackage
        ]
        ++ lib.optionals cfg.bitwarden.enable [
          cfg.bitwarden.package
          cfg.bitwarden.pinentryPackage
        ];

      # Fetch the password from Bitwarden and (re)write the obscured rclone
      # config. Non-fatal: if the vault is locked / offline we warn and keep any
      # existing credentials rather than aborting the switch or truncating a
      # working config.
      home.activation.nasMountCredentials = lib.mkIf cfg.bitwarden.enable (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          export PATH=${credentialPath}''${PATH:+:$PATH}
          cfgfile=${lib.escapeShellArg cfg.configFile}
          cfgdir=$(dirname "$cfgfile")
          mkdir -p "$cfgdir"
          chmod 700 "$cfgdir"

          if ! smbpass=$(rbw get ${lib.escapeShellArg cfg.bitwarden.item} 2>/dev/null) || [ -z "$smbpass" ]; then
            echo "nas-mount: WARNING could not read the SMB password from Bitwarden item '${cfg.bitwarden.item}' via rbw." >&2
            echo "nas-mount:   Run 'rbw unlock' (or 'rbw login') then re-run 'home-manager switch'. Keeping any existing credentials file." >&2
          else
            obscured=$(rclone obscure "$smbpass")
            (
              umask 077
              {
                printf '[%s]\n' ${lib.escapeShellArg cfg.remoteName}
                printf 'type = smb\n'
                printf 'host = %s\n' ${lib.escapeShellArg cfg.host}
                printf 'user = alex\n'
                printf 'pass = %s\n' "$obscured"
              } > "$cfgfile"
            )
            chmod 600 "$cfgfile"
            echo "nas-mount: wrote rclone credentials to $cfgfile"
          fi
        ''
      );

      systemd.user.services.nas-mount = {
        Unit = {
          Description = "Mount NAS SMB share '${cfg.share}' at ${cfg.mountPoint} (rclone/FUSE)";
          Documentation = [ "https://rclone.org/smb/" ];
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };

        Service = {
          # rclone signals readiness to systemd once the mount is live.
          Type = "notify";
          Environment = [ "PATH=${runtimePath}" ];
          ExecStartPre = [
            "${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg cfg.mountPoint}"
            # Clear a stale mountpoint left by an unclean shutdown (ignore errors).
            "-${cfg.fusePackage}/bin/fusermount3 -uz ${lib.escapeShellArg cfg.mountPoint}"
          ];
          ExecStart = "${cfg.package}/bin/rclone ${mountArgs}";
          ExecStop = "${cfg.fusePackage}/bin/fusermount3 -u ${lib.escapeShellArg cfg.mountPoint}";
          Restart = "on-failure";
          RestartSec = 10;
        };

        Install.WantedBy = [ "default.target" ];
      };
    })
  ];
}
