#!/bin/bash
# Contains common functions and variables for the reposet subcommands.
#
# author: andreasl

reposets_dir="${HOME}/.config/reposets"
n_current_repo=0  # the current repository index
push_tags=false
use_force=false


function die {
    # Print a given error message,
    # optionally write a given command to the clipboard,
    # and exit with a given code.
    >&2 printf -- "${r}Error: ${1}${n}\n"

    if [ -n "$3" ] && command -v xclip >/dev/null && [ -n "$DISPLAY" ]; then
        printf '%s' "$3" | xclip -i -f -selection primary | xclip -i -selection clipboard
        if [ $((PIPESTATUS[1]+PIPESTATUS[2])) -eq 0 ]; then
            printf "Command '${3}' written to system clipboard\n"
        fi
    fi
    exit "$2"
}

function cd_to_repo_or_die {
    # cd into a repository ir die.
    if ! cd "$repo_path"; then
        die "Path ${rb}${repo_path}${r} does not exist." "$1"
    fi
}

function check_if_local_branch_exists_or_die {
    # Check if the local branch exists or die with the given exit code.
    if ! git rev-parse --verify "$local_branch" 1>/dev/null 2>&1; then
        msg="The repo ${rb}${repo_path}${r} does not contain a branch called"
        msg+=" ${rb}${local_branch}${r}"
        die "$msg" "$1" "cd \"${repo_path}\""
    fi
}

function checkout_local_branch_or_die {
    # Check out the local branch or die with the given exit code.
    if ! git checkout "$local_branch"; then
        msg="Calling \`${rb}git checkout ${local_branch}${r}\` on ${rb}${repo_path}${r} failed."
        die "$msg" "$1" "cd \"${repo_path}\""
    fi
}

function git_fetch_and_pull_or_die {
    # Check if the current repo can be used for fetching/pulling,
    # if yes, call git fetch,
    # and git pull --rebase
    # If $use_force is set to 'true', call git clean -dfx and git reset --hard HEAD
    # prior to pulling.
    # In case of any error, die with the exit code the git command returns.
    if [ -z "$pull_remote" ] || [ -z "$pull_branch" ]; then
        printf -- "${b}Repo ${bb}$repo_path${b} is not set up for pulling.${n}\n"
        return
    fi

    git fetch --prune --tags "$pull_remote" "$pull_branch"
    code="$?"
    if [ "$code" -ne 0 ]; then
        msg="Calling \`${rb}git fetch --prune --tags ${pull_remote} ${pull_branch}${r}\` on the"
        msg+=" repo ${rb}${repo_path}${r} failed:"
        if [ "$code" -eq 128 ]; then
            msg+=" Missing access rights."
        else
            msg+=" Unknown error."
        fi
        die "$msg" "$code" "cd \"${repo_path}\""
    fi

    if [ "$use_force" == true ]; then
        git clean -dfx
        git reset --hard HEAD
    fi

    git pull --rebase "$pull_remote" "$pull_branch"
    code="$?"
    if [ "$code" -ne 0 ]; then
        msg="Calling \`${rb}git pull --rebase ${pull_remote} ${pull_branch}${r}\` on the repo"
        msg+=" ${rb}${repo_path}${r} failed: "
        if [ "$code" -eq 1 ]; then
            msg+=" Either did not find this remote branch or conflicting local files exist."
        elif [ "$code" -eq 128 ]; then
            msg+=" Merge conflict."
        else
            msg+=" Unknown error."
        fi
        die "$msg" "$code" "cd \"${repo_path}\""
    fi
}

function git_push_or_die {
    # Check if the current repo can be used for pushing,
    # if yes, call git push or die with the exit code git push returns.
    if [ -z "$push_remote" ] || [ -z "$push_branch" ]; then
        printf -- "${b}Repo ${bb}$repo_path${b} is not set up for pushing.${n}\n"
        return
    fi

    if [ "$push_tags" == true ]; then
        git push --tags "$push_remote" "$local_branch":"$push_branch"
    else
        git push "$push_remote" "$local_branch":"$push_branch"
    fi
    code="$?"
    if [ "$code" -eq 1 ]; then
        # possibly rejected from server/gerrit side
        msg="Calling \`${yb}git push ${push_remote} ${local_branch}:${push_branch}${y}\`"
        msg+=" on the repo ${yb}${repo_path}${y} failed with exit code 1."
        >&2 printf -- "${y}$msg${n}\n"
    elif [ "$code" -ne 0 ]; then
        msg="Calling \`${rb}git push ${push_remote} ${local_branch}:${push_branch}${r}\`"
        msg+=" on the repo ${rb}${repo_path}${r} failed:"
        if [ "$code" -eq 128 ]; then
            msg+=" Do you have access rights?"
            error_msgs="${error_msgs}${msg}"
            >&2 printf -- "${r}$msg${n}\n"
        else
            msg+=" Unknown reason."
            die "$msg" "$code" "cd \"${repo_path}\""
        fi
    fi
}

function load_reposet_or_die {
    # Load a reposet with the given name,
    # perform sanity checks
    # and append it to tbe array _repos.
    # If no reposet is given, load the default reposet.
    reposet_file="${reposets_dir}/${1}.reposet"
    if [ ! -f "$reposet_file" ]; then
        die "Expected existing reposet file at ${rb}${reposet_file}${r} but found none." 11
    fi

    # shellcheck disable=SC1090
    source "$reposet_file"
    sanity_check_reposet_or_die
    _repos+=(${repos[@]})
    n_repos="${#_repos[@]}"
}

function load_reposets_or_die {
    # Load the given reposets,
    # perform sanity checks
    # and add the found repos into the array _repos.
    # If no reposet is given, load the default reposet.
    if [ "$#" -ne 0 ]; then
        for reposet in "$@"; do
            load_reposet_or_die "$reposet"
        done
    else
        load_reposet_or_die
    fi
}

function n_current_repo++ {
    # Add 1 to the common variable n_current_repo.
    ((n_current_repo += 1))
}

function print_all_repos_status_or_die {
    # Change directory to each repo, or die with the given exit code,
    # and call git status.
    max_path_length=0
    for repo in "${_repos[@]}"; do
        set_common_repo_variables "$repo"
        n_current_repo++
        [ ${#repo_path} -gt "$max_path_length" ] && max_path_length=${#repo_path}
    done

    n_current_repo=0
    for repo in "${_repos[@]}"; do
        set_common_repo_variables "$repo"
        n_current_repo++
        cd_to_repo_or_die 1

        printf "%s" "$PWD"; printf "%0.s~" $(seq ${#PWD} "${max_path_length}");
        git status --branch --short --untracked-files
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
    # Check if the reposet array 'repos' has the correct form.

    # check reposet is not empty
    if [ ${#repos[@]} -eq 0 ]; then
        msg="Error in ${BASH_SOURCE[0]} sourced by ${0}: Reposet array \"\$repos\" in file:"
        msg+=" \"${rb}${reposet_file}${r}\" seems to be empty."
        die "$msg" 12
    fi

    # check each reposet entry has correct size
    wrong_lines="$(printf '%s\n' "${repos[@]}" | grep -Ensv '^([^:]+:){2}([^:]*:){3}[^:]*$')"
    if [ -n "$wrong_lines" ]; then
        msg="Errors in ${BASH_SOURCE[0]} sourced by ${0}: Reposet array \"\$repos\" in file:"
        msg+=" \"${rb}${reposet_file}${r}\" contains broken lines:\n"
        msg+="${wrong_lines}\n\n"
        msg+="A repository definition must contain 6 fields, each delimited by ':' in the form:\n"
        msg+="<path>:<local branch>:[<remote pull repo>]:[<remote pull branch>]:"
        msg+="[<remote push repo>]:[<remote push branch>]\n"
        die "$msg" 13
    fi
}

function set_common_repo_variables {
    # Set common variables that relate to the given repo line.
    n_repos="${#_repos[@]}"
    repo_path="$(local_path "$1")"
    local_branch="$(local_branch "$1")"
    pull_remote="$(remote_pull_repo "$1")"
    pull_branch="$(remote_pull_branch "$1")"
    push_remote="$(remote_push_repo "$1")"
    push_branch="$(remote_push_branch "$1")"
}

function get_element {
    # Retrieve the n-th ':' delimited element from the given string.
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
# If you want to change them, redefine them. Disable them altogether by not calling the function.
# shellcheck disable=SC2034
function define_color_codes {
    r='\e[0;31m'
    g='\e[0;32m'
    y='\e[0;33m'
    b='\e[0;34m'
    bold='\e[1m'
    rb='\e[1;31m'
    gb='\e[1;32m'
    yb='\e[1;33m'
    bb='\e[1;34m'
    n='\e[0m'
}
define_color_codes
