{ pkgs, lib, ... }:
{
  # Let home-manager manage itself
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Filesystem / search
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

    # Version control
    git-lfs
    gh

    # Build tools
    cmake
    ninja

    # Languages / runtimes
    nodejs
    python3

    # Diagnostics / profiling (Linux kernel perf is better installed system-wide)
    graphviz

    # Fonts
    nerd-fonts.jetbrains-mono
    fira  # Fira Sans — used by Hyprland groupbar / waybar
  ] ++ lib.optionals stdenv.isLinux [
    clang
    lldb
    gdb
  ];

  # Add ~/dotfiles/bin and ~/.local/bin to XDG session path
  home.sessionPath = [
    "$HOME/dotfiles/bin"
    "$HOME/.local/bin"
  ];
}
