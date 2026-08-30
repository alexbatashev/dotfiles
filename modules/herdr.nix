{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  home.packages = lib.optional (
    !config.os.shipsUserTools
  ) inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;

  xdg.configFile."herdr/config.toml" = {
    force = true;
    source = ./herdr/config.toml;
  };
}
