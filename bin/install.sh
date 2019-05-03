#!/usr/bin/env bash

# Variables

RANDOM_MEDIA_PORTAL="https://gitlab.com/frozenfoxx/random-media-portal.git"

# Functions

# Logic

git clone ${RANDOM_MEDIA_PORTAL}
cp ../etc/dhcpd.conf /etc/dhcpd/