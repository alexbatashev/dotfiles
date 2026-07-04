# Per-user SMB mount of the NAS share, for standalone home-manager on non-NixOS
# Linux hosts (nuc, orion, ...). This is the SAME mechanism as GNOME's
# "Connect to Server" / single-click network mount: GVFS (`gio mount`).
#
# Why GVFS and not rclone/CIFS:
#   * kernel CIFS (mount.cifs) needs root and lives in /etc — home-manager
#     cannot own it on a non-NixOS box, and it is system-global, not per-user.
#   * a private FUSE mount (rclone/sshfs) is rootless but must create its own
#     FUSE mount via the setuid /usr/bin/fusermount3 — which the current Ubuntu
#     kernel refuses for an unprivileged session (mount() returns EPERM even
#     with full caps). That path simply does not work here.
#   * GVFS sidesteps both: the login session already runs one working gvfs FUSE
#     bridge at /run/user/$UID/gvfs (gvfsd-fuse). `gio mount` just adds the SMB
#     share into that existing bridge — no new mount, no root, no fstab. The
#     files are then reachable from the terminal under that gvfs path, and we
#     symlink a stable location (default ~/mnt/nas) at it.
#
# Secret (repo is public): the SMB password is never committed. It is pulled
# from Bitwarden with `rbw` during `home-manager switch` and written to a 0600
# file OUTSIDE the nix store (default ~/.config/nas/smb-pass). The login service
# feeds it to `gio mount` on stdin, so no keyring seeding and no prompt.
#
# Requires: a running user session with GVFS (gvfsd + gvfsd-fuse) — i.e. a
# desktop login. Enable only on such hosts. Bootstrap once per machine:
#   rbw config set email <you@example.com>
#   rbw config set pinentry pinentry-curses
#   rbw login                                  # unlock, then `home-manager switch`
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.nasMount;

  # Encoded name gvfs gives an SMB mount under /run/user/$UID/gvfs.
  gvfsName = "smb-share:server=${cfg.host},share=${cfg.share}";

  mountScript = pkgs.writeShellScript "nas-gvfs-mount" ''
    set -eu
    export PATH=${
      lib.makeBinPath [
        cfg.giobPackage
        pkgs.coreutils
      ]
    }''${PATH:+:$PATH}

    # Force gio to take credentials from stdin rather than popping a GUI
    # password dialog (which would hang this non-interactive service).
    unset DISPLAY WAYLAND_DISPLAY || true

    gvfs_path="$XDG_RUNTIME_DIR/gvfs/${gvfsName}"

    # Add the share to the session's gvfs bridge if not already there. `gio
    # mount` reads user / domain / password from stdin (no tty, no GUI agent).
    if [ ! -d "$gvfs_path" ]; then
      if [ ! -r ${lib.escapeShellArg cfg.passFile} ]; then
        echo "nas-mount: no password file at ${cfg.passFile}; run 'rbw unlock' and 'home-manager switch'." >&2
        exit 1
      fi
      printf '%s\n%s\n%s\n' \
        ${lib.escapeShellArg cfg.user} \
        ${lib.escapeShellArg cfg.domain} \
        "$(cat ${lib.escapeShellArg cfg.passFile})" \
        | gio mount "smb://${cfg.host}/${cfg.share}"
    fi

    # Stable, terminal-friendly path -> the gvfs mount.
    mkdir -p "$(dirname ${lib.escapeShellArg cfg.mountPoint})"
    ln -sfn "$gvfs_path" ${lib.escapeShellArg cfg.mountPoint}
  '';

  unmountScript = pkgs.writeShellScript "nas-gvfs-unmount" ''
    set -u
    export PATH=${lib.makeBinPath [ cfg.giobPackage pkgs.coreutils ]}''${PATH:+:$PATH}
    gio mount -u "smb://${cfg.host}/${cfg.share}" 2>/dev/null || true
    rm -f ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true
  '';
in
{
  options.services.nasMount = {
    enable = lib.mkEnableOption "the per-user GVFS SMB mount of the NAS share";

    host = lib.mkOption {
      type = lib.types.str;
      default = "nas.siren-pollux.ts.net";
      description = "SMB server host (reachable over the tailnet).";
    };

    share = lib.mkOption {
      type = lib.types.str;
      default = "home";
      description = "SMB share to mount.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "alex";
      description = "SMB username.";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "SMB workgroup/domain (empty accepts the server default).";
    };

    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/mnt/nas";
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/mnt/nas"'';
      description = ''
        Stable symlink pointing at the gvfs mount, for terminal/app access.
        Same path on every machine (the share is per-user anyway).
      '';
    };

    passFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.configHome}/nas/smb-pass";
      defaultText = lib.literalExpression ''"''${config.xdg.configHome}/nas/smb-pass"'';
      description = ''
        0600 file holding the SMB password, written at activation from Bitwarden
        (outside the world-readable nix store). Not managed if
        `bitwarden.enable = false` (provide it yourself).
      '';
    };

    giobPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.glib.bin;
      defaultText = lib.literalExpression "pkgs.glib.bin";
      description = "Package providing the `gio` binary.";
    };

    bitwarden = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Fetch the SMB password from Bitwarden with `rbw` during `home-manager switch`.";
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
        default = "DiskStation";
        description = "Name of the Bitwarden item whose password is the SMB password.";
      };
    };
  };

  config = lib.mkMerge [
    {
      warnings = lib.optional (cfg.enable && !pkgs.stdenv.isLinux) (
        "services.nasMount is enabled but only supported on Linux (GVFS user session); "
        + "it is a no-op on this platform."
      );
    }

    (lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
      home.packages =
        [ cfg.giobPackage ]
        ++ lib.optionals cfg.bitwarden.enable [
          cfg.bitwarden.package
          cfg.bitwarden.pinentryPackage
        ];

      # Fetch the password from Bitwarden and (re)write the 0600 pass file.
      # Non-fatal: if the vault is locked/offline we warn and keep any existing
      # file rather than aborting the switch or truncating a working password.
      home.activation.nasMountCredentials = lib.mkIf cfg.bitwarden.enable (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          export PATH=${
            lib.makeBinPath [
              cfg.bitwarden.package
              pkgs.coreutils
            ]
          }''${PATH:+:$PATH}
          passfile=${lib.escapeShellArg cfg.passFile}
          mkdir -p "$(dirname "$passfile")"
          chmod 700 "$(dirname "$passfile")"
          if ! smbpass=$(rbw get ${lib.escapeShellArg cfg.bitwarden.item} 2>/dev/null) || [ -z "$smbpass" ]; then
            echo "nas-mount: WARNING could not read SMB password from Bitwarden item '${cfg.bitwarden.item}' via rbw." >&2
            echo "nas-mount:   Run 'rbw unlock' then re-run 'home-manager switch'. Keeping any existing password file." >&2
          else
            ( umask 077; printf '%s' "$smbpass" > "$passfile" )
            chmod 600 "$passfile"
            echo "nas-mount: wrote SMB password to $passfile"
          fi
        ''
      );

      systemd.user.services.nas-mount = {
        Unit = {
          Description = "Mount NAS SMB share '${cfg.share}' into GVFS and symlink ${cfg.mountPoint}";
          Documentation = [ "man:gio(1)" ];
          # GVFS (gvfsd-fuse) is part of the graphical session.
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${mountScript}";
          ExecStop = "${unmountScript}";
        };

        Install.WantedBy = [ "graphical-session.target" ];
      };
    })
  ];
}
