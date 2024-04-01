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
    apt install -y php php-fpm php-mysql
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

# Function to configure a site with PHP support and MySQL integration
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
    mkdir -p "$site_directory" || { echo "Failed to create directory"; exit 1; }

    # Prompt user to enter database connection details
    read -p "Enter MySQL username: " username
    read -s -p "Enter MySQL password: " password
    read -p "Enter MySQL database name: " dbname

    # Create MySQL user and database
    mysql -u root -p -e "CREATE USER IF NOT EXISTS '$username'@'localhost' IDENTIFIED BY '$password';" || { echo "Failed to create MySQL user"; exit 1; }
    mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS $dbname;" || { echo "Failed to create MySQL database"; exit 1; }
    mysql -u root -p -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$username'@'localhost';" || { echo "Failed to grant privileges"; exit 1; }

    # Generate index.php file with site name and database content
    echo "Generating index.php for site: $site_name"
    cat << EOF > "$site_directory/index.php"
<?php
// Database configuration
\$servername = "localhost";
\$username = "$username";
\$password = "$password";
\$dbname = "$dbname";

// Create connection
\$conn = new mysqli(\$servername, \$username, \$password, \$dbname);

// Check connection
if (\$conn->connect_error) {
    die("Connection failed: " . \$conn->connect_error);
}

// Check if the table exists, if not, create it and insert data
\$result = \$conn->query("SHOW TABLES LIKE 'tablename'");
if (\$result->num_rows == 0) {
    // Table does not exist, create it
    \$sql_create_table = "CREATE TABLE tablename (
        id INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(30) NOT NULL
    )";
    if (\$conn->query(\$sql_create_table) === TRUE) {
        echo "Table created successfully<br>";
        // Insert some datas
        \$sql_insert_data = "INSERT INTO tablename (name) VALUES ('Claire'), ('June'), ('July')";
        if (\$conn->query(\$sql_insert_data) === TRUE) {
            echo "Data inserted successfully<br>";
        } else {
            echo "Error inserting data: " . \$conn->error . "<br>";
        }
    } else {
        echo "Error creating table: " . \$conn->error . "<br>";
    }
}

// Fetch data from database
\$sql_select_data = "SELECT * FROM tablename";
\$result = \$conn->query(\$sql_select_data);

if (\$result->num_rows > 0) {
    // Output data of each row
    while(\$row = \$result->fetch_assoc()) {
        echo "id: " . \$row["id"]. " - Name: " . \$row["name"]. "<br>";
    }
} else {
    echo "0 results";
}
\$conn->close();
?>

<!DOCTYPE html>
<html>
<head>
<title>$site_name</title>
</head>
<body>
<h1>Welcome to $site_name!</h1>
</body>
</html>
EOF

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
    systemctl reload nginx || { echo "Failed to reload Nginx"; exit 1; }

    # Echo message indicating successful site configuration
    echo "Site configuration with PHP support and MySQL integration generated successfully: $site_name, and configured on port $http_port"
}

# Function to install PHP
install_wordpress() {
    echo "Installing WordPress..."

    # Download WordPress
    if ! wget -q https://wordpress.org/latest.tar.gz -P /tmp; then
        echo "Failed to download WordPress. Please check your network connection and try again."
        return 1
    fi

    # Extract WordPress
    if ! tar -xzf /tmp/latest.tar.gz -C /var/www/; then
        echo "Failed to extract WordPress. Please check your file system and try again."
        return 1
    fi

    # Create WordPress configuration file
    if ! cp /var/www/wordpress/wp-config-sample.php /var/www/wordpress/wp-config.php; then
        echo "Failed to create the WordPress configuration file. Please check your file system and try again."
        return 1
    fi

    # Generate secret keys and salts
    secret_keys=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    if [ -z "$secret_keys" ]; then
        echo "Failed to generate secret keys and salts. Please check your network connection and try again."
        return 1
    fi
    echo "$secret_keys" | tee -a /var/www/wordpress/wp-config.php > /dev/null

    # Set up database details
    read -p "Enter MySQL username: " username
    read -s -p "Enter MySQL password: " password
    echo
    read -p "Enter MySQL database name for WordPress: " wp_dbname

    sed -i "s/database_name_here/$wp_dbname/" /var/www/wordpress/wp-config.php
    sed -i "s/username_here/$username/" /var/www/wordpress/wp-config.php
    sed -i "s/password_here/$password/" /var/www/wordpress/wp-config.php

    # Set correct permissions
    if ! chown -R www-data:www-data /var/www/wordpress; then
        echo "Failed to set permissions. Please check your file system and try again."
        return 1
    fi

    echo "WordPress installed successfully."
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
    "install_wordpress")
        install_wordpress
        ;;
    *)
        # Invalid argument provided
        echo "Invalid argument. Usage:"
        echo "To install PHP: $0 install_php"
        echo "To install MySQL: $0 install_mysql"
        echo "To configure a site with PHP support and MySQL integration: $0 configure_php_site site_name http_port"
        echo "To install WordPress: $0 install_wordpress"
        exit 1
        ;;
esac

