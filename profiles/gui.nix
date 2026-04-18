{ pkgs, ... }:
{
  home.packages = with pkgs; [
    localsend
    nerd-fonts.jetbrains-mono
    fira
  ];

  imports = [
    ../modules/obsidian.nix
    ../modules/zed.nix
  ];
}
