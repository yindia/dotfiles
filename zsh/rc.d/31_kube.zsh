# kuv — pick a kubeconfig, then a context, then a namespace, each through fzf.
#
# fzf always draws the lists; kubectx/kubens are used only to apply a choice,
# and kubectl covers the same ground when they are absent. Keeping selection
# and application separate means the interface is identical either way, rather
# than shifting depending on what happens to be installed.

if (( ${+commands[kubectl]} )); then
    kuv() {
        emulate -L zsh

        (( ${+commands[fzf]} )) || {
            print -u2 "kuv: fzf is required"
            return 1
        }

        local kube_dir=${KUV_KUBECONFIG_DIR:-$HOME/.kube}
        [[ -d $kube_dir ]] || {
            print -u2 "kuv: no such directory: $kube_dir"
            return 1
        }

        # Top-level regular files only. ~/.kube also carries cache/ and
        # .colima/, holding an HTTP cache and timestamped backups — neither is
        # something you would ever want to switch to.
        local -a configs=()
        local f
        for f in $kube_dir/*(.N); do
            # Every kubeconfig has a clusters list. Checking for it filters out
            # lock files, notes and whatever else collects in this directory,
            # without hardcoding a naming convention.
            command grep -qE '^clusters:' $f 2>/dev/null && configs+=($f)
        done

        (( $#configs )) || {
            print -u2 "kuv: no kubeconfig found in $kube_dir"
            return 1
        }

        # --select-1 skips the prompt when there is only one candidate, --exit-0
        # when there are none. Both keep the flow from stalling on a list that
        # offers no actual choice.
        local config
        config=$(print -l -- $configs | fzf \
            --select-1 --exit-0 \
            --prompt='kubeconfig> ' \
            --preview='kubectl config get-contexts --kubeconfig {} 2>/dev/null || cat {}' \
            --preview-window='right,60%') || return 1
        [[ -n $config ]] || return 1

        # Exported before the context step because everything below, including
        # kubectx and kubens, reads it. Cancelling later therefore leaves this
        # kubeconfig selected while context and namespace stay untouched.
        export KUBECONFIG=$config

        local context
        context=$(kubectl config get-contexts -o name | fzf \
            --select-1 --exit-0 \
            --prompt='context> ') || return 1
        [[ -n $context ]] || return 1

        # Both tools announce the switch on stderr, which would duplicate the
        # summary printed at the end. Capture it instead of discarding it, so a
        # genuine failure still has something to report.
        local err
        if (( ${+commands[kubectx]} )); then
            err=$(kubectx $context 2>&1 > /dev/null)
        else
            err=$(kubectl config use-context $context 2>&1 > /dev/null)
        fi || {
            print -u2 "kuv: ${err:-could not switch to context '$context'}"
            return 1
        }

        # Namespaces, unlike contexts, are not in the file — they have to come
        # from the cluster. Three separate guards, because each failure mode
        # looks different:
        #   --request-timeout  an unreachable cluster returns instead of hanging
        #   < /dev/null        a context missing credentials makes kubectl
        #                      prompt for a username on *stdout*, which would
        #                      otherwise block the shell and be captured as if
        #                      it were a namespace
        #   status + filter    anything that still reaches stdout is discarded
        #                      unless it has the shape kubectl actually emits
        local ns_output
        local -a namespaces=()
        if ns_output=$(kubectl get namespaces -o name --request-timeout=5s 2>/dev/null < /dev/null); then
            namespaces=(${(f)ns_output})
            namespaces=(${(M)namespaces:#namespace/*})
            namespaces=(${namespaces#namespace/})
        fi

        if (( ! $#namespaces )); then
            print -u2 "kuv: cannot reach '$context' to list namespaces; context set, namespace left alone"
            print "kuv: ${config/#$HOME/~} · $context"
            return 0
        fi

        local namespace
        namespace=$(print -l -- $namespaces | fzf \
            --select-1 --exit-0 \
            --prompt='namespace> ') || return 0
        [[ -n $namespace ]] || return 0

        if (( ${+commands[kubens]} )); then
            err=$(kubens $namespace 2>&1 > /dev/null)
        else
            err=$(kubectl config set-context --current --namespace=$namespace 2>&1 > /dev/null)
        fi || {
            print -u2 "kuv: ${err:-could not switch to namespace '$namespace'}"
            return 1
        }

        print "kuv: ${config/#$HOME/~} · $context · $namespace"
    }
fi
