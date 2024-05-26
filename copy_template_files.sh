#!/bin/bash

set -e

main()
{
    local -r THIS_SCRIPT_PATH="$(tmp_find_script_path)"
    local -r THIS_REPO_PATH="$THIS_SCRIPT_PATH"
    local -r DEST_PATH="$1"

    local tmp_file_info_submodules="$(mktemp)"

    # Add files or directories to ignore here
    local ignore_files=(
        "$THIS_REPO_PATH/copy_template_files.sh"
        "$THIS_REPO_PATH/.git"
        "$THIS_REPO_PATH/.gitmodules"
        "$THIS_REPO_PATH/lib/lib_sources"
    )

    if [[ -z "$DEST_PATH" || ! -d "$DEST_PATH" ]]
    then
        echo "Usage: $0 <destination_path>"
        exit 1
    fi

    get_source_repo_submodule_info "$tmp_file_info_submodules"

    copy_git_submodules

    copy_files

    rm "$tmp_file_info_submodules"
}

get_source_repo_submodule_info()
{
    local file="$1"

    pushd "$THIS_REPO_PATH" >/dev/null

    git submodule update --init --recursive >/dev/null
    git submodule status --recursive >"$file"

    popd >/dev/null
}

copy_git_submodules()
{
    pushd "$DEST_PATH" >/dev/null

    local commit
    local path
    local url

    while read -r line
    do
        # Extract submodule commit, path, and URL
        submodule_commit="$(echo "$line" | awk '{print $1}')"
        submodule_rel_path="$(echo "$line" | awk '{print $2}')"
        url="$(git -C "$THIS_REPO_PATH" config -f .gitmodules --get "submodule.${submodule_rel_path}.url")"

        # Add the submodule
        git submodule add "$url" "$submodule_rel_path" >/dev/null 2>&1

        # Checkout the specific commit
        pushd "$submodule_rel_path" >/dev/null
        git checkout "$submodule_commit" >/dev/null 2>&1
        popd >/dev/null

    done < "$tmp_file_info_submodules"

    popd >/dev/null
}

copy_files()
{
    # Create rsync exclude parameters from ignore_files array
    local rsync_exclude=""
    for file in "${ignore_files[@]}"
    do
        rsync_exclude+="--exclude=$(basename "$file") "
    done

    # Perform the copy using rsync
    eval rsync -av $rsync_exclude "$THIS_REPO_PATH/" "$DEST_PATH" >/dev/null
}

tmp_find_script_path() {
    unset -f tmp_find_script_path; local s="${BASH_SOURCE[0]}"; local d
    while [[ -L "$s" ]]; do d=$(cd -P "$(dirname "$s")" &>/dev/null && pwd); s=$(readlink "$s"); [[ $s != /* ]] && s=$d/$s; done
    echo "$(cd -P "$(dirname "$s")" &>/dev/null && pwd)"
}

### Call main() ###
main "$@"
###################
