if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
end

fish_add_path $HOME/.local/bin

if test -f $HOME/.local/share/swiftly/env.fish
    source $HOME/.local/share/swiftly/env.fish
end

if test -f $HOME/.cargo/env.fish
    source $HOME/.cargo/env.fish
end

if test -f $HOME/.config/fish/local.fish
    source $HOME/.config/fish/local.fish
end

if command -q brew
    eval "$(brew shellenv fish)"
end

if command -q mise
    mise activate fish | source
end

if command -q zoxide
    zoxide init fish | source
end

alias cat bat
alias gt git
alias gti git
alias ll 'eza --long --header --git'
alias ls eza
alias perfgdwarf 'perf record --call-graph dwarf'
alias perfglbr 'perf record --call-graph lbr'
alias perfhw 'perf stat -e cycles,instructions,branches,branch-misses,cache-references,cache-misses'
alias perfio "perf stat -e 'block:*'"
alias perfrpt "perf report -g 'graph,0.5,caller'"
alias tmux 'tmux -u'
alias vim nvim
