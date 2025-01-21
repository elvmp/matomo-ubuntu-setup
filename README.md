# matomo-ubuntu-setup
LAMP and Matomo Setup Script

This script automates the process of setting up a LAMP stack (Linux, Apache, MySQL, PHP) along with Matomo analytics on an Ubuntu server.

Features

Enables root login over SSH with a password.

Installs and configures Apache web server.

Installs MySQL server and sets up a random root password.

Installs PHP and all necessary extensions for Matomo.

Configures Apache to prioritize PHP files (e.g., index.php).

Prompts the user for a hostname and sets up a corresponding virtual host.

Creates a phpinfo() test page to verify PHP installation.

Installs Git and clones Matomo into the web server directory.

Sets up a Matomo database and admin user with random credentials.

Displays critical information at the end, including:

- MySQL root password.

- Matomo admin username, email, and password.

- URLs for the web server and Matomo.

Prerequisites

- An Ubuntu server with root or sudo privileges.

- A valid hostname or domain (optional, but recommended).

Usage Instructions

1. Save the Script

Save the script to a file, e.g., lamp_matomo_setup.sh:

nano lamp_matomo_setup.sh

Paste the script content and save the file.

2. Make the Script Executable

Set the necessary permissions:

chmod +x lamp_matomo_setup.sh

3. Run the Script

Execute the script with superuser privileges:

sudo ./lamp_matomo_setup.sh

4. Follow the Prompts

During execution, the script will ask for:

Your hostname (e.g., example.com).

Matomo admin email.

Matomo admin username.

The script will handle everything else, including setting up the MySQL database, installing required packages, and configuring the web server.

Output

At the end of the script, it will display:

MySQL root password.

Matomo admin username, email, and password.

Matomo URL (e.g., http://<your-server-ip>/matomo).

Web server URL (e.g., http://<your-server-ip>).

Use this information to log into Matomo and verify your setup.

Testing the Installation

Open your browser and visit the URLs provided at the end of the script.

Verify PHP is working by visiting http://<your-server-ip>/index.php.

Access the Matomo dashboard at http://<your-server-ip>/matomo.

Notes

The script generates random passwords for security. Make sure to save the output for future reference.

Ensure your server firewall allows HTTP (port 80) and SSH (port 22) traffic.

DNS configuration is required for the hostname to work correctly (optional if using the server IP directly).

Troubleshooting

If any step fails:

Check the logs for Apache, MySQL, or the script output.

Verify required services are running:

Apache: sudo systemctl status apache2

MySQL: sudo systemctl status mysql

Test PHP installation by visiting the info.php test page.

License

This script is open-source and can be modified as needed. Use it at your own risk
