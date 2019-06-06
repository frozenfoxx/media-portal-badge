#!/usr/bin/env bash

# Variables
PLATFORM=$(uname -s)
HOSTNAME=$(hostname)
MEDIA_DIR=${MEDIA_DIR:-"/data"}
MEDIA_MODE=${MEDIA_MODE:-"video"}
RANDOM_MEDIA_PORTAL=${RANDOM_MEDIA_PORTAL:-"https://gitlab.com/frozenfoxx/random-media-portal.git"}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
LOG_PATH=${LOG_PATH:-"/var/log"}
STD_LOG='media_portal_badge_install.log'
STD_LOG_ARG=''

# Functions

# Check if the script is running as root
check_root()
{
  if [[ $EUID -ne 0 ]]; then
    eval echo "[!] This script must be run as root." ${STD_LOG_ARG}
    exit 1
  fi
}

# Configure dhcpcd
configure_dhcpcd()
{
  eval echo "[+] Configuring dhcpcd..." ${STD_LOG_ARG}

  # Backup original config and install our own
  mv /etc/dhcpcd.conf /etc/dhcpcd.conf.orig
  cp ${SCRIPT_DIR}/../etc/dhcpcd.conf /etc/dhcpcd.conf

  # Restart networking to take effect
  # service dhcpcd restart
  # ip link set wlan0 down
  # ip link set wlan0 up
}

# Set up and configure dnsmasq
configure_dnsmasq()
{
  eval echo "[+] Configuring dnsmasq..." ${STD_LOG_ARG}

  # Backup original config and install our own
  mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
  cp ${SCRIPT_DIR}/../etc/dnsmasq.conf /etc/dnsmasq.conf

  # Enable the service at boot
  systemctl enable dnsmasq
}

# Set up and configure hostapd
configure_hostapd()
{
  eval echo "[+] Configuring hostapd..." ${STD_LOG_ARG}

  # Backup original config and install our own
  if [[ -f /etc/hostapd/hostapd.conf ]]; then
    mv /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.orig
  fi
  
  cp ${SCRIPT_DIR}/../etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf
  chmod 640 /etc/hostapd/hostapd.conf

  # Specify a default config for hostapd
  rm /etc/default/hostapd
  cp ${SCRIPT_DIR}/../etc/default/hostapd /etc/default/hostapd

  # Enable the service at boot
  systemctl unmask hostapd
  systemctl enable hostapd
}

# Set up the network devices
configure_network()
{
  eval echo "[+] Configuring network devices..." ${STD_LOG_ARG}

  cp ${SCRIPT_DIR}/../etc/network/interfaces.d/wlan0 /etc/network/interfaces.d/wlan0

  eval echo "[+] Updating hosts..." ${STD_LOG_ARG}
  
  sed -i '/^192\.168\.4\.1.*$/d' /etc/hosts
  echo "192.168.4.1 ${HOSTNAME}" >> /etc/hosts
}

# Set up and configure nginx
configure_nginx()
{
  eval echo "[+] Generating self-signed SSL certificate..." ${STD_LOG_ARG}
  cp ${SCRIPT_DIR}/../root/localhost.openssl.conf /root/

  # Create the certificate and key
  cd /root
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout localhost.key -out localhost.crt -config localhost.openssl.conf

  # Move those to the SSL directory
  mv localhost.crt /etc/ssl/certs/
  mv localhost.key /etc/ssl/private/localhost.key

  # Change back to the script directory
  cd ${SCRIPT_DIR}

  eval echo "[+] Configuring nginx..." ${STD_LOG_ARG}

  # Copy in our site config(s)
  cp ${SCRIPT_DIR}/../etc/nginx/sites-available/*.conf /etc/nginx/sites-available/

  # Enable the new site
  ln -s /etc/nginx/sites-available/localhost.conf /etc/nginx/sites-enabled/localhost.conf

  # Disable the default welcome
  if [[ -f /etc/nginx/sites-enabled/default ]]; then
    rm /etc/nginx/sites-enabled/default
  fi

  # Start the service
  systemctl start nginx
  systemctl enable nginx
}

# Enable IPv4 forwarding
enable_forwarding()
{
  eval echo "[+] Enabling IPv4 forwarding..." ${STD_LOG_ARG}

  if [[ $(grep -e '^#net\.ipv4\.ip_forward=1$' /etc/sysctl.conf) ]]; then
    sed -i '/^#net\.ipv4\.ip_forward=1$/s/^#//' /etc/sysctl.conf
  else
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
  fi

  eval echo "[+] Enabling localnet routing..." ${STD_LOG_ARG}
  if [[ $(grep -e '^#net\.ipv4\.conf\.all\.route_localnet=1$' /etc/sysctl.conf) ]] ; then
    sed -i '/^#net\.ipv4\.conf\.all\.route_localnet=1$/s/^#//' /etc/sysctl.conf
  else
    echo net.ipv4.conf.all.route_localnet=1 >> /etc/sysctl.conf
  fi
}

# Output final information about the installation
finalize_message()
{
  eval echo "[+] The media-portal-badge stack is now installed and ready to go." ${STD_LOG_ARG}
  eval echo "[+] To alter which media to serve check these variables in the /etc/systemd/random-media-portal.env file" ${STD_LOG_ARG}
  eval echo "[+]     MEDIA_DIR              path containing media for the portal" ${STD_LOG_ARG}
  eval echo "[+]     MEDIA_MODE             display mode for the portal" ${STD_LOG_ARG}
}

# Install dependencies
install_dependencies()
{
  eval echo "[+] Installing core toolchain..." ${STD_LOG_ARG}

  # Install core tools
  apt-get update
  apt-get install -y \
    git \
    dnsmasq \
    hostapd \
    nginx \
    ruby

  # Install gem dependencies
  gem install bundler

  # Create directory for holding media if it doesn't exist already
  mkdir -p /data
}

# Install the random-media-portal
install_random_media_portal()
{
  eval echo "[+] Installing the random-media-portal..." ${STD_LOG_ARG}

  # Change to a directory for optional software
  cd /opt
  
  # Pull a copy of the latest random-media-portal
  git clone ${RANDOM_MEDIA_PORTAL} random-media-portal
  cd random-media-portal
  bundle install --system

  # Install the service file
  cp ${SCRIPT_DIR}/../etc/systemd/system/random-media-portal.service /etc/systemd/system/
  cp ${SCRIPT_DIR}/../etc/systemd/random-media-portal.env /etc/systemd/

  # FIXME: substitute environment variables

  # Reload the service
  systemctl daemon-reload
  systemctl enable random-media-portal.service

  # Change back to the script directory
  cd ${SCRIPT_DIR}
}

# Upgrade the system
upgrade_system()
{
  eval echo "[+] Upgrading system..." ${STD_LOG_ARG}

  apt-get update
  apt-get upgrade -y
  apt-get dist-upgrade -y

  eval echo "[+] Reboot may be necessary." ${STD_LOG_ARG}
}

# Set logging on
set_logging()
{
  echo "[+] Running with logging option..."
  STD_LOG_ARG=">>${LOG_PATH}/${STD_LOG}"
}

# Display usage information
usage()
{
  echo "Usage: [Environment Variables] ./install.sh [-hL]"
  echo "  Environment Variables:"
  echo "    LOG_PATH               path for logs (default: '/var/log')"
  echo "    RANDOM_MEDIA_PORTAL    HTTP clone target for the random-media-portal (default: https://gitlab.com/frozenfoxx/random-media-portal.git)"
  echo "  Options:"
  echo "    -h | --help            display this usage information"
  echo "    -L | --Log             enable logging (target: '[LOG_PATH]/media_portal_badge_install.log')"
}

# Logic

# Argument parsing
while [ "$1" != "" ]; do
  case $1 in
    -L | --Log )  set_logging
                  ;;
    -h | --help ) usage
                  exit 0
  esac
  shift
done

check_root
upgrade_system
install_dependencies
install_random_media_portal
configure_nginx
configure_network
configure_dhcpcd
configure_hostapd
enable_forwarding
configure_dnsmasq
finalize_message