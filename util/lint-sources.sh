#!/bin/bash
# Run the linter shellcheck with the project's preferences.
# Run it from the project's root directory in order to make shellcheck follow source statements.
#
# author: andreasl

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${script_dir}/../src" || exit 1

# ignore the following error codes:
# SC2059: Don't use variables in the printf format string. Use printf "..%s.." "$foo".
# SC2181: Check exit code directly with e.g. 'if mycmd;', not indirectly with $?.
# shellcheck disable=SC2035
shellcheck -x --exclude SC2059,SC2181 *
