{ lib, ... }:
{
  programs.fish.interactiveShellInit = lib.mkAfter ''
    eval "$(/opt/homebrew/bin/brew shellenv fish)"
  '';
}
