# nuc: x86_64-linux GNOME box on non-NixOS Ubuntu, managed by standalone
# home-manager. Runs T3 Code as a personal coding-agent server over the tailnet,
# plus a local GUI session.
{ config, ... }:
{
  imports = [
    ../modules/t3code.nix
  ];

  # The ghostty package's desktop entry sets DBusActivatable=true, so GNOME tries
  # to launch it via D-Bus/systemd activation (app-com.mitchellh.ghostty.service)
  # which doesn't exist on non-NixOS — clicking the menu icon then does nothing.
  # Shadow it with a copy in ~/.local/share/applications (higher XDG priority than
  # the nix profile) that runs Exec directly. Written via home.file because
  # xdg.enable is false on this host, so xdg.desktopEntries would be a no-op.
  home.file.".local/share/applications/com.mitchellh.ghostty.desktop".text =
    let
      ghostty = "${config.programs.ghostty.package}/bin/ghostty --gtk-single-instance=true";
    in
    ''
      [Desktop Entry]
      Version=1.0
      Name=Ghostty
      Type=Application
      Comment=A terminal emulator
      Exec=${ghostty}
      Icon=com.mitchellh.ghostty
      Categories=System;TerminalEmulator;
      Keywords=terminal;tty;pty;
      StartupNotify=true
      StartupWMClass=com.mitchellh.ghostty
      Terminal=false
      DBusActivatable=false
      Actions=new-window;

      [Desktop Action new-window]
      Name=New Window
      Exec=${ghostty}
    '';

  # Mount the NAS `home` share at ~/mnt/nas. Rootless rclone/FUSE user service;
  # the SMB password is pulled from Bitwarden (rbw) at switch-time. See
  # ../modules/nas-mount.nix for the one-time `rbw` bootstrap.
  services.nasMount.enable = true;

  # Standalone home-manager on a non-NixOS host: integrate with the system's
  # session/systemd so the user service picks up the right environment.
  targets.genericLinux.enable = true;

  #services.t3code = {
  #  enable = true;
  #  # nuc's Tailscale IP — the server is only reachable over the tailnet.
  #  host = "100.86.155.54";
  #  # version = "0.0.27"; # pin here for a fully reproducible deployment
  # };
}
