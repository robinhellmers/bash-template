#!/usr/bin/env bash

sourceable_script='false'

if [[ "$sourceable_script" != 'true' && ! "${BASH_SOURCE[0]}" -ef "$0" ]]
then
    echo "Do not source this script! Execute it with bash instead."
    return 1
fi
unset sourceable_script

########################
### Library sourcing ###
########################

library_sourcing()
{
    # Unset as only called once and most likely overwritten when sourcing libs
    unset -f library_sourcing

    local -r THIS_SCRIPT_PATH="$(tmp_find_script_path)"

    # Store $THIS_SCRIPT_PATH as unique or local variables
    # LIB_PATH is needed by sourced libraries as well
    readonly PROJECT_BASE_PATH="$THIS_SCRIPT_PATH"
    export PROJECT_BASE_PATH
    readonly LIB_PATH="$THIS_SCRIPT_PATH/lib"
    export LIB_PATH

    ### Source libraries ###
    source "$LIB_PATH/lib_core.bash"
    source "$LIB_PATH/lib.bash"
}

# Minimal version of find_path(). Should only be used within this script to source library defining find_path().
tmp_find_script_path() {
    unset -f tmp_find_script_path; local s="${BASH_SOURCE[0]}"; local d
    while [ -L "$s" ]; do d=$(cd -P "$(dirname "$s")" &>/dev/null && pwd); s=$(readlink "$s"); [[ $s != /* ]] && s=$d/$s; done
    echo "$(cd -P "$(dirname "$s")" &>/dev/null && pwd)"
}

library_sourcing

############
### MAIN ###
############

main()
{
    local this_file="$(find_path 'this_file' "${#BASH_SOURCE[@]}" "${BASH_SOURCE[@]}")"
    echo -e "\nthis_file: $this_file\n"

    func_lib 123

    # Expected invalid usage error
    func_lib abc
}

###################
### END OF MAIN ###
###################

main_stderr_red()
{
    main "$@" 2> >(sed $'s|.*|\e[31m&\e[m|' >&2)
}

#################
### Call main ###
#################
main_stderr_red "$@"
#################
