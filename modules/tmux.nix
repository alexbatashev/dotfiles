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
      set -g prefix2 C-b
      setw -g pane-base-index 1
      set -g renumber-windows on

      bind h split-window -v -c "#{pane_current_path}"
      bind v split-window -h -c "#{pane_current_path}"
      bind x kill-pane

      bind -n C-l select-pane -L
      bind -n C-h select-pane -R
      bind -n C-k select-pane -U
      bind -n C-j select-pane -D

      bind -n M-1 select-window -t 1
      bind -n M-2 select-window -t 2
      bind -n M-3 select-window -t 3
      bind -n M-4 select-window -t 4
      bind -n M-5 select-window -t 5
      bind -n M-6 select-window -t 6
      bind -n M-7 select-window -t 7
      bind -n M-8 select-window -t 8
      bind -n M-9 select-window -t 9

      bind -n M-l select-window -t -1
      bind -n M-h select-window -t +1

      set -g default-terminal "tmux-256color"
      set -ag terminal-overrides ",*:RGB"
      set -g mouse on
      set -g base-index 1
      setw -g pane-base-index 1
      set -g renumber-windows on
      set -g history-limit 50000
      set -g escape-time 0
      set -g focus-events on
      set -g set-clipboard on
      set -g allow-passthrough on
      setw -g aggressive-resize on
      set -g detach-on-destroy off

      set -g status-position top
      set -g status-interval 5
      set -g status-left-length 30
      set -g status-right-length 50
      set -g window-status-separator ""

      set -g status-style "bg=default,fg=default"
      set -g status-left "#[fg=black,bg=blue,bold] #S #[bg=default] "
      set -g status-right "#[fg=blue]#{?client_prefix,PREFIX ,}#[fg=brightblack]#h "
      set -g window-status-format "#[fg=brightblack] #I:#W "
      set -g window-status-current-format "#[fg=blue,bold] #I:#W "
      set -g pane-border-style "fg=brightblack"
      set -g pane-active-border-style "fg=blue"
      set -g message-style "bg=default,fg=blue"
      set -g message-command-style "bg=default,fg=blue"
      set -g mode-style "bg=blue,fg=black"
      setw -g clock-mode-colour blue
    '';

    plugins = with pkgs.tmuxPlugins; [
      cpu
    ];
  };
}
