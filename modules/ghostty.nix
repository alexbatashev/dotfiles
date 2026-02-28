{pkgs, config, ...}: {
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else null;

    systemd.enable = false;

    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = true;

    settings = {
      theme = "Jellybeans";
      font-size = 20;
    };
  };
}
