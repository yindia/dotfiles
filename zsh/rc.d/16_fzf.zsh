# Some sane defaults for fzf
export FZF_DEFAULT_OPTS="--ansi --height=50% --tmux=bottom,50%,border-native --border=top --layout=reverse-list"

# Ctrl-R history, Ctrl-T paths, Alt-C cd. Must stay ahead of fzf-tab (17_),
# which rebinds Tab back to itself afterwards.
source <(fzf --zsh)
