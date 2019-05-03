#!/bin/bash
#
# Makes the script reposet executable and
# copies the scripts into the directory /usr/local/bin.
#
# author: andreasl

setup_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "${setup_script_dir}/src/reposet"
sudo cp "${setup_script_dir}/src/"* '/usr/local/bin'