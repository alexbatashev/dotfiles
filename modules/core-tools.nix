{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.os.shipsUserTools = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Set when the operating system already ships the terminal tools, desktop
      apps and tool runtimes this configuration would otherwise install. Nix
      then installs only what the OS lacks. Configuration is managed here in
      either case, so setting this drops packages, never settings.
    '';
  };

  config = lib.mkIf (!config.os.shipsUserTools) {
    home.packages = with pkgs; [
      bat
      btop
      eza
      fd
      fzf
      lazygit
      ripgrep
      unzip
    ];
  };
}
