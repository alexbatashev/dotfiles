alias ls 'exa'
alias cat 'bat'
alias ll 'exa --long --header --git'
alias vim 'nvim'
alias perfhw 'perf stat -e cycles,instructions,branches,branch-misses,cache-references,cache-misses'
alias perfio "perf stat -e 'block:*'"
alias perfgdwarf "perf record --call-graph dwarf"
alias perfglbr "perf record --call-graph lbr"
alias perfrpt "perf report -g 'graph,0.5,caller'"

alias gt 'git'
alias gti 'git'
