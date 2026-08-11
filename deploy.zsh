#!/usr/bin/env zsh

setopt extended_glob err_exit

zmodload -m -F zsh/files b:zf_\*

SCRIPT_DIR=${0:A:h}
# with systemd-homed `a`/`A` expands to storage location `/home/username.homedir` instead of mounted location `/home/username`
# therefore massage SCRIPT_DIR to expected home location by removing `.homedir` from it
if [[ $SCRIPT_DIR == $HOME.homedir* ]]; then
    SCRIPT_DIR=${SCRIPT_DIR/.homedir/}
fi
cd $SCRIPT_DIR

# Default XDG paths
XDG_CACHE_HOME=$HOME/.cache
XDG_CONFIG_HOME=$HOME/.config
XDG_DATA_HOME=$HOME/.local/share
XDG_STATE_HOME=$HOME/.local/state

# Create required directories
print "Creating required directory tree..."
zf_mkdir -p $XDG_CONFIG_HOME/{aerospace,ghostty,git/local,htop,jj/conf.d,ranger,gem,tig,gnupg,nvim/{plugin,after},wezterm,yazi}
zf_mkdir -p $XDG_CACHE_HOME/{vim/{backup,swap,undo},zsh,tig}
zf_mkdir -p $XDG_DATA_HOME/{{goenv,jenv,luaenv,nodenv,phpenv,plenv,pyenv,rbenv}/plugins,zsh,man/man1,vim/spell,nvim/site/pack/plugins}
zf_mkdir -p $XDG_STATE_HOME
zf_mkdir -p $HOME/.local/{bin,etc}
zf_chmod 700 $XDG_CONFIG_HOME/gnupg
print "  ...done"

# Link zshenv if needed
print "Checking for ZDOTDIR env variable..."
if [[ $ZDOTDIR == $SCRIPT_DIR/zsh ]]; then
    print "  ...present and valid, skipping .zshenv symlink"
else
    print "  ...failed to match this script dir. ZDOTDIR is \"$ZDOTDIR\", which doesn't match expected value \"$SCRIPT_DIR/zsh\". Symlinking .zshenv"
    zf_ln -sfn $SCRIPT_DIR/zsh/.zshenv ${ZDOTDIR:-$HOME}/.zshenv
fi

# Link config files
print "Linking config files..."
zf_ln -sfn $SCRIPT_DIR/vim $XDG_CONFIG_HOME/vim
zf_ln -sfn $SCRIPT_DIR/nvim/init.lua $XDG_CONFIG_HOME/nvim/init.lua
zf_ln -sfn $SCRIPT_DIR/nvim/init $XDG_CONFIG_HOME/nvim/plugin/init
zf_ln -sfn $SCRIPT_DIR/nvim/lsp $XDG_CONFIG_HOME/nvim/after/lsp
zf_ln -sfn $SCRIPT_DIR/nvim/ftplugin $XDG_CONFIG_HOME/nvim/ftplugin
zf_ln -sfn $SCRIPT_DIR/nvim/plugins $XDG_DATA_HOME/nvim/site/pack/plugins/start
zf_ln -sfn $SCRIPT_DIR/tmux $XDG_CONFIG_HOME/tmux
zf_ln -sfn $SCRIPT_DIR/configs/aerospace.toml $XDG_CONFIG_HOME/aerospace/aerospace.toml
zf_ln -sfn $SCRIPT_DIR/configs/ghostty $XDG_CONFIG_HOME/ghostty/config
# WezTerm resolves its config as $WEZTERM_CONFIG_FILE, then $HOME/.wezterm.lua,
# then the XDG path. Both file locations are linked, rather than only the XDG
# one, because WezTerm exports the path it booted with as WEZTERM_CONFIG_FILE
# into every pane it spawns. Long-lived panes therefore keep resolving
# $HOME/.wezterm.lua, and deleting it breaks `wezterm` inside those sessions
# ("Error opening ...: No such file or directory") until a full app restart.
# A stale regular file there is backed up first, since it would otherwise win
# over the XDG path and shadow this config with no error to explain it.
if [[ -f $HOME/.wezterm.lua && ! -L $HOME/.wezterm.lua ]]; then
    print "  ...found legacy ~/.wezterm.lua, backing up to ~/.wezterm.lua.bak"
    zf_mv $HOME/.wezterm.lua $HOME/.wezterm.lua.bak
fi
zf_ln -sfn $SCRIPT_DIR/configs/wezterm.lua $XDG_CONFIG_HOME/wezterm/wezterm.lua
zf_ln -sfn $SCRIPT_DIR/configs/wezterm.lua $HOME/.wezterm.lua
zf_ln -sfn $SCRIPT_DIR/configs/gitconfig $XDG_CONFIG_HOME/git/config
zf_ln -sfn $SCRIPT_DIR/configs/gitattributes $XDG_CONFIG_HOME/git/attributes
zf_ln -sfn $SCRIPT_DIR/configs/gitignore $XDG_CONFIG_HOME/git/ignore
zf_ln -sfn $SCRIPT_DIR/configs/jj.toml $XDG_CONFIG_HOME/jj/conf.d/dotfiles.toml
zf_ln -sfn $SCRIPT_DIR/configs/tigrc $XDG_CONFIG_HOME/tig/config
zf_ln -sfn $SCRIPT_DIR/configs/htoprc $XDG_CONFIG_HOME/htop/htoprc
zf_ln -sfn $SCRIPT_DIR/configs/ranger $XDG_CONFIG_HOME/ranger/rc.conf
zf_ln -sfn $SCRIPT_DIR/configs/gemrc $XDG_CONFIG_HOME/gem/gemrc
zf_ln -sfn $SCRIPT_DIR/configs/ranger-plugins $XDG_CONFIG_HOME/ranger/plugins
zf_ln -sfn $SCRIPT_DIR/yazi/init.lua $XDG_CONFIG_HOME/yazi/init.lua
zf_ln -sfn $SCRIPT_DIR/yazi/keymap.toml $XDG_CONFIG_HOME/yazi/keymap.toml
zf_ln -sfn $SCRIPT_DIR/yazi/theme.toml $XDG_CONFIG_HOME/yazi/theme.toml
zf_ln -sfn $SCRIPT_DIR/yazi/yazi.toml $XDG_CONFIG_HOME/yazi/yazi.toml
zf_ln -sfn $SCRIPT_DIR/yazi/plugins $XDG_CONFIG_HOME/yazi/plugins
zf_ln -sfn $SCRIPT_DIR/gpg/gpg.conf $XDG_CONFIG_HOME/gnupg/gpg.conf
zf_ln -sfn $SCRIPT_DIR/gpg/gpg-agent.conf $XDG_CONFIG_HOME/gnupg/gpg-agent.conf
zf_ln -sfn $SCRIPT_DIR/tools/git-diff-pager $HOME/.local/bin/git-diff-pager
print "  ...done"

# `git clean -ffd` below deletes everything untracked in this tree, and the git
# hooks run this script on every checkout and merge. That is harmless for build
# artifacts, but a skill that was just written and not committed yet would go
# with it, so stop while it can still be rescued.
print "Checking for uncommitted Claude Code skills..."
untracked_skills=$(git ls-files --others --exclude-standard --directory claude/skills)
if [[ -n $untracked_skills ]]; then
    print "  ...found uncommitted paths under claude/skills:"
    for untracked_skill in ${(f)untracked_skills}; do
        print "       $untracked_skill"
    done
    print "  ...\`git clean -ffd\` in this script would delete them without warning."
    print "     Commit them with \`git add claude/skills\` or move them out, then deploy again."
    exit 1
fi
print "  ...none found"

# Make sure submodules are installed
print "Syncing submodules..."
git submodule sync > /dev/null
git submodule update --init --recursive > /dev/null
git clean -ffd
print "  ...done"

# Link Claude Code skills
#
# claude/skills holds one directory per skill, committed directly or added as a
# submodule, the same way nvim/plugins and zsh/plugins work. claude/skills.conf
# groups them into profiles, and $CLAUDE_PROFILE picks which profile this
# machine gets. Only symlinks pointing back into claude/skills are ever created
# or removed here, so skills installed into ~/.claude/skills by anything else
# are never touched.
print "Linking Claude Code skills..."
claude_profile=${CLAUDE_PROFILE:-default}
claude_skills_dir=$SCRIPT_DIR/claude/skills
claude_skills_conf=$SCRIPT_DIR/claude/skills.conf
claude_skills_target=$HOME/.claude/skills

if [[ $claude_profile == none ]]; then
    print "  ...CLAUDE_PROFILE=none, skipping"
elif [[ ! -f $claude_skills_conf ]]; then
    print "  ...no ${claude_skills_conf:t} found, skipping"
else
    # Read the profile sections. A section stays empty rather than absent when
    # it has no entries, so an intentionally empty profile is distinguishable
    # from one that was never declared.
    typeset -A claude_profiles
    claude_section=""
    while IFS= read -r claude_line || [[ -n $claude_line ]]; do
        claude_line=${claude_line%%\#*}
        claude_line=${claude_line##[[:space:]]#}
        claude_line=${claude_line%%[[:space:]]#}
        if [[ -z $claude_line ]]; then
            continue
        fi
        if [[ $claude_line == \[*\] ]]; then
            claude_section=${claude_line[2,-2]}
            if (( ! ${+claude_profiles[$claude_section]} )); then
                claude_profiles[$claude_section]=""
            fi
            continue
        fi
        if [[ -n $claude_section ]]; then
            claude_profiles[$claude_section]+="$claude_line"$'\n'
        fi
    done < $claude_skills_conf

    # Flatten the selected profile, following @profile includes. The visited
    # set keeps a profile that includes itself, directly or in a cycle, from
    # looping forever.
    claude_queue=($claude_profile)
    claude_selected=()
    claude_unknown=()
    typeset -A claude_visited
    while (( ${#claude_queue} > 0 )); do
        claude_current=${claude_queue[1]}
        claude_queue=(${claude_queue[2,-1]})
        if (( ${+claude_visited[$claude_current]} )); then
            continue
        fi
        claude_visited[$claude_current]=1
        if (( ! ${+claude_profiles[$claude_current]} )); then
            claude_unknown+=($claude_current)
            continue
        fi
        for claude_entry in ${(f)claude_profiles[$claude_current]}; do
            if [[ -z $claude_entry ]]; then
                continue
            elif [[ $claude_entry == @* ]]; then
                claude_queue+=(${claude_entry#@})
            else
                claude_selected+=($claude_entry)
            fi
        done
    done
    claude_selected=(${(u)claude_selected})

    for claude_current in $claude_unknown; do
        print "  ...profile \"$claude_current\" is not declared in ${claude_skills_conf:t}, skipping it"
    done

    zf_mkdir -p $claude_skills_target

    # Retract links this repo made earlier that the current profile no longer
    # selects, so switching profiles is not additive. Links pointing anywhere
    # else belong to someone else and are left as they are.
    for claude_link in $claude_skills_target/*(#qN@); do
        if [[ $(readlink $claude_link) != $claude_skills_dir/* ]]; then
            continue
        fi
        if (( ${claude_selected[(Ie)${claude_link:t}]} == 0 )); then
            zf_rm $claude_link
            print "  ...unlinked \"${claude_link:t}\", no longer in profile \"$claude_profile\""
        fi
    done

    claude_linked=0
    for claude_skill in $claude_selected; do
        if [[ ! -d $claude_skills_dir/$claude_skill ]]; then
            print "  ...\"$claude_skill\" is listed in ${claude_skills_conf:t} but absent from claude/skills, skipping"
            continue
        fi
        # Something already sits under this name: a real directory installed by
        # another tool, or a symlink some other installer made. Overwriting it
        # would destroy work this repo does not own, so defer and say so. Links
        # already pointing into claude/skills are ours and get refreshed below.
        # `-L` is tested separately because `-e` is false for a broken symlink.
        if [[ -e $claude_skills_target/$claude_skill || -L $claude_skills_target/$claude_skill ]]; then
            claude_existing=""
            if [[ -L $claude_skills_target/$claude_skill ]]; then
                claude_existing=$(readlink $claude_skills_target/$claude_skill)
            fi
            if [[ $claude_existing != $claude_skills_dir/* ]]; then
                print "  ...\"$claude_skill\" already exists in ~/.claude/skills and was not put there by this repo, leaving it alone"
                continue
            fi
        fi
        zf_ln -sfn $claude_skills_dir/$claude_skill $claude_skills_target/$claude_skill
        claude_linked=$(( claude_linked + 1 ))
    done
    print "  ...done, linked $claude_linked skill(s) for profile \"$claude_profile\""
fi

print "Compiling zsh plugins..."
autoload -Uz zrecompile
for zsh_plugin_file in $SCRIPT_DIR/zsh/plugins/**/*.zsh{-theme,}(#q.); do
    zrecompile -pq $zsh_plugin_file
done
print "  ...done"

# Install hook to call deploy script after successful pull
print "Installing git hooks..."
zf_mkdir -p .git/hooks
zf_ln -sfn ../../deploy.zsh .git/hooks/post-merge
zf_ln -sfn ../../deploy.zsh .git/hooks/post-checkout
print "  ...done"

if (( ${+commands[make]} )); then
    # Make install git-extras
    print "Installing git-extras..."
    pushd tools/git-extras
    PREFIX=$HOME/.local make install > /dev/null
    popd
    print "  ...done"

    if (( ${+commands[which]} )); then
        print "Installing git-quick-stats..."
        pushd tools/git-quick-stats
        PREFIX=$HOME/.local make install > /dev/null
        popd
        print "  ...done"
    fi
fi

print "Installing fzf..."
pushd tools/fzf
if fzf_install_output=$(./install --bin); then
    zf_ln -sfn $SCRIPT_DIR/tools/fzf/bin/fzf $HOME/.local/bin/fzf
    zf_ln -sfn $SCRIPT_DIR/tools/fzf/bin/fzf-tmux $HOME/.local/bin/fzf-tmux
    zf_ln -sfn $SCRIPT_DIR/tools/fzf/man/man1/fzf.1 $XDG_DATA_HOME/man/man1/fzf.1
    zf_ln -sfn $SCRIPT_DIR/tools/fzf/man/man1/fzf-tmux.1 $XDG_DATA_HOME/man/man1/fzf-tmux.1
    print "  ...done"
else
    print $fzf_install_output
    print "  ...error detected, ignoring, please check the fzf installation guide"
fi
popd

if (( ${+commands[perl]} )); then
    # Install diff-so-fancy
    print "Installing diff-so-fancy..."
    zf_ln -sfn $SCRIPT_DIR/tools/diff-so-fancy/diff-so-fancy $HOME/.local/bin/diff-so-fancy
    print "  ...done"
fi

if (( ${+commands[vim]} )); then
    # Generate vim help tags
    print "Generating vim helptags..."
    command vim --not-a-term -i "NONE" -c "helptags ALL" -c "qall" &> /dev/null
    print "  ...done"
fi

# markdown-preview.nvim is shipped as a pre-built binary that is downloaded
# rather than checked in, so it has to be fetched here. Its own installer
# (`mkdp#util#install()`) is not used because it decides whether to download by
# running `<binary> --version`, which fails on this release -- it would refetch
# 50MB on every deploy, and deploy runs from the post-merge/post-checkout
# hooks. The stamp file below is the version check instead.
mkdp_dir=$SCRIPT_DIR/nvim/plugins/markdown-preview.nvim
if [[ -d $mkdp_dir ]]; then
    print "Installing markdown-preview binary..."
    mkdp_version=$(grep -m1 '"version"' $mkdp_dir/package.json)
    mkdp_version=${mkdp_version//[^0-9.]/}
    if [[ -f $mkdp_dir/app/bin/.version && "$(<$mkdp_dir/app/bin/.version)" == $mkdp_version ]]; then
        print "  ...v$mkdp_version already present, skipping"
    elif mkdp_install_output=$($mkdp_dir/app/install.sh v$mkdp_version 2>&1); then
        print -r -- $mkdp_version > $mkdp_dir/app/bin/.version
        print "  ...done"
    else
        print $mkdp_install_output
        print "  ...download failed, :MarkdownPreview stays broken until app/install.sh succeeds"
    fi
fi

if (( ${+commands[nvim]} )); then
    # Generate nvim help tags
    print "Generating nvim helptags..."
    command nvim --headless -c "helptags ALL" -c "qall" &> /dev/null
    print "  ...done"
    # Update treesitter config
    print "Updating tree-sitter parsers..."
    command nvim --headless -c "TSUpdate" -c "qall" &> /dev/null
    print "  ...done"
    # Update mason registries
    print "Updating mason registries..."
    command nvim --headless -c "MasonUpdate" -c "qall" &> /dev/null
    print "  ...done"
fi

# For each env-wrapper link its plugins
print "Linking env-wrappers' plugins..."
    for env_wrapper in $SCRIPT_DIR/env-wrappers/*; do
        # 'plugin' here is a directory with name which doesn't match env-wrapper's name
        for env_wrapper_plugin in $env_wrapper/^${env_wrapper:t}$*(#qN/); do
            zf_ln -sfn $env_wrapper_plugin $XDG_DATA_HOME/${env_wrapper:t}/plugins/${env_wrapper_plugin:t}
        done
    done
    zf_ln -sfn $SCRIPT_DIR/env-wrappers/goenv/goenv/plugins/go-build $XDG_DATA_HOME/goenv/plugins/go-build
    zf_ln -sfn $SCRIPT_DIR/env-wrappers/jenv/jenv/available-plugins/export $XDG_DATA_HOME/jenv/plugins/export
    zf_ln -sfn $SCRIPT_DIR/env-wrappers/pyenv/default-packages $XDG_DATA_HOME/pyenv/default-packages
    zf_ln -sfn $SCRIPT_DIR/env-wrappers/rbenv/default-gems $XDG_DATA_HOME/rbenv/default-gems
print "  ...done"

# Trigger zsh run with powerlevel10k prompt to download gitstatusd
print "Downloading gitstatusd for powerlevel10k..."
zsh -is <<< '' &> /dev/null
print "  ...done"

# Install task to pull updates every midnight
print "Installing periodic update task..."
if (( ${+commands[systemctl]} )); then
    print "  ...systemd detected, installing timer for periodic updates..."

    if (( EUID == 0 )); then
        systemd_unit_dir=/etc/systemd/system
        systemctl_cmd=(systemctl)
        print "  ...running as root, installing system-wide timer..."
    else
        systemd_unit_dir=$XDG_CONFIG_HOME/systemd/user
        systemctl_cmd=(systemctl --user)
        print "  ...running as regular user, installing user timer..."
    fi
    zf_mkdir -p $systemd_unit_dir

    service_name=pull-dotfiles.service
    service_content="[Unit]
Description=Pull dotfiles update
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/git -c user.name=systemd.update -c user.email=systemd@localhost pull
WorkingDirectory=$SCRIPT_DIR"
    print -r -- $service_content > $systemd_unit_dir/$service_name

    timer_name=pull-dotfiles.timer
    timer_content="[Unit]
Description=Pull dotfiles update daily

[Timer]
OnCalendar=daily
RandomizedDelaySec=120s
Persistent=true

[Install]
WantedBy=timers.target"
    print -r -- $timer_content > $systemd_unit_dir/$timer_name

    if ${systemctl_cmd[@]} daemon-reload > /dev/null && ${systemctl_cmd[@]} enable --now $timer_name > /dev/null; then
       print "  ...done"
    else
       print "Failed to install systemd timer. Check permissions and systemd setup"
    fi
elif (( ${+commands[crontab]} )); then
    print "  ...cron detected, installing job for periodic updates..."
    cron_task="cd $SCRIPT_DIR && git -c user.name=cron.update -c user.email=cron@localhost pull"
    cron_schedule="0 0 * * * $cron_task"
    if cat <(grep --ignore-case --invert-match --fixed-strings $cron_task <(crontab -l)) <(echo $cron_schedule) | crontab -; then
        print "  ...done"
    else
        print "Please add \`cd $SCRIPT_DIR && git pull\` to your crontab or just ignore this, you can always update dotfiles manually"
    fi
else
    print "  ...no systemd or cron detected, skipping"
fi
