#!/bin/bash

# Function to add a cronjob
add_cronjob() {
    # Add a cronjob to execute the disk_monitor.sh script every hour
    if ! crontab -l | grep -q "$(pwd)/disk_monitor.sh"; then
        (crontab -l 2>/dev/null; echo "0 * * * * $(pwd)/disk_monitor.sh") | crontab -
        echo "Cronjob added successfully."
    else
        echo "Cronjob already exists."
    fi
}

# Function to monitor disk space
disk_monitor() {
    # Get disk usage percentage
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)

    # Check if disk usage exceeds 10%
    if [ $disk_usage -gt 10 ]; then
        echo "Disk space almost full ${disk_usage}% used." >> $(pwd)/message.log
    else
        echo "Disk space usage: ${disk_usage}%.">> $(pwd)/message.log
    fi
}

# Main function
main() {
    # Check if the script is run as root
    if [ "$(id -u)" -ne 0 ]; then
        echo "Please run this script with sudo or as root."
        exit 1
    fi

    # Check if the message log file exists, if not create it
    if [ ! -f "$(pwd)/message.log" ]; then
        touch $(pwd)/message.log
    fi

    # Call the add_cronjob function to set up the cronjob
    add_cronjob

    # Call the disk_monitor function to check disk space immediately
    disk_monitor
}

# Call the main function
main

