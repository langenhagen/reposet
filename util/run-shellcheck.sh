#!/bin/bash
#
# Runs the shellcheck linter with the project's preferences.
# Run it from the project's root directory in order to make shellcheck follow source statements.
#
# author: andreasl

# ignore
# SC2059: Don't use variables in the printf format string. Use printf "..%s.." "$foo".
# SC2181: Check exit code directly with e.g. 'if mycmd;', not indirectly with $?.
shellcheck -x --exclude SC2059,SC2181 src/*
