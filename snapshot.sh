#!/bin/bash

show_help() {
    echo "Usage: $0 <container_name> [-s | -r <snapshot_name> | -l]"
    echo "Options:"
    echo "  -s              Create a new snapshot for the specified container."
    echo "  -r <snapshot>   Rollback to the specified snapshot for the container."
    echo "  -l              List all snapshots for the specified container."
    echo "  -d <snapshot>   Delete the specified snapshot for the container."
}

list_snapshots() {
    local container_name=$1

    # Check if the specified container exists
    if ! lxc list --format csv -c n | grep -q "^$container_name$"; then
        echo "Container $container_name does not exist."
        exit 1
    fi

    # List all snapshots for the container
    lxc info "$container_name" | grep -A 999999 Snapshots
}

create_snapshot() {
    local container_name=$1

    # Check if the specified container exists
    if ! lxc list --format csv -c n | grep -q "^$container_name$"; then
        echo "Container $container_name does not exist."
        exit 1
    fi

    # Create a new snapshot with a custom name
    local snapshot_name="$container_name-$(uuidgen | awk -F- '{print $2}')-$(date +%Y%m%d)"
    lxc snapshot "$container_name" "$snapshot_name"

    echo "Snapshot $snapshot_name created for container $container_name."
}

rollback_snapshot() {
    local container_name=$1
    local snapshot_name=$2

    # Check if the specified container exists
    if ! lxc info "$container_name" &>/dev/null; then
        echo "Container $container_name does not exist."
        exit 1
    fi

    # Check if the specified snapshot exists
    if lxc info "$container_name" | grep -q "$snapshot_name"; then
        # Rollback to the specified snapshot
        lxc restore "$container_name" "$snapshot_name"
        echo "Container $container_name rolled back to snapshot $snapshot_name."
    else
        echo "Snapshot $snapshot_name does not exist for container $container_name."
        exit 1
    fi
}

delete_snapshot() {
    local container_name=$1
    local snapshot_name=$2

    # Check if the specified container exists
    if ! lxc info "$container_name" &>/dev/null; then
        echo "Container $container_name does not exist."
        exit 1
    fi

    # Check if the specified snapshot exists
    if lxc info "$container_name" | grep -q "$snapshot_name"; then
        # Delete the specified snapshot
        lxc delete "$container_name/$snapshot_name"
        echo "Snapshot $snapshot_name deleted for container $container_name."
    else
        echo "Snapshot $snapshot_name does not exist for container $container_name."
        exit 1
    fi
}



#######################################################################################

if [ -z "${1-}" ]; then
    show_help
    exit 1
else
    echo "Using Container: $1"
    container_name=$1

    # Check for the second flag
    case "${2-}" in
        -s)
            create_snapshot "$container_name"
            ;;
        -r)
            if [ -z "${3-}" ]; then
                echo "Missing snapshot name for rollback."
                exit 1
            fi
            rollback_snapshot "$container_name" "$3"
            ;;
        -l)
            list_snapshots "$container_name"
            ;;
        -d)
            if [ -z "${3-}" ]; then
                echo "Missing snapshot name for rollback."
                exit 1
            fi
            delete_snapshot "$container_name" "$3"
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
fi

