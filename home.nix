{
  pkgs,
  username,
  lib,
  ...
}:
{
  home.username = username;
  home.homeDirectory =
    if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${username}" else "/home/${username}";

  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    wget
    curl
    yazi
    bloaty

    rustup

    jujutsu

    mermaid-cli

    cmake
    ninja
    pnpm
    starpls
    # nixpkgs bazelisk ships a stub sha256sum that shadows coreutils
    (symlinkJoin {
      name = "bazelisk";
      paths = [ bazelisk ];
      postBuild = "rm $out/bin/sha256sum";
    })
    (pkgs.writeShellScriptBin "bazel" ''
      exec ${lib.getExe pkgs.bazelisk} "$@"
    '')

    nodejs
    python3
    uv

    graphviz

    nil
    nixd
  ];

  programs.home-manager.enable = true;
  services.syncthing.enable = true;

  home.activation.migrateLegacyDarwinAppsLink = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    lib.hm.dag.entryBefore [ "installPackages" ] ''
      target="$HOME/Applications/Home Manager Apps"
      if [ -L "$target" ] && [[ "$(readlink "$target")" == /nix/store/* ]]; then
        run rm "$target"
      fi
    ''
  );

  home.sessionPath = [
    "$HOME/dotfiles/bin"
    "$HOME/.local/bin"
  ];

  imports = [
    ./modules/agents.nix
    ./modules/core-tools.nix
    ./modules/fish.nix
    ./modules/ghostty.nix
    ./modules/git.nix
    ./modules/helix.nix
    ./modules/herdr.nix
    ./modules/mise.nix
    ./modules/nas-mount.nix
    ./modules/tmux.nix
  ];
}
