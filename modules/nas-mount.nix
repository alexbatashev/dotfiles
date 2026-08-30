# Per-user SMB mount of the NAS share, for standalone home-manager on non-NixOS
# Linux hosts. Same mechanism as GNOME's "Connect to Server": GVFS (`gio`).
# Works on BOTH desktop and headless/SSH boxes, fully rootless.
#
# Why GVFS and not rclone/CIFS:
#   * kernel CIFS needs root and lives in /etc — home-manager can't own it on a
#     non-NixOS box, and it is system-global, not per-user.
#   * a private FUSE mount (rclone/sshfs) creates its own mount via the setuid
#     /usr/bin/fusermount3, which some current Ubuntu kernels (e.g. nuc's
#     7.0.0-27) refuse for an unprivileged session (mount() EPERM). Dead end.
#   * GVFS mounts the share into the session's gvfs FUSE bridge at
#     /run/user/$UID/gvfs — no new privileged mount, no root, no fstab. On a
#     desktop the bridge already runs; on a headless/SSH host we start our own
#     `gvfsd-fuse` (rootless). The files are then reachable from the terminal,
#     and we symlink a stable path (default ~/mnt/nas) at them.
#
# Needs the distro's gvfs pieces (gvfsd, gvfsd-fuse, gvfsd-smb) — present on
# Ubuntu/Debian desktops and servers with the `gvfs`/`gvfs-backends` packages.
# `gio` itself may come from nix; GIO_EXTRA_MODULES points it at the system
# gvfs backend so it understands smb:// outside a desktop session.
#
# Secret (repo is public): the SMB password is never committed. Pulled from
# Bitwarden with `rbw` during `home-manager switch` into a 0600 file outside the
# nix store (default ~/.config/nas/smb-pass), fed to `gio` on stdin — no keyring
# seeding, no prompt. Bootstrap once per machine:
#   rbw config set email <you@example.com>
#   rbw config set pinentry pinentry-curses
#   rbw login                                  # unlock, then `home-manager switch`
#
# Persistence when logged out (headless boxes reached only by SSH): enable
# `systemd --user` lingering so the mount survives between sessions:
#   loginctl enable-linger "$USER"
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.nasMount;

  gvfsName = "smb-share:server=${cfg.host},share=${cfg.share}";

  # System tools first (gio/gvfsd-fuse/systemctl/systemd-run/fusermount3 must be
  # the distro's, to talk to the running user manager and system gvfs), with
  # nix coreutils/gio as fallback.
  binPath = "/usr/bin:/bin:${
    lib.makeBinPath [
      cfg.giobPackage
      pkgs.coreutils
    ]
  }";

  mountScript = pkgs.writeShellScript "nas-gvfs-mount" ''
    set -u
    export PATH=${binPath}''${PATH:+:$PATH}
    # Force gio to read credentials from stdin, never a GUI dialog.
    unset DISPLAY WAYLAND_DISPLAY || true

    bridge="$XDG_RUNTIME_DIR/gvfs"
    sp="$bridge/${gvfsName}"

    # Let nix `gio` find the system gvfs SMB backend outside a desktop session.
    mods=$(dirname "$(ls /usr/lib/*/gio/modules/libgvfsdbus.so /usr/lib/gio/modules/libgvfsdbus.so 2>/dev/null | head -1)" 2>/dev/null || true)
    [ -n "$mods" ] && export GIO_EXTRA_MODULES="''${GIO_EXTRA_MODULES:+$GIO_EXTRA_MODULES:}$mods"

    # 1. Ensure a HEALTHY gvfs fuse bridge. `ls` succeeds on a live bridge
    #    (desktop session already runs one -> reuse it). If it is missing or
    #    stale/disconnected (ENOTCONN), tear it down and start our own.
    if ! ls "$bridge" >/dev/null 2>&1; then
      fusermount3 -u "$bridge" 2>/dev/null || fusermount -u "$bridge" 2>/dev/null || umount "$bridge" 2>/dev/null || true
      systemctl --user reset-failed nas-gvfs-bridge 2>/dev/null || true
      gf=$(ls /usr/lib/gvfs/gvfsd-fuse /usr/libexec/gvfs/gvfsd-fuse 2>/dev/null | head -1 || true)
      if [ -n "$gf" ]; then
        mkdir -p "$bridge"
        systemd-run --user --quiet --collect --unit=nas-gvfs-bridge \
          --property=Restart=on-failure "$gf" -f "$bridge" || true
        for _ in $(seq 1 20); do ls "$bridge" >/dev/null 2>&1 && break; sleep 0.5; done
      fi
    fi
    if ! ls "$bridge" >/dev/null 2>&1; then
      echo "nas-mount: no working gvfs bridge at $bridge (is gvfs installed / a session running?)." >&2
      exit 1
    fi

    # 2. Mount the share into gvfs if not already present.
    if [ ! -d "$sp" ]; then
      if [ ! -r ${lib.escapeShellArg cfg.passFile} ]; then
        echo "nas-mount: no password file at ${cfg.passFile}; run 'rbw unlock' then 'home-manager switch'." >&2
        exit 1
      fi
      printf '%s\n%s\n%s\n' \
        ${lib.escapeShellArg cfg.user} \
        ${lib.escapeShellArg cfg.domain} \
        "$(cat ${lib.escapeShellArg cfg.passFile})" \
        | gio mount "smb://${cfg.host}/${cfg.share}" || true
      for _ in $(seq 1 20); do [ -d "$sp" ] && break; sleep 0.5; done
    fi
    if [ ! -d "$sp" ]; then
      echo "nas-mount: share did not appear at $sp after mounting." >&2
      exit 1
    fi

    # 3. Stable, terminal-friendly path -> the gvfs mount. Replace any leftover
    #    symlink or stale directory (e.g. from an older module) at that path, so
    #    `ln` can't drop the link *inside* an existing dir.
    mkdir -p "$(dirname ${lib.escapeShellArg cfg.mountPoint})"
    mountpoint -q ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null \
      || rm -rf ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true
    ln -sfn "$sp" ${lib.escapeShellArg cfg.mountPoint}
    echo "nas-mount: mounted at ${cfg.mountPoint}"
  '';

  unmountScript = pkgs.writeShellScript "nas-gvfs-unmount" ''
    set -u
    export PATH=${binPath}''${PATH:+:$PATH}
    unset DISPLAY WAYLAND_DISPLAY || true
    gio mount -u "smb://${cfg.host}/${cfg.share}" 2>/dev/null || true
    rm -f ${lib.escapeShellArg cfg.mountPoint} 2>/dev/null || true
    systemctl --user stop nas-gvfs-bridge 2>/dev/null || true
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
      description = "Stable symlink at the gvfs mount, for terminal/app access.";
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
      description = "Package providing a fallback `gio` binary.";
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
      warnings = lib.optional (cfg.enable && !pkgs.stdenv.hostPlatform.isLinux) (
        "services.nasMount is enabled but only supported on Linux (GVFS); it is a no-op here."
      );
    }

    (lib.mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isLinux) {
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
          # Works headless or desktop; no graphical-session dependency.
          After = [ "default.target" ];
        };

        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${mountScript}";
          ExecStop = "${unmountScript}";
        };

        Install.WantedBy = [ "default.target" ];
      };
    })
  ];
}
