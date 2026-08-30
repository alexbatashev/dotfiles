{ ... }:
{
  # Mount the NAS `home` share at ~/mnt/nas. Rootless rclone/FUSE user service;
  # the SMB password is pulled from Bitwarden (rbw) at switch-time. See
  # ../modules/nas-mount.nix for the one-time `rbw` bootstrap.
  services.nasMount.enable = true;
}
