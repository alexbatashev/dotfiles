{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    terminal = "screen-256color";

    # Window / pane numbering
    baseIndex = 1;
    historyLimit = 100000;

    extraConfig = ''
      setw -g pane-base-index 1
      set -g renumber-windows on
    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
    ];
  };
}
