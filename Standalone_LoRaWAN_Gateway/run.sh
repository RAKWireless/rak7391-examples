#!/bin/bash

# ----------------------------
# Configuration
# ----------------------------

INTERFACE=${INTERFACE:-$(ip route | awk '/default/ {print $5}')}
GATEWAY_EUI=${GATEWAY_EUI:-$(ip link show $INTERFACE | awk '/ether/ {print $2}' | awk -F\: '{print $1$2$3"fffe"$4$5$6}' | tr '[a-z]' '[A-Z]')}
IP=${IP:-$(ip address show $INTERFACE | awk '/inet / {print $2}' | sed 's/\/.*//' | tail -1)}

COLOR_HEADER="\e[41m\e[97m" # white on red
COLOR_SUMMARY="\e[1;32m" # bold green on black
COLOR_ERROR="\e[31m" # red
COLOR_END="\e[0m"

# ----------------------------
# Tasks
# ----------------------------

# Modify docker-compose.yml file
echo -e "${COLOR_HEADER}[1] Configuring docker-compose.yml file${COLOR_END}"
sed "s/GATEWAY_EUI: \".*\"/GATEWAY_EUI: \"$GATEWAY_EUI\"/g" -i docker-compose.yml
sed "s/TTS_DOMAIN: .*/TTS_DOMAIN: $IP/g" -i docker-compose.yml

echo -e "${COLOR_HEADER}[2] Pulling remote images (it may take a while the first time)${COLOR_END}"
docker compose pull -q

echo -e "${COLOR_HEADER}[3] Running services${COLOR_END}"
docker compose up -d

echo -e "${COLOR_SUMMARY}"
echo "---------------------------------------------------------------------"
echo "Gateway EUI  : $GATEWAY_EUI"
echo "Stack URL    : https://$IP/       (admin/changeme)"
echo "Node-RED URL : http://$IP:1880/"
echo "Grafana URL  : http://$IP:3000/   (admin/changeme)"
echo "---------------------------------------------------------------------"
echo -e "${COLOR_END}"
