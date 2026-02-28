{ ... }:
{
  # Source hyprland config from the home-manager store
  xdg.configFile = {
    "waybar/config.jsonc" = {
      source = ./config.jsonc;
    };

    "waybar/style.css" = {
      source = ./style.css;
    };

  };
}
