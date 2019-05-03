#!/usr/bin/env bash

# Variables
PLATFORM=$(uname -s)
HOSTNAME=$(hostname)
RANDOM_MEDIA_PORTAL=${RANDOM_MEDIA_PORTAL:-"https://gitlab.com/frozenfoxx/random-media-portal.git"}
LOG_PATH=${LOG_PATH:-"/var/root/log"}
STD_LOG='media_portal_badge_install.log'
STD_LOG_ARG=''

# Functions

# Install dependencies
install_dependencies()
{
  apt-get install -y \
    git \
    dnsmasq \
    hostapd \
    lighttpd \
    ruby
}

# Install the random-media-portal
install_random_media_portal()
{
  git clone ${RANDOM_MEDIA_PORTAL}
}

# Upgrade the system
upgrade_system()
{
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
  echo "[+] Usage: [Environment Variables] install.sh [-hL]"
  echo "[+]   Environment Variables:"
  echo "[+]     LOG_PATH               path for logs (default: '/var/root/log')"
  echo "[+]     RANDOM_MEDIA_PORTAL    HTTP clone target for the random-media-portal (default: https://gitlab.com/frozenfoxx/random-media-portal.git)"
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
