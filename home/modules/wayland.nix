{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    # Status bar & launcher
    waybar
    wofi

    # Screenshot pipeline
    grim
    slurp
    swappy
    wl-clipboard

    # Idle / lock
    swayidle
    swaylock

    # Notifications
    mako

    # Wallpaper
    swaybg

    # Volume overlay bar
    wob

    # Brightness
    brightnessctl

    # Media control
    playerctl

    # Audio GUI
    pavucontrol

    # Power / session menu
    wlogout

    # Input method
    fcitx5

    # Network applet
    networkmanagerapplet
  ];

  # ── Hyprland ─────────────────────────────────────────────────────────────
  # Symlinked out-of-store so hyprland can write socket files and the user
  # can edit sub-configs without a home-manager rebuild.
  xdg.configFile."hypr" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles/hyprland/.config/hypr";
  };

  # ── Waybar ───────────────────────────────────────────────────────────────
  xdg.configFile."waybar" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles/waybar/.config/waybar";
  };

  # ── Wofi ─────────────────────────────────────────────────────────────────
  xdg.configFile."wofi" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles/wofi/.config/wofi";
  };
}
