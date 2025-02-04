#!/bin/bash

# Function to generate a random password
generate_password() {
  openssl rand -base64 12
}

# Function to install Apache, MySQL, and PHP
install_apache_mysql_php() {
  echo "[INFO] Installing Apache..."
  apt install apache2 -y
  systemctl enable apache2
  systemctl start apache2
  echo "[INFO] Apache installed and started."

  echo "[INFO] Setting priority for index.php..."
  cat << EOF > /etc/apache2/mods-enabled/dir.conf
<IfModule mod_dir.c>
    DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
</IfModule>
EOF
  systemctl restart apache2

  MYSQL_ROOT_PASSWORD=$(generate_password)
  echo "[INFO] Installing MySQL..."
  apt install mysql-server -y
  systemctl enable mysql
  systemctl start mysql
  mysql --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;"
  echo "[INFO] MySQL installed and root password configured."

  echo "[INFO] Installing PHP and required extensions..."
  apt install php libapache2-mod-php php-mysql php-curl php-gd php-cli php-mbstring php-xml php-zip php-bcmath php-intl php-soap -y
  echo "[INFO] PHP installed with necessary extensions for Matomo."
}

# Function to configure Apache virtual host
configure_virtual_host() {
  echo "[INFO] Configuring Apache virtual host..."
  VHOST_DIR="/var/www/${HOSTNAME}"
  MATOMO_DIR="${VHOST_DIR}/matomo"

  cat << EOF > /etc/apache2/sites-available/${HOSTNAME}.conf
<VirtualHost *:80>
    ServerName ${HOSTNAME}
    DocumentRoot ${VHOST_DIR}

    <Directory ${MATOMO_DIR}>
        DirectoryIndex index.php
        AllowOverride All
        Require all granted
    </Directory>

    <Directory ${VHOST_DIR}>
        DirectoryIndex info.php
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${HOSTNAME}_error.log
    CustomLog \${APACHE_LOG_DIR}/${HOSTNAME}_access.log combined
</VirtualHost>
EOF

  mkdir -p ${MATOMO_DIR}
  a2ensite ${HOSTNAME}
  a2dissite 000-default
  systemctl reload apache2

  echo "[INFO] Virtual host configured for ${HOSTNAME}."
}

# Function to upload Matomo files
upload_matomo() {
  echo "[INFO] Uploading Matomo files..."
  read -p "Enter your hostname (e.g., example.com): " HOSTNAME
  if [ -z "$HOSTNAME" ]; then
    echo "[ERROR] Hostname cannot be empty. Exiting."
    exit 1
  fi

  configure_virtual_host

  git clone https://github.com/matomo-org/matomo.git ${MATOMO_DIR}
  cd ${MATOMO_DIR}
  echo "[INFO] Checking out the stable release 5.2.1..."
  git checkout 5.2.1
  git submodule update --init --recursive
  echo "[INFO] Installing Composer dependencies..."
  curl -sS https://getcomposer.org/installer | php
  php composer.phar install --no-dev

  chown -R www-data:www-data ${MATOMO_DIR}
  chmod -R 755 ${MATOMO_DIR}

  # Create info.php for PHP verification
  cat << EOF > ${VHOST_DIR}/info.php
<?php
phpinfo();
?>
EOF
  chown www-data:www-data ${VHOST_DIR}/info.php
  chmod 644 ${VHOST_DIR}/info.php

  echo "[INFO] Matomo uploaded successfully to ${MATOMO_DIR}."
  echo "[INFO] PHP test file created at ${VHOST_DIR}/info.php."
}

# Main menu
echo "Select an installation option:"
echo "1. Full install (Apache, MySQL, PHP, Matomo upload)"
echo "2. Install Apache, MySQL, and PHP"
echo "3. Upload Matomo files"
echo "4. Exit"
read -p "Enter your choice: " CHOICE

case $CHOICE in
  1)
    install_apache_mysql_php
    upload_matomo
    ;;
  2)
    install_apache_mysql_php
    ;;
  3)
    upload_matomo
    ;;
  4)
    echo "Exiting."
    exit 0
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

# Display output if full install was selected
if [ "$CHOICE" == "1" ]; then
  IP_ADDRESS=$(hostname -I | awk '{print $1}')
  echo "[INFO] Full setup completed successfully!"
  echo "========================================="
  echo "MySQL Root Password: ${MYSQL_ROOT_PASSWORD}"
  echo "Matomo URL: http://${IP_ADDRESS}/matomo"
  echo "PHP Info URL: http://${IP_ADDRESS}/info.php"
  echo "========================================="
fi
