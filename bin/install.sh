#!/usr/bin/env bash

# Variables
PLATFORM=$(uname -s)
HOSTNAME=$(hostname)
MEDIA_DIR=${MEDIA_DIR:-"/data"}
MEDIA_MODE=${MEDIA_MODE:-"video"}
RANDOM_MEDIA_PORTAL=${RANDOM_MEDIA_PORTAL:-"https://gitlab.com/frozenfoxx/random-media-portal.git"}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
LOG_PATH=${LOG_PATH:-"/var/root/log"}
STD_LOG='media_portal_badge_install.log'
STD_LOG_ARG=''

# Functions

# Set up and configure nginx
configure_nginx()
{
  eval echo "[+] Configuring nginx..." ${STD_LOG_ARG}

  # Copy in our site config(s)
  cp ${SCRIPT_DIR}/../etc/nginx/*.conf /etc/nginx/conf.d/

  # Disable the default welcome
  mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.disabled

  # Start the service
  systemctl start nginx
  systemctl enable nginx
}

# Output final information about the installation
finalize_message()
{
  eval echo "[+] The media-portal-badge stack is now installed and ready to go." ${STD_LOG_ARG}
  eval echo "[+] To alter which media to serve check these variables in the /etc/systemd/system/random_media_portal.service file:" ${STD_LOG_ARG}
  eval echo "[+]     MEDIA_DIR              path containing media for the portal (default: '/data')" ${STD_LOG_ARG}
  eval echo "[+]     MEDIA_MODE             display mode for the portal (default: 'video')" ${STD_LOG_ARG}
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

  # Change back to the script directory
  cd ${SCRIPT_DIR}

  # Install the service file
  cp ${SCRIPT_DIR}/../etc/systemd/system/random_media_portal.service /etc/systemd/system/
  systemctl daemon-reload
  systemctl start random_media_portal.service
  systemctl enable random_media_portal.service

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
  echo "[+] Usage: [Environment Variables] ./install.sh [-hL]"
  echo "[+]   Environment Variables:"
  echo "[+]     LOG_PATH               path for logs (default: '/var/root/log')"
  echo "[+]     RANDOM_MEDIA_PORTAL    HTTP clone target for the random-media-portal (default: https://gitlab.com/frozenfoxx/random-media-portal.git)"
  echo "[+]   Options:"
  echo "[+]     -h | --help            display this usage information"
  echo "[+]     -L | --Log             enable logging (target: '[LOG_PATH]/media_portal_badge_install.log')"
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

upgrade_system
install_dependencies
install_random_media_portal
configure_nginx
finalize_message