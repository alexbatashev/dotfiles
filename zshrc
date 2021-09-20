#export ZSH="$HOME/dotfiles/oh-my-zsh"

source $HOME/dotfiles/aliases.sh
source $HOME/dotfiles/funcs.sh

source $HOME/dotfiles/powerlevel10k/powerlevel10k.zsh-theme

ZSH_THEME="powerlevel10k"

plugins=(git tmux)

alias tmux='tmux -u'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f $HOME/dotfiles/p10k.zsh ]] || source $HOME/dotfiles/p10k.zsh
