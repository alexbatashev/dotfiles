#export ZSH="$HOME/dotfiles/oh-my-zsh"

HISTFILE="$HOME/.zsh_history"
HISTSIZE=500000
SAVEHIST=500000
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.

source $HOME/dotfiles/aliases.sh
source $HOME/dotfiles/funcs.sh

source $HOME/dotfiles/powerlevel10k/powerlevel10k.zsh-theme

ZSH_THEME="powerlevel10k"

plugins=(git tmux)

alias tmux='tmux -u'

if [ -f /etc/redhat-release ]; then
  bindkey '^[[H' beginning-of-line
  bindkey '^[[F' end-of-line
  bindkey "^[[3~" delete-char
fi

export AUTO_NOTIFY_WHITELIST=("apt-get" "dnf" "cargo" "ninja" "cmake" "make")
export AUTO_NOTIFY_THRESHOLD=30

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f $HOME/dotfiles/p10k.zsh ]] || source $HOME/dotfiles/p10k.zsh
source $HOME/dotfiles/zsh_plugins.sh

_zpcompinit_custom;
autoload -U compinit; compinit;
