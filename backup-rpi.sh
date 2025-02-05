#!/usr/bin/env bash

# Default values
host="192.168.13.170"
config_path="etc/rpi4-klipper.conf"

# Get location of this script
sp="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
json_file="$sp/servers.json"

# Help message function
print_help() {
    echo "Usage: $(basename "$0") [server_name]"
    echo
    echo "Arguments:"
    echo "  server_name    Name of the server as defined in servers.json"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message and exit"
    echo
    echo "If no server_name is provided, the default values will be used:"
    echo -e "  host: $host    config: $config_path"
    echo
    echo "content of servers.json:"
    echo
    cat "$json_file"
    exit 0
}

# Function to parse JSON using jq
get_server_info() {
    local name="$1"
    local json_data
    json_data=$(jq -r --arg name "$name" '.[] | select(.name == $name)' "$json_file")

    if [[ -n "$json_data" ]]; then
        host=$(echo "$json_data" | jq -r '.ip')
        config_path=$(echo "$json_data" | jq -r '.config')
    else
        echo "Server name '$name' not found in $json_file. Using default values."
    fi
}

# Check for input argument
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print_help
elif [[ -n "$1" ]]; then
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed. Install it and try again."
        exit 1
    fi
    get_server_info "$1"
fi

# Check if the host is reachable
if ! ping -c 3 -w 5 "$host" > /dev/null; then
    echo "Host $host is not responding!"
    exit 1
else
    echo
    echo "==> Host $host is reachable."
    echo "==> Commencing mounting of its image and rsync"
    echo "==> using $config_path for config"
    echo
fi

# Navigate to the backup script directory
cd /home/hamid/Downloads/src/rpi-backup-script || exit

# Run backup script with the determined config path
bin/backup-rpi "$config_path"
