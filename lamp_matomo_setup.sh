#!/bin/bash

# Function to generate a random password
generate_password() {
  openssl rand -base64 12
}

# Enable root login with password in sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

echo "[INFO] Root login with password enabled. SSH service restarted."

# Update and install required packages
apt update -y && apt upgrade -y

# Install Apache
echo "[INFO] Installing Apache..."
apt install apache2 -y
systemctl enable apache2
systemctl start apache2

echo "[INFO] Apache installed and started."

# Install MySQL and set up with a random password
MYSQL_ROOT_PASSWORD=$(generate_password)
echo "[INFO] Installing MySQL..."
apt install mysql-server -y
systemctl enable mysql
systemctl start mysql

mysql --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;"

echo "[INFO] MySQL installed and root password configured."

# Install PHP and required extensions
echo "[INFO] Installing PHP and required extensions..."
apt install php libapache2-mod-php php-mysql php-curl php-gd php-cli php-mbstring php-xml php-zip php-bcmath php-intl php-soap -y

echo "[INFO] PHP installed with necessary extensions for Matomo."

# Configure Apache to prefer PHP files over others
cat << EOF > /etc/apache2/mods-enabled/dir.conf
<IfModule mod_dir.c>
    DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
</IfModule>
EOF
systemctl restart apache2

echo "[INFO] Apache configured to prioritize PHP files."

# Ask the user for hostname and create a virtual host
read -p "Enter your hostname (e.g., example.com): " HOSTNAME
if [ -z "$HOSTNAME" ]; then
  echo "[ERROR] Hostname cannot be empty. Exiting."
  exit 1
fi

cat << EOF > /etc/apache2/sites-available/${HOSTNAME}.conf
<VirtualHost *:80>
    ServerName ${HOSTNAME}
    DocumentRoot /var/www/${HOSTNAME}

    <Directory /var/www/${HOSTNAME}>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${HOSTNAME}_error.log
    CustomLog \${APACHE_LOG_DIR}/${HOSTNAME}_access.log combined
</VirtualHost>
EOF

mkdir -p /var/www/${HOSTNAME}
cat << EOF > /var/www/${HOSTNAME}/index.php
<?php
phpinfo();
?>
EOF

chown -R www-data:www-data /var/www/${HOSTNAME}
chmod -R 755 /var/www/${HOSTNAME}

a2ensite ${HOSTNAME}
a2dissite 000-default

# Test Apache configuration for syntax errors
apache2ctl configtest

# Reload Apache to apply changes
if [ $? -eq 0 ]; then
    systemctl reload apache2
    echo "[INFO] Apache reloaded successfully!"
else
    echo "[ERROR] Apache configuration test failed. Please check your configuration."
    exit 1
fi

# Install Git
echo "[INFO] Installing Git..."
apt install git -y

# Clone and set up Matomo
echo "[INFO] Setting up Matomo..."
MATOMO_DIR=/var/www/${HOSTNAME}/matomo
git clone https://github.com/matomo-org/matomo.git ${MATOMO_DIR}
chown -R www-data:www-data ${MATOMO_DIR}
chmod -R 755 ${MATOMO_DIR}

# Ask for Matomo admin information
read -p "Enter Matomo Admin Email: " MATOMO_ADMIN_EMAIL
read -p "Enter Matomo Admin Username: " MATOMO_ADMIN_USERNAME
MATOMO_ADMIN_PASSWORD=$(generate_password)

echo "[INFO] Configuring Matomo Database..."
MATOMO_DB_NAME="matomo"
MATOMO_DB_USER="matomo_user"
MATOMO_DB_PASSWORD=$(generate_password)

mysql --execute="CREATE DATABASE ${MATOMO_DB_NAME};"
mysql --execute="CREATE USER '${MATOMO_DB_USER}'@'localhost' IDENTIFIED BY '${MATOMO_DB_PASSWORD}';"
mysql --execute="GRANT ALL PRIVILEGES ON ${MATOMO_DB_NAME}.* TO '${MATOMO_DB_USER}'@'localhost';"
mysql --execute="FLUSH PRIVILEGES;"

cat << EOF > ${MATOMO_DIR}/config.ini.php
[database]
host = "127.0.0.1"
username = "${MATOMO_DB_USER}"
password = "${MATOMO_DB_PASSWORD}"
dbname = "${MATOMO_DB_NAME}"
adapter = "PDO_MYSQL"
port = 3306

[General]
assume_secure_protocol = 0
trusted_hosts[] = "${HOSTNAME}"
EOF

# Set up No-IP client
echo "[INFO] Setting up No-IP client..."
wget --content-disposition https://www.noip.com/download/linux/latest
LATEST_FILE=$(ls noip-duc_*.tar.gz | tail -n 1)
tar xf $LATEST_FILE
LATEST_DIR=$(tar -tzf $LATEST_FILE | head -1 | cut -f1 -d"/")
cd $LATEST_DIR
sudo make install

echo "[INFO] Please follow the prompts to configure the No-IP client."
sudo /usr/local/bin/noip2 -C

# Display MySQL password, Matomo details, and webserver URL
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "[INFO] Setup completed successfully!"
echo "========================================="
echo "MySQL Root Password: ${MYSQL_ROOT_PASSWORD}"
echo "Matomo Admin Username: ${MATOMO_ADMIN_USERNAME}"
echo "Matomo Admin Email: ${MATOMO_ADMIN_EMAIL}"
echo "Matomo Admin Password: ${MATOMO_ADMIN_PASSWORD}"
echo "Matomo URL: http://${IP_ADDRESS}/matomo"
echo "Website URL: http://${IP_ADDRESS} (or http://${HOSTNAME} if DNS is configured)"
echo "Test PHP info page: http://${IP_ADDRESS}/index.php"
echo "========================================="
