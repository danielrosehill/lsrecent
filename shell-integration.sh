# lsrecent shell integration — source this from ~/.bashrc or ~/.bash_aliases
# ==============================================================================
# Plain `ls` (no arguments) in any directory listed in ~/.config/lsrecent/dirs
# shows the grouped view (TODAY / PAST WEEK / PAST MONTH / PAST 3 MONTHS /
# OLDER). Any arguments (e.g. `ls -la`, `ls foo`) or piped output fall
# through to normal ls.

alias lsr='lsrecent'                       # Grouped view anywhere, on demand
alias lsr-edit='${EDITOR:-nano} ~/.config/lsrecent/dirs'

lsr-add() {  # Enable the grouped view for a directory (default: current dir)
    local d; d=$(realpath "${1:-$PWD}")
    mkdir -p ~/.config/lsrecent
    grep -qxF "$d" ~/.config/lsrecent/dirs 2>/dev/null || echo "$d" >> ~/.config/lsrecent/dirs
    echo "lsrecent enabled for: $d"
}

lsr-remove() {  # Disable the grouped view for a directory (default: current dir)
    local d; d=$(realpath "${1:-$PWD}")
    sed -i "\\#^${d}\$#d" ~/.config/lsrecent/dirs
    echo "lsrecent disabled for: $d"
}

ls() {
    if (( $# == 0 )) && [[ -t 1 && -f ~/.config/lsrecent/dirs ]]; then
        local d
        while IFS= read -r d; do
            [[ -z "$d" || "$d" == \#* ]] && continue
            d="${d/#\~/$HOME}"
            if [[ "$PWD" == "$d" ]]; then
                lsrecent
                return
            fi
        done < ~/.config/lsrecent/dirs
    fi
    command ls --color=auto "$@"
}
