{ ... }:
{
  # Mount the NAS `home` share at ~/mnt/nas. Rootless rclone/FUSE user service;
  # the SMB password is pulled from Bitwarden (rbw) at switch-time. See
  # ../modules/nas-mount.nix for the one-time `rbw` bootstrap.
  services.nasMount.enable = true;

  # Standalone home-manager on a non-NixOS host: integrate with the system's
  # session/systemd so the user service picks up the right environment.
  targets.genericLinux.enable = true;
}
