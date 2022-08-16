#!/bin/bash

# Variables
INTERFACE="eth0"
IP=$(ip address show $INTERFACE | awk '/inet / {print $2}' | sed 's/\/.*//' | tail -1)
GATEWAY_ID="gw01"
GATEWAY_EUI="0011223344556677"
USER_ID="admin"
FREQUENCY_PLAN="EU_863_870"
APP_ID="app01"

# Modify docker-compose.yml file
sed "s/GATEWAY_EUI: \".*\"/GATEWAY_EUI: \"$GATEWAY_EUI\"/g" -i docker-compose.yml
sed "s/TTS_DOMAIN: .*/TTS_DOMAIN: $IP/g" -i docker-compose.yml

# pull images
echo "------------------------------------"
echo "Pulling images"
echo "------------------------------------"
docker compose pull

# run
echo "------------------------------------"
echo "Running services"
echo "------------------------------------"
docker compose up -d

# wait 30 seconds
echo "Waiting for services to boot up"
sleep 30

echo "------------------------------------"
echo "Configuring stack"
echo "------------------------------------"

# create gateway
docker exec -it stack ttn-lw-cli gateways create $GATEWAY_ID --user-id $USER_ID --frequency-plan-id $FREQUENCY_PLAN --gateway-eui $GATEWAY_EUI --enforce-duty-cycle &>/dev/null
if [[ $? -ne 0 ]]; then
    echo "ERROR: Could not create gateway!!"
    exit
fi

# create application
docker exec -it stack ttn-lw-cli applications create $APP_ID --user-id $USER_ID &>/dev/null
if [[ $? -ne 0 ]]; then
    echo "ERROR: Could not create application!!"
    exit
fi

# Output
echo ""
echo "------------------------------------"
echo "Configuration"
echo "------------------------------------"
echo "Stack URL: https://$IP/ (admin/changeme)"
echo "TagoCore URL: http://$IP:9888/"
echo "------------------------------------"
