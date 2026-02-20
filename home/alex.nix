{ pkgs, ... }:
{
  home = {
    username = "alex";
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/alex" else "/home/alex";
    stateVersion = "24.11";
  };

  # Allow unfree packages (zed-editor, etc.)
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./modules/common.nix
    ./modules/fish.nix
    ./modules/git.nix
    ./modules/helix.nix
    ./modules/kitty.nix
    ./modules/tmux.nix
    ./modules/neovim.nix
    ./modules/zed.nix
  ];
}
