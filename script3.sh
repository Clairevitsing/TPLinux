#!/bin/bash

if [ "$EUID" -ne 0 ]
then echo "Please run as root"
exit
fi

# Function to create a new user with a password
create_user() {
    # Check if there are exactly 2 arguments
    if [ $# -ne 2 ]; then
        echo "Usage: $0 user username password"
        exit 1
    fi
    
    # Create a new user with the specified name
    local username="$1"
    local password="$2"
    echo "Creating user: $username"
    useradd "$username" --create-home
    
    # Set the password for the new user
    echo "$username:$password" | chpasswd
    
    echo "User created: $username"
    echo "Password saved: $password"
}

# Function to install nginx
install_nginx() {
    echo "Updating repositories..."
    apt update
    echo "Installing nginx package..."
    apt install -y nginx
    echo "Nginx installed successfully."
}

# Function to configure an nginx site
configure_site() {
    # Check if there is exactly 1 argument
    if [ $# -ne 1 ]; then
        echo "Usage: $0 configure_site site_name"
        exit 1
    fi
    
    # Create the configuration file in /etc/nginx/sites-available
    local site_name="$1"
    echo "Creating configuration file for site: $site_name"
    cp /etc/nginx/sites-available/default "/etc/nginx/sites-available/$site_name"
    echo "Configuration file created: /etc/nginx/sites-available/$site_name"
}

# Check the first argument and call the corresponding function
case "$1" in
    "user")
        shift
        create_user "$@"
        ;;
    "install")
        install_nginx
        ;;
    "configure_site")
        shift
        configure_site "$@"
        ;;
    *)
        echo "Invalid argument. Usage:"
        echo "To create a user: $0 user username password"
        echo "To install nginx: $0 install"
        echo "To configure a site: $0 configure_site site_name"
        exit 1
        ;;
esac

