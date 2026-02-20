{ config, pkgs, ... }:
{
  programs.neovim = {
    enable        = true;
    defaultEditor = false;  # helix is the default; set to true to prefer nvim
    vimAlias      = false;  # "vim" alias handled by fish shellAliases
    viAlias       = false;
    package       = pkgs.neovim;
  };

  # Symlink the existing AstroNvim config directory directly (out-of-store)
  # so that lazy.nvim / mason can write back into it (lazy-lock.json, etc.).
  xdg.configFile."nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/dotfiles/nvim/.config/nvim";
  };
}
