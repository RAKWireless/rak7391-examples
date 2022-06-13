#!/bin/bash

CONFIG_FILE=$1
USER_ID=admin

# login
#docker exec -it stack ttn-lw-cli login --callback=false

# parse json file to add gateway
gw_index=0
while true;do
    gw=`jq -r --arg index $gw_index '.gateways[$index|tonumber]' $CONFIG_FILE | grep -w null`
    if [ $? -eq 0 ]; then
        break
    else
        gateway_id=`jq -r --arg index $gw_index '.gateways[$index|tonumber]["gateway-id"]' $CONFIG_FILE`
        frequency_plan_id=`jq -r --arg index $gw_index '.gateways[$index|tonumber]["frequency-plan-id"]' $CONFIG_FILE`
        gateway_eui=`jq -r --arg index $gw_index '.gateways[$index|tonumber]["gateway-eui"]' $CONFIG_FILE`

        #add gateway
        ret=`docker exec -it stack ttn-lw-cli gateways list | grep $gateway_eui`
        if [ $? -eq 1 ];then
            ret=`docker exec -it stack ttn-lw-cli gateways get $gateway_id | grep -E ^error:.*`
            if [ $? -eq 0 ];then
                ret=`docker exec -it stack ttn-lw-cli gateways get $gateway_id | grep -E ^error:.*gateway_not_found`
                if [ $? -eq 0 ];then
                    echo "Create new gateway."
                    docker exec -it stack ttn-lw-cli gateways create $gateway_id \
                        --user-id $USER_ID --frequency-plan-id $frequency_plan_id \
                        --gateway-eui $gateway_eui --enforce-duty-cycle
                else
                    echo "Error occured when creating gateway."
                fi
            else
                echo "Gateways with same gateway id[$gateway_id] already existed."
            fi
        else
            echo "Gateways with gateway_eui[$gateway_eui] already existed."
        fi
        gw_index=$[$gw_index+1]
    fi
done


# parse json file to add applications and devices
app_index=0
while true;do
    app=`jq -r --arg app_index $app_index '.applications[$app_index|tonumber]' $CONFIG_FILE | grep -w null`
    if [ $? -eq 0 ]; then
        break
    else
        application_id=`jq -r --arg app_index $app_index \
            '.applications[$app_index|tonumber]["application-id"]' $CONFIG_FILE`
        ret=`docker exec -it stack ttn-lw-cli applications get $application_id | grep -E ^error:.*`
        if [ $? -eq 0 ];then
            ret=`docker exec -it stack ttn-lw-cli applications get $application_id | grep -E ^error:.*application_not_found`
            if [ $? -eq 0 ];then
                echo "Create new application."
                docker exec -it stack ttn-lw-cli applications create $application_id --user-id $USER_ID
                # set uplink format
                docker exec -it stack ttn-lw-cli applications link set $application_id --default-formatters.up-formatter FORMATTER_CAYENNELPP
                # generate api key
                #docker exec -it stack ttn-lw-cli app api-keys create $application_id --right-application-link
                # for mqtt
                docker exec -it stack ttn-lw-cli app api-keys create $application_id \
                    --right-application-traffic-read --right-application-traffic-down-write
            else
                echo "Error occured when creating application."
            fi
        else
            echo "Application with application id[$application_id] already existed."
        fi

        # add devices
        dev_index=0
        while true;do
            dev=`jq -r --arg app_index $app_index --arg dev_index $dev_index \
                '.applications[$app_index|tonumber]["devices"][$dev_index|tonumber]' $CONFIG_FILE | grep -w null`
            if [ $? -eq 0 ]; then
                break
            else
                device_id=`jq -r --arg app_index $app_index --arg dev_index $dev_index \
                    '.applications[$app_index|tonumber]["devices"][$dev_index|tonumber]["device-id"]' $CONFIG_FILE`
                frequency_plan_id=`jq -r --arg app_index $app_index --arg dev_index $dev_index \
                    '.applications[$app_index|tonumber]["devices"][$dev_index|tonumber]["frequency-plan-id"]' $CONFIG_FILE`
                dev_eui=`jq -r --arg app_index $app_index --arg dev_index $dev_index \
                    '.applications[$app_index|tonumber]["devices"][$dev_index|tonumber]["dev-eui"]' $CONFIG_FILE`
                app_eui=`jq -r --arg app_index $app_index --arg dev_index $dev_index \
                    '.applications[$app_index|tonumber]["devices"][$dev_index|tonumber]["app-eui"]' $CONFIG_FILE`
                app_key=`jq -r --arg app_index $app_index --arg dev_index $dev_index \
                    '.applications[$app_index|tonumber]["devices"][$dev_index|tonumber]["app-key"]' $CONFIG_FILE`

                ret=`docker exec -it stack ttn-lw-cli end-devices list $application_id | grep $dev_eui`
                if [ $? -eq 1 ];then
                    ret=`docker exec -it stack ttn-lw-cli end-devices get $application_id $device_id | grep -E ^error:.*`
                    if [ $? -eq 0 ];then
                        ret=`docker exec -it stack ttn-lw-cli end-devices get $application_id $device_id | grep -E ^error:.*end_device_not_found`
                        if [ $? -eq 0 ];then
                            echo 'Create new end device.'
                            docker exec -it stack ttn-lw-cli end-devices create $application_id $device_id \
                                --dev-eui $dev_eui --join-eui $app_eui --frequency-plan-id $frequency_plan_id \
                                --root-keys.app-key.key $app_key --lorawan_version MAC_V1_0_3 --lorawan_phy_version PHY_V1_0_3_REV_A \
                                --supports-join --supports-class-b --supports-class-c
                                #--formatters.up-formatter FORMATTER_CAYENNELPP
                        else
                            echo "Error occured when creating end device."
                        fi
                    else
                        echo "End device with same device id[$device_id] existed."
                    fi
                else
                    echo "End device with dev eui[$dev_eui] already existed."
                fi
                dev_index=$[$dev_index+1]
            fi
        done
        app_index=$[$app_index+1]
    fi
done
