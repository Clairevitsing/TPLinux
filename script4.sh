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

install_nginx() {
    echo "Updating repositories..."
    apt update
    echo "Installing nginx package..."
    apt install -y nginx
    echo "Nginx installed successfully."
}

# Function to configure site
configure_site() {
    # Check if there are exactly 2 arguments
    if [ $# -ne 2 ]; then
        echo "Usage: $0 configure_site site_name http_port"
        exit 1
    fi
    
    site_name="$1"
    http_port="$2"

    # Logic to configure the site goes here
    echo "Configuring site: $site_name on port $http_port"
}

case "$1" in
    "user")
        shift
        create_user "$@"
        ;;
    "install")
        install_nginx
        ;;
    "configure_site")
        configure_site "$@"
        ;;
    *)
        # Invalid argument provided
        echo "Invalid argument. Usage:"
        echo "To create a user: $0 user username password"
        echo "To install nginx: $0 install"
        echo "To configure a site: $0 configure_site site_name http_port"
        exit 1
        ;;
esac

# New functionality to generate Nginx server block configuration
if [ "$1" = "generate_config" ]; then
    # Check if there are exactly 3 arguments
    if [ $# -ne 4 ]; then
        echo "Usage: $0 generate_config site_name http_port root_directory"
        exit 1
    fi

    site_name="$2"
    http_port="$3"
    root_directory="$4"

    # Generate Nginx server block configuration
    echo "server {
    listen $http_port default_server;
    listen [::]:$http_port default_server;

    root $root_directory;

    index index.html;

    server_name $site_name;

    location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to displaying a 404.
        try_files \$uri \$uri/ =404;
    }
}"
fi

