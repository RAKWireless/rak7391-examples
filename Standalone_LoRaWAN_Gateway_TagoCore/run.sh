#!/bin/bash

# ----------------------------
# Configuration
# ----------------------------

INTERFACE=${INTERFACE:-$(ip route | awk '/default/ {print $5}')}
GATEWAY_EUI=${GATEWAY_EUI:-$(ip link show $INTERFACE | awk '/ether/ {print $2}' | awk -F\: '{print $1$2$3"fffe"$4$5$6}' | tr '[a-z]' '[A-Z]')}
IP=${IP:-$(ip address show $INTERFACE | awk '/inet / {print $2}' | sed 's/\/.*//' | tail -1)}
GATEWAY_ID=${GATEWAY_ID:-"gw01"}
FREQUENCY_PLAN=${FREQUENCY_PLAN:-"EU_863_870"}
USER_ID="admin"
STACK_CLI="docker exec stack ttn-lw-cli"
TAGOCORE_WEBHOOK_BASE_URL="http://tagocore:8000"
DEVICES_FILE=devices.csv

COLOR_HEADER="\e[41m\e[97m" # white on red
COLOR_SUMMARY="\e[1;32m" # bold green on black
COLOR_ERROR="\e[31m" # red
COLOR_END="\e[0m"

# ----------------------------
# Functions
# ----------------------------

create_gateway() {

    LOCAL_GATEWAY_ID=$1
    LOCAL_GATEWAY_EUI=$2

    # check if the gateway is already created
    $STACK_CLI gateways get --gateway-eui $LOCAL_GATEWAY_EUI &>/dev/null

    # create gateway if it does not exist
    if [[ $? -eq 255 ]]
    then
        $STACK_CLI gateways create $LOCAL_GATEWAY_ID --user-id $USER_ID --frequency-plan-id $FREQUENCY_PLAN --gateway-eui $LOCAL_GATEWAY_EUI --enforce-duty-cycle &>/dev/null
        if [[ $? -ne 0 ]]; then
            echo -e "    ${COLOR_ERROR}ERROR: Could not create $LOCAL_GATEWAY_EUI gateway!!${COLOR_END}"
            exit
        fi
        echo "    Gateway $LOCAL_GATEWAY_EUI created!"
    else
        echo "    Gateway $LOCAL_GATEWAY_EUI already exists!"
    fi

}

create_application() {

    LOCAL_APP_ID=$1

    # check if application already exists
    $STACK_CLI applications get --application-id $LOCAL_APP_ID &>/dev/null

    # create application if doesn't exist
    if [[ $? -eq 255 ]]
    then
        $STACK_CLI applications create $LOCAL_APP_ID --user-id $USER_ID &>/dev/null
        if [[ $? -ne 0 ]]; then
            echo -e "    ${COLOR_ERROR}ERROR: Could not create $LOCAL_APP_ID application!!${COLOR_END}"
            exit
        fi
        echo "    Application $LOCAL_APP_ID created!"

        $STACK_CLI application webhooks set --application-id $LOCAL_APP_ID --webhook-id ${LOCAL_APP_ID}-tagocore --format json --base-url $TAGOCORE_WEBHOOK_BASE_URL --uplink-message.path "/uplink" &>/dev/null
        echo "    Webhook to TagoCore created!"

        $STACK_CLI application link set $LOCAL_APP_ID --default-formatters.up-formatter FORMATTER_CAYENNELPP &>/dev/null
        echo "    CayenneLPP configured as uplink payload formatter!"


    #else
        #echo "    Application $LOCAL_APP_ID already exists!"
    fi

}

create_device() {

    LOCAL_APP_ID=$1
    LOCAL_DEVICE_ID=$2
    LOCAL_DEVEUI=$3
    LOCAL_APPEUI=$4
    LOCAL_APPKEY=$5

    # check if device already exists
    $STACK_CLI device get --dev-eui $LOCAL_DEVEUI --device-id $LOCAL_DEVICE_ID --application-id $LOCAL_APP_ID &>/dev/null

    # create device if doesn't exist
    if [[ $? -eq 255 ]]
    then
        $STACK_CLI device create $LOCAL_APP_ID $LOCAL_DEVICE_ID --join-eui $LOCAL_APPEUI --dev-eui $LOCAL_DEVEUI --root-keys.app-key.key $LOCAL_APPKEY --frequency-plan-id $FREQUENCY_PLAN --lorawan-version 1.0.3 --lorawan-phy-version 1.0.3-a &>/dev/null
        if [[ $? -ne 0 ]]; then
            echo -e "    ${COLOR_ERROR}ERROR: Could not create $LOCAL_DEVICE_ID device!!${COLOR_END}"
            exit
        fi
        echo "    Device $LOCAL_DEVICE_ID created!"
    else
        echo "    Device $LOCAL_DEVICE_ID already exists!"
    fi



}

# ----------------------------
# Tasks
# ----------------------------

run() {

    # Modify docker-compose.yml file
    echo -e "${COLOR_HEADER}[1] Configuring docker-compose.yml file${COLOR_END}"
    sed "s/GATEWAY_EUI: \".*\"/GATEWAY_EUI: \"$GATEWAY_EUI\"/g" -i docker-compose.yml
    sed "s/TTS_DOMAIN: .*/TTS_DOMAIN: $IP/g" -i docker-compose.yml
    sed "s/SERVER_HOST: .*/SERVER_HOST: $IP/g" -i docker-compose.yml

    echo -e "${COLOR_HEADER}[2] Pulling remote images (it may take a while the first time)${COLOR_END}"
    docker compose pull

    echo -e "${COLOR_HEADER}[3] Building local images (give it also a minute to finish)${COLOR_END}"
    docker compose build

    echo -e "${COLOR_HEADER}[4] Running services${COLOR_END}"
    docker compose up -d

    echo -e "${COLOR_SUMMARY}"
    echo "---------------------------------------------------------------------"
    echo "Summary"
    echo "---------------------------------------------------------------------"
    echo "Stack URL:    https://$IP/       (admin/changeme)"
    echo "TagoCore URL: http://$IP:9888/"
    echo "---------------------------------------------------------------------"
    echo "Once the stack service is up and running, "
    echo "execute \"./run.sh populate\" to load the default config on TTS"
    echo "---------------------------------------------------------------------"
    echo -e "${COLOR_END}"

}

populate() {

    echo -e "${COLOR_HEADER}[1] Create Gateway${COLOR_END}"
    create_gateway $GATEWAY_ID $GATEWAY_EUI

    if [ -f "$DEVICES_FILE" ]
    then
        echo -e "${COLOR_HEADER}[2] Create Apps & Devices${COLOR_END}"
        while IFS=, read -r APP_ID DEVICE_ID DEVEUI APPEUI APPKEY
        do
            create_application $APP_ID
            create_device $APP_ID $DEVICE_ID $DEVEUI $APPEUI $APPKEY
        done < $DEVICES_FILE
    fi

}

# ----------------------------
# Dispatcher
# ----------------------------

if [[ $1 == "populate" ]]
then
    populate
else
    run
fi
