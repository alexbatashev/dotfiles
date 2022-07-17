function mkd() {
  mkdir -p "$@" && cd "$@"
}

# Determine size of a file or total size of a directory
function fs() {
	if du -b /dev/null > /dev/null 2>&1; then
		local arg=-sbh;
	else
		local arg=-sh;
	fi
	if [[ -n "$@" ]]; then
		du $arg -- "$@";
	else
		du $arg .[^.]* ./*;
	fi;
}

# Normalize `open` across Linux, macOS, and Windows.
# This is needed to make the `o` function (see below) cross-platform.
if [ ! $(uname -s) = 'Darwin' ]; then
	if grep -q Microsoft /proc/version; then
		# Ubuntu on Windows using the Linux subsystem
		alias open='explorer.exe';
	else
		alias open='xdg-open';
	fi
fi

# `o` with no arguments opens the current directory, otherwise opens the given
# location
function o() {
	if [ $# -eq 0 ]; then
		open .;
	else
		open "$@";
	fi;
}

extract () {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2) tar xvjf $1   ;;
      *.tar.gz)  tar xvzf $1   ;;
      *.tar.xz)  tar xvfJ $1   ;;
      *.bz2)     bunzip2 $1    ;;
      *.rar)     unrar x $1    ;;
      *.gz)      gunzip $1     ;;
      *.tar)     tar xvf $1    ;;
      *.tbz2)    tar xvjf $1   ;;
      *.tgz)     tar xvzf $1   ;;
      *.zip)     unzip $1      ;;
      *.Z)       uncompress $1 ;;
      *.7z)      7z x $1       ;;
      *)         echo "'$1' cannot be extracted via >extract<" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

dotall() {
  OTYPE="svg"
  if [ -n $2 ] ; then
    OTYPE=$2;
  fi
  if [ -n $1 ] ; then
    for f in *.dot
    do
      dot -T $OTYPE $f -o $1/$f.$OTYPE;
    done
  fi
}

enable_llvm_clangd() {
  BASE_DIR=
  if [[ "$OSTYPE" == "darwin"* ]]; then
    BASE_DIR=~/Library/Preferences/clangd/
  else
    BASE_DIR=~/.config/clangd/
  fi
  mkdir -p $BASE_DIR
  echo -n "---\n" >> $BASE_DIR/config.yaml
  echo -n "If:\n" >> $BASE_DIR/config.yaml
  echo -n "  PatternMatch: " >> $BASE_DIR/config.yaml
  echo -n $1 >> $BASE_DIR/config.yaml
  echo -n ".*\n" >> $BASE_DIR/config.yaml
  echo -n "Index:\n" >> $BASE_DIR/config.yaml
  echo -n "  External:\n" >> $BASE_DIR/config.yaml
  echo -n "    Server: clangd-index.llvm.org:5900\n" >> $BASE_DIR/config.yaml
  echo -n "    MountPoint: " >> $BASE_DIR/config.yaml
  echo -n $1 >> $BASE_DIR/config.yaml
  echo -n "\n" >> $BASE_DIR/config.yaml
}

_zpcompinit_custom() {
  setopt extendedglob local_options
  autoload -Uz compinit
  local zcd=${ZDOTDIR:-$HOME}/.zcompdump
  local zcdc="$zcd.zwc"
  # Compile the completion dump to increase startup speed, if dump is newer or doesn't exist,
  # in the background as this is doesn't affect the current session
  if [[ -f "$zcd"(#qN.m+1) ]]; then
        compinit -i -d "$zcd"
        { rm -f "$zcdc" && zcompile "$zcd" } &!
  else
        compinit -C -d "$zcd"
        { [[ ! -f "$zcdc" || "$zcd" -nt "$zcdc" ]] && rm -f "$zcdc" && zcompile "$zcd" } &!
  fi
}
