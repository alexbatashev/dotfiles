{config, pkgs, username, ...}:
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
  ];

  programs.home-manager.enable = true;

  home.sessionPath = [
    "$HOME/dotfiles/bin"
    "$HOME/.local/bin"
  ];
}
