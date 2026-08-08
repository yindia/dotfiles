tqindia() {
    local dir="$HOME/workspace/tqindia"
    if [[ -d "$dir" ]]; then
        cd "$dir"
    else
        print -u2 "tqindia: directory not found: $dir"
        return 1
    fi
}
