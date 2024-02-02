#!/bin/bash
run_make() {
    local container_name=$1
    local directory='/usr/src/asterisk'
    local asterisk_version=$(lxc exec "$container_name" -- sh -c "ls $directory | grep -E '^asterisk-[0-9]+\.[0-9]+\.[0-9]+$' | awk '{print}'")

    lxc exec "$container_name" -- sh -c "cd $directory/$asterisk_version && sh contrib/scripts/get_mp3_source.sh"
    lxc exec "$container_name" -- sh -c "cd $directory/$asterisk_version && make clean && make && make install"
}

configure_asterisk() {
    local container_name=$1
    local directory='/usr/src/asterisk'
    local asterisk_version=$(lxc exec "$container_name" -- sh -c "ls $directory | grep -E '^asterisk-[0-9]+\.[0-9]+\.[0-9]+$' | awk '{print}'")

    echo "Asterisk Version: $asterisk_version"

    lxc exec $container_name -- /bin/bash -c "cd $directory/$asterisk_version && ./configure"
}
run_make_menuconfig() {
    local container_name=$1
    local directory='/usr/src/asterisk'
    local menuconfig_flag="no"
    local menuconfig_option=$2
    local asterisk_version=$(lxc exec "$container_name" -- sh -c "ls $directory | grep -E '^asterisk-[0-9]+\.[0-9]+\.[0-9]+$' | awk '{print}'")

    if [ -z "$container_name" ]; then
        echo "Please provide a container name as the first argument."
        return 1
    fi

    shift  # Shift the arguments to access the second variable

    # Check if the second argument is the -m or --menu-config flag
    if [ "${menuconfig_option-}" = "-m" ]; then
        menuconfig_flag="yes"
    fi

    # Check if the specified container exists
    if ! lxc info "$container_name" > /dev/null 2>&1; then
        echo "Container '$container_name' does not exist."
        return 1
    fi

    # Check if menuconfig flag is set
    if [ "$menuconfig_flag" = "yes" ]; then
        # Run make menuconfig in the default directory
        lxc exec "$container_name" -- /bin/bash -c "cd $directory/$asterisk_version && make menuconfig"
    else
        echo "Skipping 'make menuconfig'."
    fi
}



####################
check_and_install_svn() {
    local container_name=$1

    # Check if svn is installed
    if ! lxc exec "$container_name" -- command -v svn > /dev/null 2>&1; then
        echo "Subversion (svn) is not installed. Installing..."
        lxc exec "$container_name" -- dnf -y install subversion
        echo "Subversion (svn) has been installed in container '$container_name'."
    else
        echo "Subversion (svn) is already installed in container '$container_name'."
    fi
}
check_and_install_dnf_plugins_core() {
    local container_name=$1

    # Check if the specified container exists
    if ! lxc info "$container_name" > /dev/null 2>&1; then
        echo "Container '$container_name' does not exist."
        return 1
    fi

    # Check if dnf-plugins-core is installed in the container
    if lxc exec "$container_name" -- dnf -y list installed dnf-plugins-core > /dev/null 2>&1; then
        echo "dnf-plugins-core is already installed in container '$container_name'."
    else
        # Install dnf-plugins-core in the container
        lxc exec "$container_name" -- dnf -y install dnf-plugins-core
        echo "dnf-plugins-core has been installed in container '$container_name'."
    fi
}
check_and_install_epel_release() {
    local container_name=$1

    # Check if the specified container exists
    if ! lxc info "$container_name" > /dev/null 2>&1; then
        echo "Container '$container_name' does not exist."
        return 1
    fi

    # Check if epel-release is installed in the container
    if lxc exec "$container_name" -- dnf list installed epel-release > /dev/null 2>&1; then
        echo "epel-release is already installed in container '$container_name'."
    else
        # Install epel-release in the container
        lxc exec "$container_name" -- dnf -y install epel-release
        echo "epel-release has been installed in container '$container_name'."
    fi
}
check_and_enable_powertools() {
    local container_name=$1

    # Check if the specified container exists
    if ! lxc info "$container_name" > /dev/null 2>&1; then
        echo "Container '$container_name' does not exist."
        return 1
    fi

    # Check if powertools is enabled in the container
    if lxc exec "$container_name" -- dnf -y repolist enabled | grep -q "powertools"; then
        echo "powertools repository is already enabled in container '$container_name'."
    else
        # Enable powertools repository in the container
        lxc exec "$container_name" -- dnf -y config-manager --set-enabled powertools
        echo "powertools repository has been enabled in container '$container_name'."
    fi
}
run_dnf_update() {
    local container_name=$1

    # Check if the specified container exists
    if ! lxc info "$container_name" > /dev/null 2>&1; then
        echo "Container '$container_name' does not exist."
        return 1
    fi

    # Run dnf update in the container
    lxc exec "$container_name" -- dnf -y update

    echo "dnf update completed in container '$container_name'."
}




check_compiler_in_container() {
    local container_name=$1

    if [ -z "$container_name" ]; then
        echo "Please provide a container name as an argument."
        exit 1
    fi

    # Check if the specified container exists
    if ! lxc info "$container_name" > /dev/null 2>&1; then
        echo "Container '$container_name' does not exist."
        exit 1
    fi

    # Check for gcc inside the container
    local compiler_check=$(lxc exec "$container_name" -- command -v gcc 2>/dev/null)

    if [ -n "$compiler_check" ]; then
        echo "C compiler (gcc) is installed in container '$container_name'."
    else
        echo "C compiler (gcc) is not installed in container '$container_name'."
        # You can add additional instructions here for installing the compiler inside the container.
        echo "Attempting to install..."
	 lxc exec $container_name -- dnf -y install gcc
    fi
}
check_gcc_cpp() {
    local container_name=$1

    # Check if the specified container exists
    if ! lxc info "$container_name" > /dev/null 2>&1; then
        echo "Container '$container_name' does not exist."
        return 1
    fi

    # Check if gcc-c++ is installed in the container
    if lxc exec "$container_name" -- dnf list installed gcc-c++ > /dev/null 2>&1; then
        echo "gcc-c++ is installed in container '$container_name'."
    else
        echo "gcc-c++ is not installed in container '$container_name'. Installing..."
        lxc exec "$container_name" -- dnf -y install gcc-c++
    fi
}
check_gnu_make() {
    local container_name=$1

    # Check if the specified container exists
    if ! lxc info "$container_name" > /dev/null 2>&1; then
        echo "Container '$container_name' does not exist."
        return 1
    fi

    # Check if GNU Make is installed in the container
    if lxc exec "$container_name" -- command -v make > /dev/null 2>&1; then
        echo "GNU Make is installed in container '$container_name'."
    else
        echo "GNU Make is not installed in container '$container_name'. Installing..."
        lxc exec "$container_name" -- dnf -y install make
    fi
}
check_bzip2() {
    local container_name=$1

    # Check if the specified container exists
    if ! lxc info "$container_name" > /dev/null 2>&1; then
        echo "Container '$container_name' does not exist."
        return 1
    fi

    # Check if bzip2 is installed in the container
    if lxc exec "$container_name" -- command -v bzip2 > /dev/null 2>&1; then
        echo "bzip2 is installed in container '$container_name'."
    else
        echo "bzip2 is not installed in container '$container_name'. Installing..."
        lxc exec "$container_name" -- dnf -y install bzip2
    fi
}
install_openssl() {
    local container_name=$1

    # Check if the specified container exists
    if ! lxc info "$container_name" > /dev/null 2>&1; then
        echo "Container '$container_name' does not exist."
        return 1
    fi

    # Check if OpenSSL is installed in the container
    if lxc exec "$container_name" -- command -v openssl > /dev/null 2>&1; then
        echo "OpenSSL is installed in container '$container_name'."
    else
        echo "OpenSSL is not installed in container '$container_name'. Installing..."
        lxc exec "$container_name" -- dnf -y install openssl
    fi
}
install_libedit() {
    local container_name=$1

    # Check if the specified container exists
    if ! lxc info "$container_name" > /dev/null 2>&1; then
        echo "Container '$container_name' does not exist."
        return 1
    fi

    # Check if libedit development package is installed in the container
    if lxc exec "$container_name" -- rpm -q libedit-devel > /dev/null 2>&1; then
        echo "'libedit' development package is installed in container '$container_name'."
    else
        echo "'libedit' development package is not installed in container '$container_name'. Installing..."
        lxc exec "$container_name" -- dnf -y install libedit-devel
    fi
}
install_uuid_package() {
    local container_name=$1
    local uuid_dev_package='libuuid-devel'

    # Check if the specified container exists
    if ! lxc info "$container_name" > /dev/null 2>&1; then
        echo "Container '$container_name' does not exist."
        return 1
    fi

    # Check if the uuid development package is installed
    if lxc exec "$container_name" -- rpm -q "$uuid_dev_package" > /dev/null 2>&1; then
        echo "UUID development package '$uuid_dev_package' is already installed in container '$container_name'."
    else
        # Install the uuid development package
        lxc exec "$container_name" -- dnf install -y "$uuid_dev_package"

        echo "UUID development package '$uuid_dev_package' installed in container '$container_name'."
    fi
}
install_libjansson_packages() {
    local container_name=$1
    local jansson_dev_package='jansson-devel'

    # Check if the specified container exists
    if ! lxc info "$container_name" > /dev/null 2>&1; then
        echo "Container '$container_name' does not exist."
        return 1
    fi

    # Check if the libjansson development package is installed
    if lxc exec "$container_name" -- rpm -q "$jansson_dev_package" > /dev/null 2>&1; then
        echo "libjansson development package '$jansson_dev_package' is already installed in container '$container_name'."
    else
        # Install the libjansson development package
        lxc exec "$container_name" -- dnf install -y "$jansson_dev_package"

        echo "libjansson development package '$jansson_dev_package' installed in container '$container_name'."
    fi
}
install_libxml2_package() {
    local container_name=$1
    local libxml2_dev_package='libxml2-devel'

    # Check if the specified container exists
    if ! lxc info "$container_name" > /dev/null 2>&1; then
        echo "Container '$container_name' does not exist."
        return 1
    fi

    # Check if the libxml2 development package is installed
    if lxc exec "$container_name" -- rpm -q "$libxml2_dev_package" > /dev/null 2>&1; then
        echo "libxml2 development package '$libxml2_dev_package' is already installed in container '$container_name'."
    else
        # Install the libxml2 development package
        lxc exec "$container_name" -- dnf install -y "$libxml2_dev_package"

        echo "libxml2 development package '$libxml2_dev_package' installed in container '$container_name'."
    fi
}
install_sqlite3_package() {
    local container_name=$1
    local sqlite3_dev_package='sqlite-devel'

    # Check if the specified container exists
    if ! lxc info "$container_name" > /dev/null 2>&1; then
        echo "Container '$container_name' does not exist."
        return 1
    fi

    # Check if the SQLite3 development package is installed
    if lxc exec "$container_name" -- rpm -q "$sqlite3_dev_package" > /dev/null 2>&1; then
        echo "SQLite3 development package '$sqlite3_dev_package' is already installed in container '$container_name'."
    else
        # Install the SQLite3 development package
        lxc exec "$container_name" -- dnf install -y "$sqlite3_dev_package"

        echo "SQLite3 development package '$sqlite3_dev_package' installed in container '$container_name'."
    fi
}


#######################################################################################

if [ -z "${1-}" ]; then
    echo "Missing Container."
    lxc ls
    echo "+-------------+---------+---------------------+-----------------------------------------------+-----------+-----------+"
    echo "+ ./build.sh <container_name> -m # Use -m to make menuconfig"
    echo "+-------------+---------+---------------------+-----------------------------------------------+-----------+-----------+"
else
    echo "Using Container: $1"
    container_name=$1
    make_menuconfig=$2

    check_and_install_dnf_plugins_core "$container_name"
    check_and_install_epel_release "$container_name"
    check_and_enable_powertools "$container_name"
    run_dnf_update "$container_name"
    check_and_install_svn "$container_name"
    check_compiler_in_container "$container_name"
    check_gcc_cpp "$container_name"
    check_gnu_make "$container_name"
    check_bzip2 "$container_name"
    install_openssl "$container_name"
    install_libedit "$container_name"
    install_uuid_package "$container_name"
    install_libjansson_packages "$container_name"
    install_libxml2_package "$container_name"
    install_sqlite3_package "$container_name"

    configure_asterisk "$container_name"
    run_make_menuconfig "$container_name" "$make_menuconfig"
    run_make "$container_name"
fi

