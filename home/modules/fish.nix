{ pkgs, ... }:
{
  programs.fish = {
    enable = true;

    # Plugins (replaces fisher + fish_plugins file)
    plugins = [
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
      { name = "hydro";    src = pkgs.fishPlugins.hydro.src; }
    ];

    shellAliases = {
      # Modern replacements
      ls  = "eza";
      ll  = "eza --long --header --git";
      cat = "bat";
      vim = "nvim";

      # Git typo forgiveness
      gt  = "git";
      gti = "git";

      # tmux with unicode
      tmux = "tmux -u";

      # perf shortcuts
      perfhw     = "perf stat -e cycles,instructions,branches,branch-misses,cache-references,cache-misses";
      perfio     = "perf stat -e 'block:*'";
      perfgdwarf = "perf record --call-graph dwarf";
      perfglbr   = "perf record --call-graph lbr";
      perfrpt    = "perf report -g 'graph,0.5,caller'";
    };

    interactiveShellInit = ''
      fish_add_path $HOME/.local/bin
      fish_add_path $HOME/dotfiles/bin
    '';
  };

  # zoxide (z / zi commands) — fish integration enabled automatically
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
}
