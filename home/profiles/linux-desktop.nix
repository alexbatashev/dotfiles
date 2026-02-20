{ pkgs, lib, ... }:
{
  # Full Hyprland desktop — imports the wayland module
  imports = [ ../modules/wayland.nix ];

  home.packages = with pkgs; [
    # Hyprland ecosystem extras
    hyprpicker     # colour picker
    hyprshot       # screenshot helper (alternative to grim+slurp)

    # Polkit agent
    polkit-kde-agent

    # Browser
    brave

    # App launcher (AUR onagre is not in nixpkgs; wofi is the fallback)
    # onagre

    # System monitor
    # (btop already in common.nix)

    # Archive
    p7zip
    unrar

    # Font: Hack (used in wofi style.css)
    hack-font
  ];
}
