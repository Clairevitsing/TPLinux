#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script with sudo or as root."
    exit 1
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

# Function to install nginx package
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
    
    local site_name="$1"
    local http_port="$2"

    # Create directory for the site using the site name
    local site_directory="/var/www/$site_name"
    echo "Creating directory for site: $site_directory"
    mkdir -p "$site_directory"

    # Generate index.html file with site name
    echo "Generating index.html for site: $site_name"
    echo "<!DOCTYPE html>
<html>
<head>
<title>$site_name</title>
</head>
<body>
<h1>Welcome to $site_name!</h1>
</body>
</html>" > "$site_directory/index.html"

    # Generate Nginx configuration file for the site
    local nginx_config="/etc/nginx/sites-available/$site_name"
    echo "Generating Nginx configuration file: $nginx_config"
    cat << EOF > "$nginx_config"
server {
    listen $http_port;
    listen [::]:$http_port;

    server_name $site_name;

    root $site_directory;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

     # Create symbolic link to enable site configuration
    ln -s "/etc/nginx/sites-available/$site_name" "/etc/nginx/sites-enabled/"

    # Reload Nginx to apply changes
    echo "Reloading Nginx to apply changes..."
    systemctl reload nginx

    # Echo message indicating successful site configuration
    echo "Site configuration with PHP support generated successfully: $site_name, and configured on port $http_port"
}

# Function to active a site
active_site() {
    # Check if there is exactly 1 argument
    if [ $# -ne 1 ]; then
        echo "Usage: $0 active_site site_name"
        exit 1
    fi
    
    site_name="$1"

    # Check if the directory for the site exists, if not, create it
    if [ ! -d "/var/www/$site_name" ]; then
        mkdir -p "/var/www/$site_name"
    fi

    # Check if index.html already exists, if not, create it
    if [ ! -f "/var/www/$site_name/index.html" ]; then
        touch "/var/www/$site_name/index.html"
        echo "<!DOCTYPE html><html><head><title>$site_name</title></head><body><h1>Welcome to $site_name!</h1></body></html>" > "/var/www/$site_name/index.html"
    fi

    # Replace ":sitename" with the site name in index.html
    sed -i "s/:sitename/$site_name/g" "/var/www/$site_name/index.html"

    # Check if the Nginx configuration file exists in sites-available
    nginx_config="/etc/nginx/sites-available/$site_name"
    if [ ! -f "$nginx_config" ]; then
        echo "Nginx configuration file not found for site: $site_name"
        exit 1
    fi

    # Activate site configuration by creating symlink in sites-enabled
    ln -sf "$nginx_config" "/etc/nginx/sites-enabled/$site_name"
    
    # Reload Nginx to apply changes
    systemctl reload nginx
    
    echo "Site configuration activated successfully: $site_name"
}

# Function to activate site configuration
add_cronjob() {
    # Define the file where "helloworld" will be appended
    file_path="/home/claire/script/monscript"  
    
    # Check if the file exists, if not, create it
    if [ ! -f "$file_path" ]; then
        echo "Creating file: $file_path"
        touch "$file_path"
        
        # Change the owner and group of the file to claire
        chown claire:claire "$file_path"
        
        # Grant write permissions to the owner of the file
        chmod u+w "$file_path"
    fi

    # Add a cronjob to append "helloworld" to the file every 5 minutes
    cronjob="*/5 * * * * echo 'helloworld' >> $file_path"
    (crontab -l ; echo "$cronjob") | crontab -
    
    echo "Cronjob added successfully."
}

# Main script execution starts here

case "$1" in
    "user")
        shift
        create_user "$@"
        ;;
    "install")
        install_nginx
        ;;
    "configure_site")
        configure_site "$2" "$3"
        ;;
    "active_site")
        active_site "$2"
        ;;
    "add_cronjob")
        add_cronjob
        ;; 
    *)
        # Invalid argument provided
        echo "Invalid argument. Usage:"
        echo "To create a user: $0 user username password"
        echo "To install nginx: $0 install"
        echo "To configure a site: $0 configure_site site_name http_port"
        echo "To activate a site: $0 active_site site_name"
        echo "To add a cronjob: $0 add_cronjob"
        exit 1
        ;;
esac

