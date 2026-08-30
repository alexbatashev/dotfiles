{ pkgs, ... }:
{
  programs.fish = {
    enable = true;

    plugins = [
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
      {
        name = "hydro";
        src = pkgs.fishPlugins.hydro.src;
      }
    ];

    shellAliases = {
      # Modern replacements
      ls = "eza";
      ll = "eza --long --header --git";
      cat = "bat";
      vim = "nvim";

      # Git typo forgiveness
      gt = "git";
      gti = "git";

      # tmux with unicode
      tmux = "tmux -u";

      # perf shortcuts
      perfhw = "perf stat -e cycles,instructions,branches,branch-misses,cache-references,cache-misses";
      perfio = "perf stat -e 'block:*'";
      perfgdwarf = "perf record --call-graph dwarf";
      perfglbr = "perf record --call-graph lbr";
      perfrpt = "perf report -g 'graph,0.5,caller'";
    };

    # Fish doesn't read /etc/profile.d, so the multi-user Nix daemon
    # integration (which puts `nix` on PATH) is never sourced automatically.
    # Pull it in here so `nix` is available in every fish shell.
    shellInit = ''
      if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      end
    '';

    interactiveShellInit = ''
      fish_add_path $HOME/.local/bin
      fish_add_path $HOME/dotfiles/bin
      if test -f $HOME/.local/share/swiftly/env.fish
        source $HOME/.local/share/swiftly/env.fish
      end
      if test -f $HOME/.cargo/env.fish
        source "$HOME/.cargo/env.fish"
      end
      if test -e $HOME/.config/fish/local.fish
        source $HOME/.config/fish/local.fish
      end
    '';
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
}
