#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script with sudo or as root."
    exit 1
fi

# Function to install PHP
install_php() {
    echo "Installing PHP..."
    apt update
    apt install -y php php-fpm
    echo "PHP installed successfully."
}

# Function to install MySQL
install_mysql() {
    echo "Installing MySQL..."
    apt update
    apt install -y mysql-server
    echo "MySQL installed successfully."

    # Start MySQL service
    systemctl start mysql

    # Check if MySQL service is running
    if ! systemctl is-active --quiet mysql; then
        echo "Failed to start MySQL service."
        exit 1
    fi

    # Secure MySQL installation
    mysql_secure_installation
}


# Function to configure a site with PHP support
configure_php_site() {

    # Check if there are exactly 2 arguments
    if [ $# -ne 2 ]; then
        echo "Usage: $0 configure_php_site site_name http_port"
        exit 1
    fi
    
    local site_name="$1"
    local http_port="$2"
    
    # Create directory for the site using the site name
    local site_directory="/var/www/$site_name"
    echo "Creating directory for site: $site_directory"
    mkdir -p "$site_directory"

    # Generate index.php file with site name
    echo "Generating index.php for site: $site_name"
    echo "<?php
    echo '<!DOCTYPE html>
<html>
<head>
<title>$site_name</title>
</head>
<body>
<h1>Welcome to $site_name!</h1>
</body>
</html>';
?>" > "$site_directory/index.php"

    # Generate Nginx configuration file for the site with PHP support
    local nginx_config="/etc/nginx/sites-available/$site_name"
    echo "Generating Nginx configuration file: $nginx_config"
    cat << EOF > "$nginx_config"
server {
    listen $http_port;
    listen [::]:$http_port;

    server_name $site_name;

    root $site_directory;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
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

# Main Script
case "$1" in
    "install_php")
        install_php
        ;;
    "install_mysql")
        install_mysql
        ;;
    "configure_php_site")
        configure_php_site "$2" "$3"
        ;;
    *)
        # Invalid argument provided
        echo "Invalid argument. Usage:"
        echo "To install PHP: $0 install_php"
        echo "To install MySQL: $0 install_mysql"
        echo "To configure a site with PHP support: $0 configure_php_site site_name http_port"
        exit 1
        ;;
esac


