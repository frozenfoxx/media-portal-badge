#!/usr/bin/env bash

# Variables
PLATFORM=$(uname -s)
MYUSER=$(whoami)
RANDOM_MEDIA_PORTAL=${RANDOM_MEDIA_PORTAL:-"https://gitlab.com/frozenfoxx/random-media-portal.git"}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
LOG_PATH=${LOG_PATH:-"${SCRIPT_DIR}"}
STD_LOG='media_portal_badge_deployment.log'
STD_LOG_ARG=''

# Functions

# Configure the hostname
configure_hostname()
{
  DEPLOY_HOSTNAME=$(whiptail --title "Hostname" --inputbox "Input a hostname" 10 40 3>&1 1>&2 2>&3)

  # Check for if the user cancelled
  if [[ ${DEPLOY_HOSTNAME} == '' ]]; then
    eval echo "[!] No hostname entered, terminating..." ${STD_LOG_ARG}
    exit 1
  fi

  eval echo "[+] Setting hostname..." ${STD_LOG_ARG}
  sudo sed -i "s/raspberrypi/${DEPLOY_HOSTNAME}/g" /media/${MYUSER}/rootfs/etc/hosts
  sudo sed -i "s/raspberrypi/${DEPLOY_HOSTNAME}/g" /media/${MYUSER}/rootfs/etc/hostname
  echo ${DEPLOY_HOSTNAME} > /media/${MYUSER}/boot/hostnames
}

# Ensure SSH is enabled at boot
configure_ssh()
{
  eval echo "[+] Enabling SSH at boot..." ${STD_LOG_ARG}
  touch /media/${MYUSER}/boot/ssh
}

# Configure user
configure_user()
{
  AUTHORIZED_KEYS=$(whiptail --title "Authorized Keys for SSH" --inputbox "Input the fully-qualified path to a public SSH key to use for connecting to the system.\n\nFound the following:\n\n$(ls ~/.ssh/*.pub)" 30 55 3>&1 1>&2 2>&3)

  # Check for if the user cancelled
  if [[ ${AUTHORIZED_KEYS} == '' ]]; then
    eval echo "[!] No public key entered, terminating..." ${STD_LOG_ARG}
    exit 1
  fi

  # Check to see if the file exists
  if ! [[ -f ${AUTHORIZED_KEYS} ]]; then
    eval echo "[!] The provided key location doesn't exist, terminating..." ${STD_LOG_ARG}
    exit 1
  fi

  eval echo "[+] Copying over the provided public key for the pi user..." ${STD_LOG_ARG}
  mkdir /media/${MYUSER}/rootfs/home/pi/.ssh
  chmod 700 /media/${MYUSER}/rootfs/home/pi/.ssh
  cp ${AUTHORIZED_KEYS} /media/${MYUSER}/rootfs/home/pi/.ssh/authorized_keys
}

# Set up WiFi for the inital connection
configure_wifi()
{
  DEPLOY_SSID=$(whiptail --title "Local Network SSID" --inputbox "Input the SSID of your local WiFi network" 10 40 3>&1 1>&2 2>&3)
  DEPLOY_PSK=$(whiptail --title "Local Network Passphrase" --inputbox "Input the local WiFi network's passphrase" 10 40 3>&1 1>&2 2>&3)

  # Check for if the user cancelled
  if [[ ${DEPLOY_SSID} == '' ]]; then
    eval echo "[!] No local network SSID entered, terminating..." ${STD_LOG_ARG}
    exit 1
  fi

  cp ./wpa_supplicant.conf /media/${MYUSER}/boot/wpa_supplicant.conf
  sed -i "s/DEPLOY_SSID/${DEPLOY_SSID}/g" /media/${MYUSER}/boot/wpa_supplicant.conf
  sed -i "s/DEPLOY_PSK/${DEPLOY_PSK}/g" /media/${MYUSER}/boot/wpa_supplicant.conf
}

# Copy over data files
deploy_data()
{
  eval echo "[+] Copying over data..." ${STD_LOG_ARG}

  sudo mkdir /media/${MYUSER}/rootfs/data
  sudo cp data/* /media/${MYUSER}/rootfs/data/

  eval echo "[+] Syncing. This might take a minute..." ${STD_LOG_ARG}
  sync
}

# Clone the media-portal-badge code onto the system
deploy_media_portal_badge()
{
  eval echo "[+] Cloning latest random-media-portal..." ${STD_LOG_ARG}

  git clone ${RANDOM_MEDIA_PORTAL} /media/${MYUSER}/rootfs/home/pi/random-media-portal
}

# Show the user what must be done next
display_further_instructions()
{
  eval echo "[+] The media-portal-badge is now almost complete. To complete installation perform the following:" ${STD_LOG_ARG}
  eval echo "[+]   * Insert the microSD card into the Raspberry Pi." ${STD_LOG_ARG}
  eval echo "[+]   * Power on the Raspberry Pi." ${STD_LOG_ARG}
  eval echo "[+]   * ssh -i [path to private key] pi@[hostname].local" ${STD_LOG_ARG}
  eval echo "[+]   * (RPi) sudo su - " ${STD_LOG_ARG}
  eval echo "[+]   * (RPi) raspi-config" ${STD_LOG_ARG}
  eval echo "[+]   * (RPi) Update the keymap/locale (likely US)." ${STD_LOG_ARG}
  eval echo "[+]   * (RPi) Update the pi user's password." ${STD_LOG_ARG}
  eval echo "[+]   * (RPi) cd /home/pi/media-portal-badge/bin && ./install.sh" ${STD_LOG_ARG}
  eval echo "[+]   * After installation has completed reboot the Raspberry Pi." ${STD_LOG_ARG}
  eval echo "[+]   * With another device, connect to the SSID." ${STD_LOG_ARG}
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
  echo "Usage: [Environment Variables] ./deploy.sh [-hL]"
  echo "  Environment Variables:"
  echo "    LOG_PATH               path for logs (default: '.')"
  echo "    RANDOM_MEDIA_PORTAL    HTTP clone target for the random-media-portal (default: https://gitlab.com/frozenfoxx/random-media-portal.git)"
  echo "  Options:"
  echo "    -h | --help            display this usage information"
  echo "    -L | --Log             enable logging (target: '[LOG_PATH]/media_portal_badge_deployment.log')"
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

configure_user
configure_ssh
configure_wifi
configure_hostname
deploy_media_portal_badge
deploy_data
display_further_instructions