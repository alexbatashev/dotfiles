DISABLE_UPDATE_PROMPT=true
DISABLE_AUTO_UPDATE=true
export ZPLUG_HOME=$ZSH_ROOT/zplug
source $ZPLUG_HOME/init.zsh
source $ZSH_ROOT/.aliases
source $ZSH_ROOT/.functions
source $ZSH_ROOT/.workflow

HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

zplug "zsh-users/zsh-history-substring-search"
zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-autosuggestions"
zplug "mafredri/zsh-async", from:github
zplug "sindresorhus/pure", use:pure.zsh, from:github, as:theme
zplug "webyneter/docker-aliases", use:docker-aliases.plugin.zsh

zplug load

bindkey "^[OB" down-line-or-search
bindkey "^[OC" forward-char
bindkey "^[OD" backward-char
bindkey "^[OF" end-of-line
bindkey "^[OH" beginning-of-line
bindkey "^[[1~" beginning-of-line
bindkey "^[[3~" delete-char
bindkey "^[[4~" end-of-line
bindkey "^[[5~" up-line-or-history
bindkey "^[[6~" down-line-or-history
bindkey "^?" backward-delete-char

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down

setopt menucomplete
zstyle ':completion:*' menu select=1 _complete _ignored _approximate
setopt correctall

if [ -f "/opt/intel/tbb/bin/tbbvars.sh" ]
then
    source /opt/intel/tbb/bin/tbbvars.sh
fi
