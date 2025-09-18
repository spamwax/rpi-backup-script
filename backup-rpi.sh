#!/usr/bin/env bash

# Default values
host="192.168.13.170"
config_path="etc/cr6-klipper.conf"

# Get location of this script
sp="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Read JSON file
json_file="$sp/servers.json"

usage() {
    echo "Usage: $(basename "$0") [server-name]"
    echo
    echo "Clone backup from a predefined server using bin/backup-rpi."
    echo
    echo "Arguments:"
    echo "  server-name   Name of the server as defined in servers.json."
    echo "                If omitted, defaults to host=$host and config=$config_path."
    echo
    echo "Options:"
    echo "  -h, --help    Show this help message and exit."
    echo
    if command -v jq &> /dev/null && [[ -f "$json_file" ]]; then
        echo "Available servers:"
        jq -r '.[] | "  \(.name)\t→ \(.ip) (config: \(.config))"' "$json_file"
    else
        echo "Available servers: (servers.json not found or jq missing)"
    fi
    echo
    echo "Example:"
    echo "  $0 cr6"
    echo "  $0 rpi3"
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

# Handle arguments
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
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
    echo "==> Commencing mounting of its image and rsync using"
    echo "$config_path as config"
fi

# Navigate to the backup script directory
cd /home/hamid/Downloads/src/rpi-backup-script || exit

# Run backup script with the determined config path
bin/backup-rpi -s -c "$config_path"
