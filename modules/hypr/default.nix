{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    fcitx5
    mako
    hypridle
    swaybg
    swayosd
  ];

  home.activation.reloadHyprWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    "$HOME/dotfiles/bin/hypr-wallpaper-random"
  '';

  # Source hyprland config from the home-manager store
  xdg.configFile = {
    "hypr/hyprland.conf" = {
      source = ./hyprland.conf;
    };

    "hypr/hypridle.conf" = {
      source = ./hypridle.conf;
    };

    "hypr/hyprlock.conf" = {
      source = ./hyprlock.conf;
    };

    "hypr/xdph.conf".text = ''
      screencopy {
        allow_token_by_default = true
        max_fps = 99
      }
    '';
  };
}
