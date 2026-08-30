{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./obsidian.nix
    ./zed.nix
  ];

  home.packages =
    with pkgs;
    [ fira ]
    ++ lib.optionals (!config.os.shipsUserTools) [
      localsend
      nerd-fonts.jetbrains-mono
    ];
}
