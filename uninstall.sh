#!/bin/bash
#
# Removes the reposet scripts from the directory /usr/local/bin.
#
# author: andreasl

sudo rm -v \
    '/usr/local/bin/reposet' \
    '/usr/local/bin/reposet.inc.sh' \
    '/usr/local/bin/reposet-'*
