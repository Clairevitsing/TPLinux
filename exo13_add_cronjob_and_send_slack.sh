#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script with sudo or as root."
    exit 1
fi

# Function to install curl using package manager
function install_curl() {
    local package_manager

    # Check which package manager is available
    if command -v apt-get &> /dev/null; then
        package_manager="apt-get"
    elif command -v yum &> /dev/null; then
        package_manager="yum"
    elif command -v dnf &> /dev/null; then
        package_manager="dnf"
    else
        echo "Unable to install curl. Please install it manually."
        exit 1
    fi

    # Install curl using the appropriate package manager
    $package_manager install -y curl
}

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "curl is not installed. Attempting to install it..."
    install_curl
fi

# Define Slack webhook URL and message
slack_webhook="https://hooks.slack.com/services/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"
message="hello world"
json="{\"text\":\"$message\"}"

# Function to add a cron job and send a message to Slack
function add_cronjob_and_send_to_slack() {
    local message="$1"

    # Add the cron job
    local cron_command="echo \"$message\""
    # Run every minute, you can customize this as needed
    local cron_schedule="* * * * *"  
    echo "$cron_schedule $cron_command" | crontab -

    # Send the message to Slack
    curl -X POST -H "Content-Type: application/json" -d "$json" "$slack_webhook"
}

# Use the function to add a cron job and send a message to Slack
add_cronjob_and_send_to_slack "$message"

