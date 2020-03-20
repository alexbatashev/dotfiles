export XDG_CONFIG_HOME=~/.dotfiles
set -g theme_display_date no

function mkd
  mkdir -p "$argv" && cd "$argv"
end

# grep in vim-readable format
function grepsrc
    if hash ack
        set CLI ack --nogroup --nocolor
    else
        set CLI grep -rn
    end

    if hash perl 2>/dev/null
        $CLI "$argv" . | perl -ne 's/:(?=[0-9]+)/ \+/g; print;'
    else
        $CLI "$argv" . | sed "s/:/ \+/g"
    end
end

