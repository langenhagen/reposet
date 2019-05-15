#!/bin/bash
#
# Contains common functions and variables for the reposet subcommands.
#
# author: andreasl

function cd_to_repo_or_die {
    if ! cd "$repo_path"; then
        die "Path ${rb}${repo_path}${r} does not exist." "$1"
    fi
}

function check_if_local_branch_exists_or_die {
    # Checks if the local branch exists or dies with the given exit code.
    if ! git rev-parse --verify "$local_branch" 1>/dev/null 2>&1; then
        msg="The repo ${rb}${repo_path}${r} does not contain a branch called"
        msg="${msg} ${rb}${local_branch}${r}"
        die "$msg" "$1" "cd \"${repo_path}\""
    fi
}

function checkout_local_branch_or_die {
    # Checks the local branch out or dies with the given exit code.
    if ! git checkout "$local_branch"; then
        msg="Calling \`${rb}git checkout ${local_branch}${r}\` on ${rb}${repo_path}${r} failed."
        die "$msg" "$1" "cd \"${repo_path}\""
    fi
}

function die {
    # Prints a given error message,
    # optionally writes a given command to the clipboard,
    # and exits with a given code.
    >&2 printf -- "${r}Error: ${1}${n}\n"

    if [ -n "$3" ] && command -v xclip >/dev/null && [ -n "$DISPLAY" ] ; then
        printf '%s' "$3" | xclip -i -f -selection primary | xclip -i -selection clipboard
        if [ $((PIPESTATUS[1]+PIPESTATUS[2])) -eq 0 ] ; then
            printf "Command '${3}' written to system clipboard\n"
        fi
    fi
    exit "$2"
}

function git_fetch_and_pull_or_die {
    # Checks if the current repo can be used for fetching/pulling,
    # if yes, calls git fetch
    # and git pull --rebase
    # In case of any error, dies with the exit code the git command returns.
    if [ -z "$pull_remote" ] || [ -z "$pull_branch" ] ; then
        printf -- "${b}Repo ${bb}$repo_path${b} is not set up for pulling.${n}\n"
        return
    fi

    git fetch --prune --tags "$pull_remote" "$pull_branch"
    code="$?"
    if [ "$code" != 0 ] ; then
        msg="Calling \`${rb}git fetch --prune --tags ${pull_remote} ${pull_branch}${r}\` on the"
        msg="${msg} repo ${rb}${repo_path}${r} failed:"
        if [ "$code" == 128 ] ; then
            msg="${msg} Missing access rights."
        else
            msg="${msg} Unknown error."
        fi
        die "$msg" "$code" "cd \"${repo_path}\""
    fi

    git pull --rebase "$pull_remote" "$pull_branch"
    code="$?"
    if [ "$code" != 0 ] ; then
        msg="Calling \`${rb}git pull --rebase ${pull_remote} ${pull_branch}${r}\` on the repo"
        msg="${msg} ${rb}${repo_path}${r} failed: "
        if [ "$code" == 1 ] ; then
            msg="${msg} Either did not find this remote branch or conflicting local files exist."
        elif [ "$code" == 128 ] ; then
            msg="${msg} Merge conflict."
        else
            msg="${msg} Unknown error."
        fi
        die "$msg" "$code" "cd \"${repo_path}\""
    fi
}

function git_push_or_die {
    # Checks if the current repo can be used for pushing,
    # if yes, calls git push or dies with the exit code git push returns.
    if [ -z "$push_remote" ] || [ -z "$push_branch" ] ; then
        printf -- "${b}Repo ${bb}$repo_path${b} is not set up for pushing.${n}\n"
        return
    fi

    git push "$push_remote" "$local_branch":"$push_branch"
    code="$?"
    if [ "$code" == 1 ] ; then
        return # 1 is "no new changes" on gerrit
    elif [ "$code" != 0 ] ; then
        msg="Calling \`${rb}git push ${push_remote} ${local_branch}:${push_branch}${r}\`"
        msg="${msg} on the repo ${rb}${repo_path}${r} failed:"
        if [ "$code" == 128 ] ; then
            msg="${msg} Do you have access rights?"
            error_msgs="${error_msgs}${msg}"
            >&2 printf -- "${r}$msg${n}\n"
        else
            msg="${msg} Unknown reason."
            die "$msg" "$code" "cd \"${repo_path}\""
        fi
    fi
}

function load_reposet_or_die {
    # Loads a reposet with the given name,
    # performs sanity checks
    # and appends it to tbe array _repos.
    # If no reposet is given, loads the default reposet.
    reposet_file="${HOME}/.reposets/${1}.reposet"
    if [ ! -f "$reposet_file" ] ; then
        die "Expected existing reposet file at ${rb}${reposet_file}${r} but found none." 11
    fi

    # shellcheck disable=SC1090
    source "$reposet_file"
    sanity_check_reposet_or_die
    _repos+=(${repos[@]})
    n_repos="${#_repos[@]}"
}

function load_reposets_or_die {
    # Loads the given reposets,
    # performs sanity checks
    # and adds the found repos into the array _repos.
    # If no reposet is given, loads the default reposet.
    if [ "$#" -ne 0 ] ; then
        for reposet in "$@" ; do
            load_reposet_or_die "$reposet"
        done
    else
        load_reposet_or_die
    fi
}

n_current_repo=0  # the current repository index
function n_current_repo++ {
    # Adds 1 to the common variable n_current_repo.
    ((n_current_repo += 1))
}

function print_all_repos_status_or_die {
    # Changes directory to each repo, or dies with the given exit code,
    # and calls git status.
    printf "Checking status for all repos:\n"
    n_current_repo=0
    for repo in "${_repos[@]}"; do
        set_common_repo_variables "$repo"
        printf "${bold}${repo_path}${n}\n"
        cd_to_repo_or_die "$1"
        git status --short --untracked-files
    done
}

function print_common_repo_variables {
    printf 'n_repos=%s\n' "$n_repos"
    printf 'n_current_repo=%s\n' "$n_current_repo"
    printf 'repo_path=%s\n' "$repo_path"
    printf 'local_branch=%s\n' "$local_branch"
    printf 'pull_remote=%s\n' "$pull_remote"
    printf 'pull_branch=%s\n' "$pull_branch"
    printf 'push_remote=%s\n' "$push_remote"
    printf 'push_branch=%s\n' "$push_branch"
}

function print_current_repo_and_progress {
    printf "${bold}(${n_current_repo}/${n_repos}) ${repo_path}${n}...\n"
}

function sanity_check_reposet_or_die {
    # Checks if the reposet array 'repos' has the correct form.

    # check reposet is not empty
    if [ ${#repos[@]} -eq 0 ] ; then
        msg="Error in ${BASH_SOURCE[0]} sourced by ${0}: Reposet array \"\$repos\" in file:"
        msg="${msg} \"${rb}${reposet_file}${r}\" seems to be empty."
        die "$msg" 12
    fi

    # check each reposet entry has correct size
    wrong_lines="$(printf '%s\n' "${repos[@]}" | grep -Ensv '^([^:]+:){2}([^:]*:){3}[^:]*$')"
    if [ -n "$wrong_lines" ] ; then
        msg="Errors in ${BASH_SOURCE[0]} sourced by ${0}: Reposet array \"\$repos\" in file:"
        msg="${msg} \"${rb}${reposet_file}${r}\" contains broken lines:\n"
        msg="${msg}${wrong_lines}\n\n"
        msg="${msg}A repository definition must contain 6 fields, each delimited by ':' in the"
        msg="${msg} form:\n"
        msg="${msg}<path>:<local branch>:[<remote pull repo>]:[<remote pull branch>]:"
        msg="${msg}[<remote push repo>]:[<remote push branch>]\n"
        die "$msg" 13
    fi
}

function set_common_repo_variables {
    # Sets common variables that relate to the given repo line.
    n_repos="${#_repos[@]}"
    repo_path="$(local_path "$1")"
    local_branch="$(local_branch "$1")"
    pull_remote="$(remote_pull_repo "$1")"
    pull_branch="$(remote_pull_branch "$1")"
    push_remote="$(remote_push_repo "$1")"
    push_branch="$(remote_push_branch "$1")"
}

function get_element {
    # Retrieves the n-th ':' delimited element from the given string.
    # Usage get_element <line> <column>
    IFS=':' read -r -a line_array <<< "$1"
    printf -- "${line_array[${2}]}\n"
}
function local_path {
    get_element "$1" 0
}
function local_branch {
    get_element "$1" 1
}
function remote_pull_repo {
    get_element "$1" 2
}
function remote_pull_branch {
    get_element "$1" 3
}
function remote_push_repo {
    get_element "$1" 4
}
function remote_push_branch {
    get_element "$1" 5
}

# color codes
# if you want to change them, redefine them with empty string '' or disable them by not calling
# tbe function.
# shellcheck disable=SC2034
function define_color_codes {
    r='\e[0;31m'
    g='\e[0;32m'
    b='\e[0;34m'
    bold='\e[1m'
    rb='\e[1;31m'
    gb='\e[1;32m'
    bb='\e[1;34m'
    n='\e[0m'
}
define_color_codes
