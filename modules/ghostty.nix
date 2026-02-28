{pkgs, config, ...}: {
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else config.lib.nixGL.wrap pkgs.ghostty;

    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = true;

    settings = {
      theme = "Jellybeans";
    };
  };
}
