#!/bin/bash
check_for_patches() {
    local container_name=$1
    local directory="/usr/src/asterisk/"

    if [ -z "$container_name" ]; then
        echo "Please provide a container name as the first argument."
        return 1
    fi

    # Check if the specified container exists
    if ! lxc info "$container_name" > /dev/null 2>&1; then
        echo "Container '$container_name' does not exist."
        return 1
    fi

    # Check if the specified directory exists in the container
    if ! lxc exec "$container_name" -- test -d "$directory"; then
        echo "Directory '$directory' does not exist in the container '$container_name'."
        return 1
    fi

    if ! lxc exec "$container_name" -- command -v patch > /dev/null 2>&1; then
        echo "Patch command not found in container '$container_name'. Installing..."
        lxc exec "$container_name" -- dnf -y install patch
    fi

    # Check if there are any files with a .patch extension in the directory and get asterisk version number.
    local patch_files=$(lxc exec "$container_name" -- sh -c "ls $directory/*-patch" 2>/dev/null)
    local asterisk_version=$(lxc exec "$container_name" -- sh -c "ls $directory | grep -E '^asterisk-[0-9]+\.[0-9]+\.[0-9]+$' | awk '{print}'")

    if [ -n "$patch_files" ]; then
        echo "Patch files found in '$directory' of container '$container_name':"
        echo "$patch_files"

        lxc exec "$container_name" -- sh -c "cd $directory/$asterisk_version && patch --strip=1 < $patch_files"

    else
        echo "No patch files found in '$directory' of container '$container_name'."
    fi
}




#######################################################################################

if [ -z "${1-}" ]; then
    echo "Missing Container."
    lxc ls
else
    echo "Using Container: $1"
    container_name=$1
#    check_for_patches "$container_name"
#    extract_asterisk "$container_name"
    echo "Patches only apply to older versions...  This is not implemented yet."

fi

