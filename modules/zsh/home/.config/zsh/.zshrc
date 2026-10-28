[[ -d $XDG_CACHE_HOME/zsh && -d $XDG_STATE_HOME/zsh ]] || mkdir -p $XDG_CACHE_HOME/zsh $XDG_STATE_HOME/zsh

HISTFILE=$XDG_STATE_HOME/zsh/history
HISTSIZE=100000
SAVEHIST=100000
setopt share_history extended_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks
setopt auto_cd interactive_comments no_beep

bindkey -e
WORDCHARS=${WORDCHARS//\/}
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

fpath=(${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share/zsh/site-functions} $fpath)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' cache-path $XDG_CACHE_HOME/zsh/zcompcache
autoload -Uz compinit
zcompdump=$XDG_CACHE_HOME/zsh/zcompdump
zcompdump_fresh=($zcompdump(N.mh-24))
if (( $#zcompdump_fresh )); then
  compinit -C -d $zcompdump
else
  compinit -d $zcompdump
fi
[[ $zcompdump.zwc -nt $zcompdump ]] || zcompile $zcompdump
unset zcompdump zcompdump_fresh

# Caches `tool args...` output and regenerates it only when the tool binary changes.
source_tool_init() {
  local bin=$commands[$1] cache=$XDG_CACHE_HOME/zsh/$1.zsh
  [[ -n $bin ]] || return 0
  [[ $cache -nt $bin ]] || { "$@" >| $cache && zcompile $cache }
  source $cache
}
source_tool_init zoxide init zsh
source_tool_init fzf --zsh
unfunction source_tool_init

alias_if_installed() {
  (( $+commands[${2%% *}] )) && alias $1=$2
}
alias_if_installed cat bat
alias_if_installed gt git
alias_if_installed gti git
alias_if_installed ll 'eza --long --header --git'
alias_if_installed ls eza
alias_if_installed perfgdwarf 'perf record --call-graph dwarf'
alias_if_installed perfglbr 'perf record --call-graph lbr'
alias_if_installed perfhw 'perf stat -e cycles,instructions,branches,branch-misses,cache-references,cache-misses'
alias_if_installed perfio "perf stat -e 'block:*'"
alias_if_installed perfrpt "perf report -g 'graph,0.5,caller'"
alias_if_installed tmux 'tmux -u'
alias_if_installed vim nvim
unfunction alias_if_installed

[[ -r $ZDOTDIR/local.zsh ]] && source $ZDOTDIR/local.zsh

source $ZDOTDIR/prompt.zsh

# zsh-syntax-highlighting must be sourced after every other widget is defined.
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  for file in {$HOMEBREW_PREFIX/share,/usr/share/zsh/plugins,/usr/share}/$plugin/$plugin.zsh(N); do
    source $file
    break
  done
done
unset plugin file
