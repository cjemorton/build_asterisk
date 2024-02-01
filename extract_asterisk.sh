#!/bin/bash

check_tar() {
    local container_name=$1

    # Check if the 'tar' program is available
    if ! lxc exec "$container_name" -- command -v tar >/dev/null 2>&1; then
        echo "tar is not installed. Installing..."
        lxc exec "$container_name" -- dnf -y install tar
    fi
}

extract_asterisk() {
    local container_name=$1
    local folder_path='/usr/src/asterisk/'
    local extension=".tar.gz"

    check_tar "$container_name"

    # Check if the specified folder exists
    if ! lxc exec "$container_name" -- test -d "$folder_path"; then
        echo "Folder: $folder_path does not exist."
        exit 1
    fi

    # Print the contents of the specified folder for debugging
    echo "Contents of $folder_path:"
    lxc exec "$container_name" -- /bin/bash -c "ls -l $folder_path"

    # Extract all .tar.gz files in the specified folder
    lxc exec "$container_name" -- /bin/bash -c "cd $folder_path && for file in *$extension; do tar -zxvf \$file; done"

    # List the extracted files for debugging
    echo "Contents of $folder_path after extraction:"
    lxc exec "$container_name" -- /bin/bash -c "ls -l $folder_path"
}

#######################################################################################

if [ -z "${1-}" ]; then
    echo "Missing Container."
    lxc ls
else
    echo "Using Container: $1"
    container_name=$1
    extract_asterisk "$container_name"
fi

