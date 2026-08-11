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

        # Deliberately no --select-1 here or below. Auto-picking a sole
        # candidate skips the step entirely, so with one kubeconfig the
        # function would open straight into the context list and look like it
        # had ignored the first stage. All three prompts always appear.
        local config
        config=$(print -l -- $configs | fzf \
            --exit-0 \
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
            --exit-0 \
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
            --exit-0 \
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

    # logs — tail pod logs through stern, choosing namespace, then pods, then
    # containers. Every list carries an explicit "[all …]" row, so walking the
    # prompts to the end is itself the way to reach "everything" rather than
    # something you have to know to skip.
    #
    # Pods and containers accept multiple selections with Tab; stern takes
    # regexes, so a selection becomes an anchored alternation. Anything passed
    # to logs is forwarded verbatim, which is how you reach --since, --timestamps
    # and the rest of stern's flags.
    logs() {
        emulate -L zsh

        (( ${+commands[stern]} )) || {
            print -u2 "logs: stern is required — brew install stern"
            return 1
        }
        (( ${+commands[fzf]} )) || {
            print -u2 "logs: fzf is required"
            return 1
        }

        # Brackets cannot appear in a Kubernetes object name (they are DNS-1123
        # labels), so these sentinels can never collide with a real one.
        local ALL_NS='[all namespaces]'
        local ALL_PODS='[all pods]'
        local ALL_CONTAINERS='[all containers]'

        local -a fzf_multi=(--multi --bind='ctrl-a:select-all,ctrl-d:deselect-all')

        # --- namespace ------------------------------------------------------
        local -a ns_list=()
        local out
        if out=$(kubectl get namespaces -o name --request-timeout=10s 2>/dev/null < /dev/null); then
            ns_list=(${(f)out})
            ns_list=(${(M)ns_list:#namespace/*})
            ns_list=(${ns_list#namespace/})
        fi
        (( $#ns_list )) || {
            print -u2 "logs: cannot reach the cluster to list namespaces — check the current context with kuv"
            return 1
        }

        local namespace
        namespace=$(print -l -- $ALL_NS $ns_list | fzf --prompt='namespace> ') || return 1
        [[ -n $namespace ]] || return 1

        local -a scope
        if [[ $namespace == $ALL_NS ]]; then
            scope=(--all-namespaces)
        else
            scope=(--namespace $namespace)
        fi

        # --- pods -----------------------------------------------------------
        # Namespace-qualified across the whole cluster, bare within one, so the
        # list stays unambiguous without being needlessly noisy.
        local pod_path
        if [[ $namespace == $ALL_NS ]]; then
            pod_path='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}'
        else
            pod_path='{range .items[*]}{.metadata.name}{"\n"}{end}'
        fi

        local -a pod_list=()
        if out=$(kubectl get pods $scope -o jsonpath=$pod_path --request-timeout=10s 2>/dev/null < /dev/null); then
            pod_list=(${(f)out})
            pod_list=(${pod_list:#})
        fi
        (( $#pod_list )) || {
            print -u2 "logs: no pods found in ${namespace}"
            return 1
        }

        local -a picked_pods
        picked_pods=(${(f)"$(print -l -- $ALL_PODS $pod_list | fzf $fzf_multi --prompt='pod> ')"}) || return 1
        (( $#picked_pods )) || return 1

        # --- containers -----------------------------------------------------
        # Scoped to the chosen pods so the list cannot offer a container that
        # produces no output. With [all pods] there is nothing to narrow by, so
        # the query covers everything in scope instead.
        local -a container_list=()
        local container_path='{range .spec.containers[*]}{.name}{"\n"}{end}{range .spec.initContainers[*]}{.name}{"\n"}{end}'
        if (( $picked_pods[(Ie)$ALL_PODS] )); then
            if out=$(kubectl get pods $scope --request-timeout=10s < /dev/null 2>/dev/null \
                -o "jsonpath={range .items[*]}$container_path{end}"); then
                container_list=(${(f)out})
            fi
        else
            local p pod_ns pod_name
            for p in $picked_pods; do
                pod_ns=$namespace
                pod_name=$p
                # Only the all-namespaces listing is qualified; split it back apart.
                if [[ $p == */* ]]; then
                    pod_ns=${p%%/*}
                    pod_name=${p##*/}
                fi
                if out=$(kubectl get pod $pod_name --namespace $pod_ns --request-timeout=10s \
                    -o "jsonpath=$container_path" < /dev/null 2>/dev/null); then
                    container_list+=(${(f)out})
                fi
            done
        fi
        container_list=(${container_list:#})
        container_list=(${(u)container_list})

        local -a picked_containers=($ALL_CONTAINERS)
        if (( $#container_list )); then
            picked_containers=(${(f)"$(print -l -- $ALL_CONTAINERS $container_list | fzf $fzf_multi --prompt='container> ')"}) || return 1
            (( $#picked_containers )) || return 1
        fi

        # --- build the stern invocation --------------------------------------
        # Dots are legal in pod names and mean "any character" in a regex, so
        # they have to be escaped before the names become one.
        local query='.'
        if ! (( $picked_pods[(Ie)$ALL_PODS] )); then
            local -a names=(${picked_pods##*/})
            names=(${names//./\\\\.})
            query="^(${(j:|:)names})\$"
        fi

        local -a container_flag=()
        if ! (( $picked_containers[(Ie)$ALL_CONTAINERS] )); then
            local -a cnames=(${picked_containers//./\\\\.})
            container_flag=(--container "^(${(j:|:)cnames})\$")
        fi

        # Echoed to stderr so it stays out of the log stream being piped or
        # redirected, while still showing what actually ran.
        print -u2 "logs: stern ${(j: :)${(q-)scope}} ${(q-)query} ${(j: :)${(q-)container_flag}} $*"
        stern $scope $container_flag $query "$@"
    }
fi
