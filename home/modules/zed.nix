{ config, pkgs, ... }:
{
  home.packages = [ pkgs.zed-editor ];

  # Symlink Zed config out-of-store so the editor can write back to it
  # (extensions, last-used models, etc.).
  xdg.configFile."zed" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles/zed/.config/zed";
  };
}
