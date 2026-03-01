{ pkgs, ... }:
{
  targets.genericLinux.enable = true;
  targets.genericLinux.gpu.nvidia = {
    enable = true;
    version = "590.48.01";
    sha256 = "sha256-ueL4BpN4FDHMh/TNKRCeEz3Oy1ClDWto1LO/LWlr1ok=";
  };
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.nvidia.acceptLicense = true;

  home.file.".local/share/wallpapers/rotation/unsplash-alex-mesmer.jpg".source = pkgs.fetchurl {
    url = "https://images.unsplash.com/photo-1768310481123-9c8e4e6fc61a?ixlib=rb-4.1.0&q=85&fm=jpg&crop=entropy&cs=srgb&dl=alex-mesmer-6h6O17NjZ_I-unsplash.jpg";
    sha256 = "sha256-7SOfq1yLZ/R/n4WZgMHDArmJS9IoZeqYTA3OrMaAru8=";
  };

  home.file.".local/share/wallpapers/rotation/unsplash-hannah-montez.jpg".source = pkgs.fetchurl {
    url = "https://images.unsplash.com/photo-1542690969-5a2050285637?ixlib=rb-4.1.0&q=85&fm=jpg&crop=entropy&cs=srgb&dl=hannah-montez-2VslRz5G8fo-unsplash.jpg";
    sha256 = "sha256-Jfi7kh9Sgu0NxuEcJ3ZfAFSwzkQVxl5aB4sOiq8fkmU=";
  };

  home.file.".local/share/wallpapers/rotation/unsplash-vincentu-solomon.jpg".source = pkgs.fetchurl {
    url = "https://images.unsplash.com/photo-1543253539-58c7d1c00c8a?ixlib=rb-4.1.0&q=85&fm=jpg&crop=entropy&cs=srgb&dl=vincentiu-solomon-Z4wF0h47fy8-unsplash.jpg";
    sha256 = "sha256-Yt2ETgMsT7Lugh3j7g5w0/sudR6qRulPNNrx6BR2gFU=";
  };

  imports = [
    ../modules/hypr/default.nix
    ../modules/waybar
  ];
}
