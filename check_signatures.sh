#!/bin/bash

check_sha256() {
    local container_name=$1
    local folder_path='/usr/src/asterisk/'

    if lxc exec "$container_name" -- test ! -d "$folder_path"; then
        echo "Folder: $folder_path is missing"
        lxc exec "$container_name" -- mkdir "$folder_path"
        exit 1
    fi

    extension=".sha256"

    if lxc exec "$container_name" -- find "$folder_path" -type f -name "*$extension" -exec test ! -e {} \; -print -quit | grep -q .; then
        echo "Files with extension $extension are missing in folder: $folder_path"
        exit 1
    fi

    lxc exec "$container_name" -- /bin/bash -c "cd $folder_path && sha256sum -c *$extension"
}
check_asc() {
    local container_name=$1
    local folder_path='/usr/src/asterisk'
    local key_id='F2FC93DB7587BD1FB49E045A5D984BE337191CE7'
    extension=".asc"

    if lxc exec "$container_name" -- test ! -d "$folder_path"; then
        echo "Folder: $folder_path is missing"
        lxc exec "$container_name" -- mkdir "$folder_path"
        exit 1
    fi

    if lxc exec "$container_name" -- find "$folder_path" -type f -name "*$extension" -exec test ! -e {} \; -print -quit | grep -q .; then
        echo "Files with extension $extension are missing in folder: $folder_path"
        exit 1
    fi

    # Get Signatures and trust them.
    lxc exec "$container_name" -- /bin/bash -c "gpg --keyserver keys.openpgp.org --recv-keys $key_id"
    lxc exec "$container_name" -- /bin/bash -c "echo -e 'trust\n5\ny\n' | gpg --command-fd 0 --edit-key $key_id"

    # Iterate over all .asc files in the directory inside the container
    lxc exec "$container_name" -- /bin/bash -c "for asc_file in $folder_path/*.asc; do
        if [ -e \"\$asc_file\" ]; then
            echo \"Processing \$asc_file\"
            version=\$(echo \"\$asc_file\" | sed -n 's/.*\/asterisk-\(.*\)\.tar\.gz\.asc/\1/p')
            folder_path=\$(dirname \"\$asc_file\")
            gpg --verify \"\$asc_file\" \$folder_path\/\asterisk-\$version.tar.gz
        fi
    done"
}

#######################################################################################

if [ -z "${1-}" ]; then
    echo "Missing Container."
    lxc ls
else
    echo "Using Container: $1"
    container_name=$1
    check_sha256 "$container_name"
    check_asc "$container_name"
fi

