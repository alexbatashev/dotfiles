# [host over ssh] pwd vcs duration status ❱, modeled on hydro for fish.
zmodload zsh/datetime
autoload -Uz add-zsh-hook

prompt_dim=$'%{\e[2m%}'
prompt_undim=$'%{\e[22m%}'
prompt_status='❱'
prompt_duration=''
prompt_vcs=''
prompt_vcs_root=''
prompt_vcs_fd=0
prompt_path=''
prompt_command_start=''
prompt_host=''
[[ -n $SSH_CONNECTION ]] && prompt_host="$prompt_dim%m$prompt_undim "

prompt_render() {
  PROMPT="$prompt_host$prompt_path ${prompt_vcs:+$prompt_vcs }${prompt_duration:+$prompt_duration }$prompt_status "
}

# ~/c/dotfiles/m/zsh with the last component bold and the repo root kept whole.
prompt_update_path() {
  local dir=$PWD full='' out='' part
  if [[ $dir == $HOME || $dir == $HOME/* ]]; then
    full=$HOME
    out='~'
    dir=${dir#$HOME}
  fi
  local -a parts=(${(s:/:)dir})
  local last=$parts[-1]
  parts[-1]=()
  for part in $parts; do
    full+=/$part
    if [[ $full != $prompt_vcs_root ]]; then
      [[ $part == .* ]] && part=$part[1,2] || part=$part[1]
    fi
    out+=$prompt_dim/$prompt_undim${part//\%/%%}
  done
  [[ -n $last ]] && out+=$prompt_dim/$prompt_undim%B${last//\%/%%}%b
  [[ -z $out ]] && out=/
  [[ $out == '~' ]] && out='%B~%b'
  prompt_path=$out
}

prompt_set_duration() {
  local -F seconds=$1
  local -i hours=seconds/3600 minutes=seconds%3600/60
  local -F 1 rest=$(( seconds - hours * 3600 - minutes * 60 ))
  local out=''
  (( hours )) && out+=${hours}h
  (( minutes )) && out+=${minutes}m
  out+=${rest}s
  prompt_duration=$out
}

prompt_preexec() {
  prompt_command_start=$EPOCHREALTIME
}

prompt_precmd() {
  local -a codes=($pipestatus)
  if [[ -n $prompt_command_start ]]; then
    local -F elapsed=$(( EPOCHREALTIME - prompt_command_start ))
    prompt_duration=''
    (( elapsed >= 1 )) && prompt_set_duration $elapsed
    prompt_status='❱'
    [[ -n ${codes:#0} ]] && prompt_status="%F{red}| $codes ❱%f"
    prompt_command_start=''
  fi
  prompt_vcs_start
  prompt_update_path
  prompt_render
}

# Sets reply=(kind root) for the nearest enclosing repo. .jj wins over .git
# because colocated jj repos leave git on a detached HEAD.
prompt_find_repo() {
  local dir=$PWD
  while true; do
    [[ -d $dir/.jj ]] && reply=(jj $dir) && return 0
    [[ -e $dir/.git ]] && reply=(git $dir) && return 0
    [[ $dir == / ]] && return 1
    dir=${dir:h}
  done
}

prompt_vcs_git() {
  local line head oid dirty='' out
  local -a ahead_behind
  for line in "${(@f)$(git --no-optional-locks status --porcelain=v2 --branch 2>/dev/null)}"; do
    case $line in
      ('# branch.oid '*) oid=${line#\# branch.oid } ;;
      ('# branch.head '*) head=${line#\# branch.head } ;;
      ('# branch.ab '*) ahead_behind=(${=line#\# branch.ab }) ;;
      ('#'*|'') ;;
      (*) dirty='•' ;;
    esac
  done
  [[ -n $head ]] || return
  [[ $head == '(detached)' ]] && head=$oid[1,7]
  out=$head$dirty
  (( ${ahead_behind[1]#+} )) && out+=" ↑${ahead_behind[1]#+}"
  (( ${ahead_behind[2]#-} )) && out+=" ↓${ahead_behind[2]#-}"
  print -r -- $out
}

prompt_vcs_jj() {
  # --ignore-working-copy: a background snapshot would race the user's own jj commands.
  jj log -r @ --no-graph --ignore-working-copy --color=never -T '
    separate(" ",
      coalesce(
        local_bookmarks.join(" "),
        parents.filter(|p| p.local_bookmarks()).map(|p| p.local_bookmarks().join(" ")).join(" "),
      ),
      change_id.shortest() ++ if(!empty, "•") ++ if(conflict, "×"),
    ) ++ "\n"' 2>/dev/null
}

prompt_vcs_start() {
  prompt_vcs_stop
  if ! prompt_find_repo; then
    prompt_vcs=''
    prompt_vcs_root=''
    return
  fi
  [[ $reply[2] == $prompt_vcs_root ]] || prompt_vcs=''
  prompt_vcs_root=$reply[2]
  exec {prompt_vcs_fd}< <(prompt_vcs_$reply[1])
  zle -F $prompt_vcs_fd prompt_vcs_done
}

# A stale worker dies of SIGPIPE once its fd is closed.
prompt_vcs_stop() {
  (( prompt_vcs_fd )) || return 0
  zle -F $prompt_vcs_fd
  exec {prompt_vcs_fd}<&-
  prompt_vcs_fd=0
}

prompt_vcs_done() {
  local result=''
  read -r -u $1 result
  prompt_vcs_stop
  prompt_vcs=${result//\%/%%}
  prompt_render
  zle reset-prompt
}

add-zsh-hook preexec prompt_preexec
precmd_functions=(prompt_precmd $precmd_functions)
