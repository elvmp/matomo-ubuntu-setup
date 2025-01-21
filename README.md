# matomo-ubuntu-setup
# LAMP and Matomo Setup Script

This script automates the installation and configuration of a LAMP stack (Linux, Apache, MySQL, PHP) along with Matomo analytics on an Ubuntu server.

## Features

- **SSH Configuration**: Enables root login with a password.
- **Apache Setup**: Installs Apache and configures it to prioritize PHP files (e.g., `index.php`).
- **MySQL Installation**: Installs MySQL, sets up a database, and configures a secure root password.
- **PHP Installation**: Installs PHP and required extensions for Matomo.
- **Virtual Host Creation**: Prompts for a hostname and sets up a corresponding Apache virtual host.
- **Git and Matomo**: Installs Git, clones Matomo, and configures it in the web server directory.
- **Database Configuration**: Creates a Matomo database and user with secure credentials.
- **No-IP Client**: Installs and configures the No-IP dynamic DNS client.
- **Output Details**: Displays essential information at the end, including MySQL root password, Matomo admin credentials, and web server URLs.

## Prerequisites

- An Ubuntu server with root or sudo privileges.
- A valid hostname or domain (optional but recommended).

## Usage Instructions

### 1. Save the Script
Save the script to a file, e.g., `lamp_matomo_setup.sh`:
```bash
nano lamp_matomo_setup.sh
```
Paste the script content and save the file.

### 2. Make the Script Executable
Set the necessary permissions:
```bash
chmod +x lamp_matomo_setup.sh
```

### 3. Run the Script
Execute the script with superuser privileges:
```bash
sudo ./lamp_matomo_setup.sh
```

### 4. Follow the Prompts
The script will prompt for:
- Your hostname (e.g., `example.com`).
- Matomo admin email and username.

The script will automatically handle the remaining configuration steps.

## Output

At the end of the script, it will display:
- **MySQL Root Password**.
- **Matomo Admin Username, Email, and Password**.
- **Matomo URL** (e.g., `http://<your-server-ip>/matomo`).
- **Web Server URL** (e.g., `http://<your-server-ip>`).

Save this information securely.

## Testing the Installation

1. Open your browser and visit the provided URLs:
   - Verify PHP by visiting: `http://<your-server-ip>/index.php`.
   - Access the Matomo dashboard at: `http://<your-server-ip>/matomo`.
2. Log into the Matomo dashboard using the admin credentials displayed at the end of the script.

## Notes

- The script generates random passwords for security. Save the output for future reference.
- Ensure your server firewall allows HTTP (port 80) and SSH (port 22) traffic.
- DNS configuration is required for the hostname to work correctly (optional if using the server IP directly).

## Troubleshooting

If any step fails:

1. Check the logs for Apache, MySQL, or the script output.
2. Verify required services are running:
   ```bash
   sudo systemctl status apache2  # Check Apache
   sudo systemctl status mysql    # Check MySQL
   ```
3. Test PHP installation by visiting the `info.php` test page.

## License

This script is open-source and can be modified as needed. Use it at your own risk.
