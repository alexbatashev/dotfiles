# orion: headless aarch64-linux box managed by standalone home-manager (no
# NixOS). It runs T3 Code as a personal coding-agent server, reachable over the
# tailnet.
{ ... }:
{
  imports = [
    ../modules/t3code.nix
  ];

  # Standalone home-manager on a non-NixOS host: integrate with the system's
  # session/systemd so the user service picks up the right environment.
  targets.genericLinux.enable = true;

  services.t3code = {
    enable = true;
    # orion's Tailscale IP — the server is only reachable over the tailnet.
    host = "100.86.155.54";
    # version = "0.0.27"; # pin here for a fully reproducible deployment
  };
}
