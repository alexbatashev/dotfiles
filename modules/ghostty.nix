{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;

    systemd.enable = false;

    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = true;

    settings = {
      theme = "JetBrains Darcula";
      font-size = 20;
      shell-integration-features = "true";
      keybind = [
        "global:cmd+backquote=toggle_quick_terminal"
      ];
      async-backend = "epoll";
    };
  };
}
