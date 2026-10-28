export ZDOTDIR=$HOME/.config/zsh
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state

# Equivalent to `eval "$(brew shellenv)"` without spawning brew on every start.
if [[ -x /opt/homebrew/bin/brew ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
  export HOMEBREW_CELLAR=$HOMEBREW_PREFIX/Cellar
  export HOMEBREW_REPOSITORY=$HOMEBREW_PREFIX
  export INFOPATH=$HOMEBREW_PREFIX/share/info:
fi

[[ -r $XDG_DATA_HOME/swiftly/env.sh ]] && source $XDG_DATA_HOME/swiftly/env.sh

# mise shims instead of `mise activate`: its per-prompt hook-env costs ~25ms.
typeset -U path
path=(
  $HOME/.local/bin
  $HOME/.cargo/bin(N/)
  $XDG_DATA_HOME/mise/shims(N/)
  ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/bin}
  ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/sbin}
  $path
)
