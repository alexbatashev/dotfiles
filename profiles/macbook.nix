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
  nix.settings.trusted-users = [
    "root"
    "alex"
    "@admin"
  ];
  nix.settings.builders-use-substitutes = true;

  users.users.${username}.home = "/Users/${username}";

  security.pam.services.sudo_local.touchIdAuth = true;

  # Fast keyboard key repeat. Mirrored on Linux/Hyprland in
  # ../modules/hypr/input.conf (repeat_delay = 225, repeat_rate = 67).
  # Units are ~15ms each: InitialKeyRepeat 15 -> 225ms delay, KeyRepeat 1 -> ~67 Hz.
  # The delay is kept at macOS's "fast" slider position (15) rather than lower,
  # so normal typing doesn't trip accidental repeats.
  # ApplePressAndHold must be off, otherwise held keys show the accent menu
  # instead of repeating.
  system.defaults.NSGlobalDomain = {
    InitialKeyRepeat = 15;
    KeyRepeat = 1;
    ApplePressAndHoldEnabled = false;
  };

  programs.fish.enable = true;
  environment.systemPackages = [
    pkgs.vim
  ];
}
