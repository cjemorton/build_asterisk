#!/bin/bash

download_files() {
    local container_name=$1
    local download_path="/usr/src/asterisk"
    local base_url="http://downloads.asterisk.org/pub/telephony/asterisk/"
    local version="21.1.0"

    local files=(
        "asterisk-$version.tar.gz"
        "asterisk-$version.tar.gz.asc"
        "asterisk-$version.sha256"
        "asterisk-$version.sha1"
        "asterisk-$version.md5"
        "asterisk-$version-patch.tar.gz.asc"
        "asterisk-$version-patch.tar.gz"
        "asterisk-$version-patch.sha256"
        "asterisk-$version-patch.sha1"
        "asterisk-$version-patch.md5"
    )

    # Check if /usr/src/asterisk folder exists, if not, create it
    if [ ! -d "$download_path" ]; then
        echo "Creating folder: $download_path"
        lxc exec "$container_name" -- mkdir -p "$download_path"
    fi

    # Check if curl is available in the container
    if lxc exec "$container_name" -- command -v curl &>/dev/null; then
        for file in "${files[@]}"; do
            link="$base_url$file"
            filename=$(basename "$link")
            filepath="$download_path/$filename"

            echo "Downloading $link to $filepath"
            lxc exec "$container_name" -- curl -sS "$link" -o "$filepath"

            if [ $? -eq 0 ]; then
                echo "Download successful."
            else
                echo "Failed to download $link."
                exit 1
            fi
        done
    else
        echo "curl is not installed in the container. Please install curl to download files."
    fi
}

install_required_tools() {
    local container_name=$1

    echo "Checking and installing required tools in the container..."

    # Check and install md5sum, sha1sum, sha256sum, and gpg using dnf
    lxc exec "$container_name" -- dnf -y install coreutils gpg

    echo "Required tools installed successfully."
}

create_container() {
    local container_name=$1

    if [ -z "$container_name" ]; then
        # Generate container name if not provided
        container_name="Rocky8-$(uuidgen | awk -F'-' '{print $2}')"
        echo "No container name provided. Generating container name: $container_name"
    fi

    echo "Creating new LXC container: $container_name"
    lxc launch images:rockylinux/8/amd64 "$container_name"
}

list_containers() {
    echo "Available LXC Containers:"
    lxc list --format csv -c n
}

print_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -c <container_name>    Specify the LXC container to use."
    echo "  -d                     Download files inside the specified container."
    echo "  -l                     List all available LXC containers."
    echo "  -n                     Create a new LXC container."
    echo "  -h                     Display this help message."
}

# Parse command line options
while getopts ":c:dlhn" opt; do
    case $opt in
        c)
            container_name=$OPTARG
            ;;
        d)
            download_flag=true
            ;;
        l)
            list_containers
            exit 0
            ;;
        n)
            create_flag=true
            ;;
        h)
            print_usage
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            print_usage
            exit 1
            ;;
    esac
done

# If no flags are provided, list containers and print usage
if [ "$#" -eq 0 ]; then
    list_containers
    print_usage
    exit 1
fi

# If the create flag is set, trigger the create_container function
if [ "$create_flag" = true ]; then
    create_container "$container_name"
fi

# If the download flag is set, trigger the download_files function
if [ "$download_flag" = true ]; then
    if [ -z "$container_name" ]; then
        echo "Error: Container name not provided. Use the -c flag to specify the container."
        exit 1
    fi
    download_files "$container_name"
fi

