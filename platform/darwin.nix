{ pkgs, username, ... }:
{
  system.stateVersion = 6;
  nix.settings.experimental-features = "nix-command flakes";

  users.users.${username}.home = "/Users/${username}";

  security.pam.services.sudo_local.touchIdAuth = true;

  programs.fish.enable = true;
  environment.systemPackages = [
    pkgs.vim
  ];
}
