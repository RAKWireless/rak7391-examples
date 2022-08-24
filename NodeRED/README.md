# NodeRED RAK-edition

The idea here is to have a docker-compose file that can start a Node-RED service with the curated RAK-edition of the Node-RED docker image. This curated image has all priviledges pre-configured, and also contains all the [RAKWireless/node-red-nodes](https://github.com/RAKWireless/node-red-nodes) preinstalled.

The RAK-edition of the Node-RED image is based on [nodered/node-red:3.0.2](https://hub.docker.com/layers/node-red/nodered/node-red/3.0.2/images/sha256-bb0fc3d02485100dbf26506a252ee53df1cacaba409ad6c03a131c69c5bf74c4?context=explore), for the latested change in Node-RED version 3.0, please check the [offical release notes](https://nodered.org/blog/2022/07/14/version-3-0-released).

 

### Requirements

#### Hardware

The RAK-edition of the Node-RED image is tailored for RAK7391with a Raspberry Pi CM4. If you need to run this image on a Raspberry Pi 4B or other platforms, please make sure you modify the docker-compose file.

#### Software

We prepared two ways for you to star the Node-RED service, one is through docker-compose, and the other one is through Portainer. No matter which way you perfer, you need to make sure you have docker installed on the OS first. You can find the detailed installation guide based on your linux distributions here: [Install Docker Engine | Docker Documentation](https://docs.docker.com/engine/install/).

If you are going to run this project directly using docker compose (not using Portainer), then you will need to install docker compose. Installing docker-compose is strongly recommended. This is pretty straight forward, please check the official documentions:[Install Docker Compose | Docker Documentation](https://docs.docker.com/compose/install/).

You can also use Portainer to start the service, please check this repository for further information: [GitHub - RAKWireless/portainer-templates: Curated list of services to deploy on a RAK WisGate Developer Gateway using Portainer](https://github.com/RAKWireless/portainer-templates). One thing to notice is that the Node-RED service defined in the Portainer template is not for Raspberry Pi 4B, unless you modify the stack file defined in the template. For Raspberry Pi 4B users, we recommand you to use docker compose to start the service.



### Deploy the code

Make sure you have docker compose installed, you should be able to check the instalation is alright by testing:

```shell
rak@rakpios:~ $ docker compose version
Docker Compose version v2.6.0
```

If you are woring on the RAK7391, you can use the `docker-compose.yml` we provided below to start the Node-RED service:

```yml
version: '3.7'

services:

  nodered:
    image: sheng2216/nodered-docker:rak
#    build:
#      context: ./
#      dockerfile: Dockerfile
    container_name: NodeRed
    user: node-red
    group_add:
      - "997"
      - "998"
    restart: unless-stopped
    devices:
      - "/dev/gpiochip0:/dev/gpiochip0"
      - "/dev/i2c-1:/dev/i2c-1"
      - "/dev/ttyUSB0:/dev/ttyUSB0"
      - "/dev/ttyUSB1:/dev/ttyUSB1"
    volumes:
      - 'node-red-data:/data'
    ports:
      - "1880:1880"

volumes:
  node-red-data:
```

If you are working on a Raspberry Pi 4B, please use the following `docker-compose.yml` file. 

```yml
version: '3.7'


services:

  nodered:
    image: sheng2216/nodered-docker:rak
#    build:
#      context: ./
#      dockerfile: Dockerfile
    container_name: NodeRed
    user: node-red
    group_add:
      - "997"
      - "998"
    restart: 
    devices:
      - "/dev/gpiochip0:/dev/gpiochip0"
      - "/dev/i2c-1:/dev/i2c-1"
      - "/dev/ttyAMA0:/dev/ttyAMA0"
    volumes:
      - 'node-red-data:/data'
    ports:
      - "1880:1880"

volumes:
  node-red-data:
```

Once the docker-compose file is ready, make sure you are in the same directory, and use the following command to start the service:

```shell
rak@rakpios:~/rak7391-use-cases/NodeRED $ docker compose up
[+] Running 3/3
 ⠿ Network nodered_default         Created                                                                                                          0.1s
 ⠿ Volume "nodered_node-red-data"  Created                                                                                                          0.0s
 ⠿ Container NodeRed               Created                                                                                                          2.2s
Attaching to NodeRed
NodeRed  | 24 Aug 04:16:25 - [info] 
NodeRed  | 
NodeRed  | Welcome to Node-RED
NodeRed  | ===================
NodeRed  | 
NodeRed  | 24 Aug 04:16:25 - [info] Node-RED version: v3.0.2
NodeRed  | 24 Aug 04:16:25 - [info] Node.js  version: v16.16.0
NodeRed  | 24 Aug 04:16:25 - [info] Linux 5.15.44-v8+ arm64 LE
NodeRed  | 24 Aug 04:16:27 - [info] Loading palette nodes
NodeRed  | 24 Aug 04:16:30 - [info] Dashboard version 3.1.7 started at /ui
NodeRed  | 24 Aug 04:16:30 - [info] Settings file  : /data/settings.js
NodeRed  | 24 Aug 04:16:30 - [info] Context store  : 'default' [module=memory]
NodeRed  | 24 Aug 04:16:30 - [info] User directory : /data
NodeRed  | 24 Aug 04:16:30 - [warn] Projects disabled : editorTheme.projects.enabled=false
NodeRed  | 24 Aug 04:16:30 - [info] Flows file     : /data/flows.json
NodeRed  | 24 Aug 04:16:30 - [warn] 
NodeRed  | 
NodeRed  | ---------------------------------------------------------------------
NodeRed  | Your flow credentials file is encrypted using a system-generated key.
NodeRed  | 
NodeRed  | If the system-generated key is lost for any reason, your credentials
NodeRed  | file will not be recoverable, you will have to delete it and re-enter
NodeRed  | your credentials.
NodeRed  | 
NodeRed  | You should set your own key using the 'credentialSecret' option in
NodeRed  | your settings file. Node-RED will then re-encrypt your credentials
NodeRed  | file using your chosen key the next time you deploy a change.
NodeRed  | ---------------------------------------------------------------------
NodeRed  | 
NodeRed  | 24 Aug 04:16:30 - [info] Server now running at http://127.0.0.1:1880/
NodeRed  | 24 Aug 04:16:30 - [warn] Encrypted credentials not found
NodeRed  | 24 Aug 04:16:30 - [info] Starting flows
NodeRed  | 24 Aug 04:16:30 - [info] Started flows
:
```

Now you should be able to access Node-RED's web interface by browsing to `http://{host-ip}:1880 `

And you should see a list of Node-RED nodes developed by RAKWireless on the left side:

![](C:\Users\Sheng\AppData\Roaming\marktext\images\2022-08-24-12-24-09-image.png)

These nodes are designed to support Wisblock modules, but they should also be compatible with the chips integreted into the Wisblock modules, please check the list below:

| Node-RED node                                                                                                      | Wisblock module                                                                                                                                                       | chip integrated in                                                                                                                         |
|:------------------------------------------------------------------------------------------------------------------ |:---------------------------------------------------------------------------------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------------------------------------------------------ |
| [@rakwireless/adc121c021](https://github.com/RAKWireless/node-red-nodes/tree/master/node-red-contrib-adc121c021)   | [RAK12004](https://store.rakwireless.com/products/mq2-gas-sensor-module-rak12004)/[RAK12009](https://store.rakwireless.com/products/wisblock-mq3-gas-sensor-rak12009) | [Texas Instruments ADC121C021](https://www.ti.com/product/ADC121C021)                                                                      |
| [@rakwireless/ads7830](https://github.com/RAKWireless/node-red-nodes/tree/master/node-red-contrib-ads7830)         | [RAK16001](https://store.rakwireless.com/products/rak16001-wisblock-adc-module)                                                                                       | [Texas Instruments ADS7830](https://www.ti.com/product/ADS7830)                                                                            |
| [@rakwireless/linbus](https://github.com/RAKWireless/node-red-nodes/tree/master/node-red-contrib-linbus)           | [RAK13005](https://store.rakwireless.com/products/lin-bus-module-rak13005)                                                                                            | [Infineon TLE7259-3](https://www.infineon.com/cms/en/product/transceivers/automotive-transceiver/automotive-lin-transceivers/tle7259-3ge/) |
| [@rakwireless/lps2x](https://github.com/RAKWireless/node-red-nodes/tree/master/node-red-contrib-lps2x)             | [RAK1902](https://store.rakwireless.com/products/rak1902-kps22hb-barometric-pressure-sensor)                                                                          | [STMicroelectronics LPS22HB](https://www.st.com/en/mems-and-sensors/lps22hb.html)                                                          |
| [@rakwireless/ltr-390uv](https://github.com/RAKWireless/node-red-nodes/tree/master/node-red-contrib-ltr-390uv)     | [RAK12019](https://store.rakwireless.com/products/rak12019-wisblock-uv-sensor)                                                                                        | [Lite-On LTR-390UV-01](https://www.mouser.com/ProductDetail/Lite-On/LTR-390UV-01?qs=g5ciJ0jwZaECcUd5i6p7%252Bg%3D%3D)                      |
| [@rakwireless/mcp-pcf-aio](https://github.com/RAKWireless/node-red-nodes/tree/master/node-red-contrib-mcp-pcf-aio) | [RAK14003](https://store.rakwireless.com/products/wisblock-led-bar-module-rak14003)                                                                                   | [Microchip MCP23017](https://www.microchip.com/en-us/product/mcp23017)                                                                     |
| [@rakwireless/opt3001](https://github.com/RAKWireless/node-red-nodes/tree/master/node-red-contrib-opt3001)         | [RAK1903](https://store.rakwireless.com/products/rak1903-opt3001dnpr-ambient-light-sensor)                                                                            | [Texas Instruments OPT3001](https://www.ti.com/product/OPT3001)                                                                            |
| [@rakwireless/pi4ioe5v](https://github.com/RAKWireless/node-red-nodes/tree/master/node-red-contrib-pi4ioe5v)       | /                                                                                                                                                                     | [PI4IOE5V9521](https://www.digikey.at/htmldatasheets/production/2415678/0/0/1/pi4ioe5v9521.html)                                           |
| [@rakwireless/pn532-i2c](https://github.com/RAKWireless/node-red-nodes/tree/master/node-red-contrib-pn532-i2c)     | [RAK13600](https://store.rakwireless.com/products/rak13600-wisblock-nfc-reader)                                                                                       | [NXP PN532](https://www.nxp.com/docs/en/nxp/data-sheets/PN532_C1.pdf)                                                                      |
| [@rakwireless/shtc3](https://github.com/RAKWireless/node-red-nodes/tree/master/node-red-contrib-shtc3)             | [RAK1901](https://store.rakwireless.com/products/rak1901-shtc3-temperature-humidity-sensor)                                                                           | [Sensirion SHTC3](https://sensirion.com/products/catalog/SHTC3/)                                                                           |


