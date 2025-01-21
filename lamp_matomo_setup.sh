#!/bin/bash

# Function to generate a random password
generate_password() {
  openssl rand -base64 12
}

# Function to install and configure SSH server
install_ssh() {
  echo "[INFO] Ensuring SSH server is installed..."
  if ! dpkg -l | grep -q openssh-server; then
    apt update -y && apt install openssh-server -y
    echo "[INFO] SSH server installed."
  fi
  sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  systemctl restart sshd
  echo "[INFO] Root login with password enabled. SSH service restarted."
}

# Function to install Apache and MySQL
install_apache_mysql() {
  echo "[INFO] Installing Apache..."
  apt install apache2 -y
  systemctl enable apache2
  systemctl start apache2
  echo "[INFO] Apache installed and started."

  MYSQL_ROOT_PASSWORD=$(generate_password)
  echo "[INFO] Installing MySQL..."
  apt install mysql-server -y
  systemctl enable mysql
  systemctl start mysql
  mysql --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;"
  echo "[INFO] MySQL installed and root password configured."
}

# Function to install Matomo
install_matomo() {
  read -p "Enter the directory where Matomo should be installed (default: /var/www/matomo): " MATOMO_DIR
  MATOMO_DIR=${MATOMO_DIR:-/var/www/matomo}
  echo "[INFO] Installing Matomo in $MATOMO_DIR..."

  mkdir -p ${MATOMO_DIR}
  git clone https://github.com/matomo-org/matomo.git ${MATOMO_DIR}
  cd ${MATOMO_DIR}
  echo "[INFO] Checking out a stable release..."
  git checkout 5.1.1
  git submodule update --init --recursive
  echo "[INFO] Installing Composer dependencies..."
  curl -sS https://getcomposer.org/installer | php
  php composer.phar install --no-dev

  echo "[INFO] Configuring Matomo Database..."
  MATOMO_DB_NAME="matomo"
  MATOMO_DB_USER="matomo_user"
  MATOMO_DB_PASSWORD=$(generate_password)
  MATOMO_ADMIN_USERNAME="admin"
  MATOMO_ADMIN_PASSWORD=$(generate_password)
  MATOMO_ADMIN_EMAIL="admin@example.com"

  mysql --execute="CREATE DATABASE ${MATOMO_DB_NAME};"
  mysql --execute="CREATE USER '${MATOMO_DB_USER}'@'localhost' IDENTIFIED BY '${MATOMO_DB_PASSWORD}';"
  mysql --execute="GRANT ALL PRIVILEGES ON ${MATOMO_DB_NAME}.* TO '${MATOMO_DB_USER}'@'localhost';"
  mysql --execute="FLUSH PRIVILEGES;"

  php ${MATOMO_DIR}/console core:update --yes

  echo "[INFO] Generating Matomo configuration file..."
  cat << EOF > ${MATOMO_DIR}/config/config.ini.php
[database]
host = "127.0.0.1"
username = "${MATOMO_DB_USER}"
password = "${MATOMO_DB_PASSWORD}"
dbname = "${MATOMO_DB_NAME}"
adapter = "PDO_MYSQL"
port = 3306

[General]
assume_secure_protocol = 0
trusted_hosts[] = "localhost"
EOF

  php ${MATOMO_DIR}/console development:disable
  php ${MATOMO_DIR}/console core:create-user --superuser --login=${MATOMO_ADMIN_USERNAME} --password=${MATOMO_ADMIN_PASSWORD} --email=${MATOMO_ADMIN_EMAIL}

  chown -R www-data:www-data ${MATOMO_DIR}
  chmod -R 755 ${MATOMO_DIR}

  echo "[INFO] Matomo installed successfully."
}

# Function to install No-IP Dynamic Update Client
install_noip() {
  echo "[INFO] Installing No-IP Dynamic Update Client (DUC)..."
  wget --content-disposition https://www.noip.com/download/linux/latest -O noip.tar.gz
  tar xf noip.tar.gz
  cd noip-duc-*/binaries
  apt install ./noip-duc_*_amd64.deb
  echo "[INFO] No-IP DUC installed."
}

# Main menu
echo "Select an installation option:"
echo "1. Full install (Apache, MySQL, Matomo, No-IP DUC)"
echo "2. Install Apache & MySQL"
echo "3. Install Matomo"
echo "4. Install No-IP Dynamic Update Client (DUC)"
echo "5. Exit"
read -p "Enter your choice: " CHOICE

case $CHOICE in
  1)
    install_ssh
    install_apache_mysql
    install_matomo
    install_noip
    ;;
  2)
    install_ssh
    install_apache_mysql
    ;;
  3)
    install_matomo
    ;;
  4)
    install_noip
    ;;
  5)
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
  echo "Matomo Admin Username: ${MATOMO_ADMIN_USERNAME}"
  echo "Matomo Admin Email: ${MATOMO_ADMIN_EMAIL}"
  echo "Matomo Admin Password: ${MATOMO_ADMIN_PASSWORD}"
  echo "Matomo Database User Password: ${MATOMO_DB_PASSWORD}"
  echo "Matomo URL: http://${IP_ADDRESS}/matomo"
  echo "========================================="
fi
