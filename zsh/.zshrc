ZSH_THEME="powerlevel9k/powerlevel9k"
DISABLE_UPDATE_PROMPT=true
DISABLE_AUTO_UPDATE=true
export ZPLUG_HOME=$ZSH_ROOT/zplug
source $ZPLUG_HOME/init.zsh
source $ZSH_ROOT/.aliases
source $ZSH_ROOT/.functions

POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_CUSTOM_BATTERY_STATUS="prompt_zsh_battery_level"
POWERLEVEL9K_DISABLE_RPROMPT=true
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="↱"
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="↳ "
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)

HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

zplug "zsh-users/zsh-history-substring-search"
zplug "bhilburn/powerlevel9k", use:powerlevel9k.zsh-theme
zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-autosuggestions"

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

setopt menucomplete
zstyle ':completion:*' menu select=1 _complete _ignored _approximate
setopt correctall
