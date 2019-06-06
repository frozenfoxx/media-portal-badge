# Raspberry Pi Deployment

This directory contains scripts and tools intended to ease deployment onto a Raspberry Pi. Follow these directions to get this working on any Raspberry Pi with onboard WiFi.

# Requirements

* [BalenaEtcher](https://www.balena.io/etcher/).
* A Linux system.
* `whiptail`
* Some videos, images, and/or audio files you wish to deploy.
* A MicroSD card.
* A Raspberry Pi with onboard WiFi.
* A local WiFi network.
* An SSH key.

# Deployment

* Download a recent image of Raspbian Lite [here](https://downloads.raspberrypi.org/raspbian_lite_latest).
* Open Etcher and flash the MicroSD card with Raspbian.
* Unplug, then replug in the card (this is due to automounting under `/media` not always being correct).
* Ensure that all supported file types you wish to deploy to the system are copied into `./data`. These will be synchronized over to the MicroSD card.
* Run `deploy.sh`. Follow the prompts, input the required information.
* Unplug, insert in the Raspberry Pi, power on.
* When booted, execute `ssh -i ~/.ssh/[Private Key] pi@[Hostname]`.
* From there you will likely wish to update the password for the `pi` user as well as update the keymap if UK is not appropriate for you.
* Become `root` (`sudo su -` will suffice).
* Run the installer as usual (`cd /home/pi/media-portal-badge/bin/ && ./install.sh`)