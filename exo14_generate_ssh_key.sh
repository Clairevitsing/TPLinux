#!/bin/bash

# Function to generate SSH key
generate_ssh_key() {
    # Check if argument is provided
    if [ $# -ne 1 ]; then
        echo "Usage: generate_ssh_key <key_name>"
        return 1
    fi

    local key_name="$1"

    # Generate 4096-bit RSA SSH key
    ssh-keygen -t rsa -b 4096 -f "$key_name"

    echo "SSH key generated successfully: $key_name"
}

# Call the function with provided argument
generate_ssh_key "$1"
