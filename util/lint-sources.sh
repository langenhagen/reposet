#!/bin/bash
# Runs the linter shellcheck with the project's preferences.
# Run it from the project's root directory in order to make shellcheck follow source statements.
#
# author: andreasl

cd src || exit 1
# ignore the error codes SC2059 and SC2181
# SC2059: Don't use variables in the printf format string. Use printf "..%s.." "$foo".
# SC2181: Check exit code directly with e.g. 'if mycmd;', not indirectly with $?.
shellcheck -x --exclude SC2059,SC2181 *
