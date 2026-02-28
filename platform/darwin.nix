{ pkgs, username, ... }:
{
  system.stateVersion = 6;
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.substituters = [
    "https://zed.cachix.org"
    "https://cache.garnix.io"
  ];
  nix.settings.trusted-public-keys = [
    "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
    "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
  ];

  users.users.${username}.home = "/Users/${username}";

  security.pam.services.sudo_local.touchIdAuth = true;

  programs.fish.enable = true;
  environment.systemPackages = [
    pkgs.vim
  ];
}
