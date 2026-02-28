{
  config,
  pkgs,
  username,
  lib,
  ...
}:
{
  home.username = username;
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";

  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    wget
    curl
    unzip
    ripgrep
    fd
    bat
    eza
    fzf
    zoxide
    btop

    git-lfs
    gh

    cmake
    ninja

    nodejs
    python3

    graphviz

    nerd-fonts.jetbrains-mono
    fira
  ];

  programs.home-manager.enable = true;

  home.activation.migrateLegacyDarwinAppsLink = lib.mkIf pkgs.stdenv.isDarwin (
    lib.hm.dag.entryBefore [ "installPackages" ] ''
      target="$HOME/Applications/Home Manager Apps"
      if [ -L "$target" ] && [[ "$(readlink "$target")" == /nix/store/* ]]; then
        run rm "$target"
      fi
    ''
  );

  home.sessionPath = [
    "$HOME/dotfiles/bin"
    "$HOME/.local/bin"
  ];

  imports = [
    ./modules/fish.nix
    ./modules/git.nix
    ./modules/ghostty.nix
    ./modules/helix.nix
    ./modules/zed.nix
    ./modules/hypr/default.nix
    ./modules/waybar/default.nix
  ];
}
