#!/usr/bin/bash
check_ping_to_google_dns() {
    local container_name=$1
    local max_attempts=10
    local attempt=1

    # Loop until the container can ping Google DNS or max attempts are reached
    while [ $attempt -le $max_attempts ]; do
        if lxc exec "$container_name" -- ping -c 1 8.8.8.8 > /dev/null 2>&1; then
            echo "Container '$container_name' can ping Google DNS (8.8.8.8)."
            return 0  # Success
        fi

        echo "Attempt $attempt: Container '$container_name' cannot ping Google DNS (8.8.8.8). Retrying..."
        ((attempt++))
        sleep 5  # Adjust the sleep interval as needed
    done

    echo "Max attempts reached. Container '$container_name' cannot ping Google DNS (8.8.8.8)."
    return 1  # Failure
}



/usr/bin/bash snapshot.sh $1 -r $1-initial_install
check_ping_to_google_dns $1
/usr/bin/bash download_asterisk.sh -c $1 -d
/usr/bin/bash check_signatures.sh $1
/usr/bin/bash extract_asterisk.sh $1
/usr/bin/bash build.sh $1
