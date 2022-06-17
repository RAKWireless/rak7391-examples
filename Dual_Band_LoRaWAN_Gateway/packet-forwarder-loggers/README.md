# LoRaWAN Packet Forwarder Loggers

This repository contains a set of parsers and loggers to monitor metrics from a LoraWAN Packet Forwarder running inside a Docker container. At the moment these parsers are compatible with the following docker images:

* [LoRa Basics™ Station for Docker](https://github.com/xoseperez/basicstation/)
* [LoRaWAN UDP Packet Forwarder Protocol for Docker](https://github.com/RAKWireless/udp-packet-forwarder)

## Parsers

Each of the projects above has its own parser:

* `basicstation.py` parses the LoRa Basics™ Station for Docker logs
* `legacy.py` parses the LoRaWAN UDP Packet Forwarder Protocol for Docker logs

Botj parsers output a JSON object for each message received in real time (for the UDP Packet Forwarder upon serial flush). The JSON object has the same format regardless of the parser. 

## Loggers

At the moment there are 4 loggers available. All of them instantiate a parser based on the PROTOCOL environment variable.

* `log2api.py`: aggregates the data received in buckets of the given size in seconds and exposes the data via an HTTP API
* `log2idb.py`: translates the output from the parser into a InfluxDB write query and sends it to a local or remote instance of InfluxDB
* `log2json.py`: aggregates the data received in buckets of the given size in seconds and dumps the current summary everytime a message is parsed
* `log2mqtt.py`: translates the output from the parser into a JSON or InfluxDB-compatible string and publishes it to a local or remote MQTT broker

## Examples

### Dependencies

The recommended way to run the parsers is by using a virtual environment. You can follow these steps.

```
sudo apt install python3-virtualenv
git clone https://github.com/xoseperez/packet-forwarder-loggers
cd packet-forwarder-loggers
virtualenv .env
source .env/bin/activate
pip install -r requirements.txt
```

### HTTP API

Expose metrics via an HTTP API:

```
# this will start monitoring a local container named `basicstation` and expose port 8888 for GET requests
> python -u log2api.py

# run this command on a separate terminal to check the output of the API (buckets are numbered in chronological order):
> curl -s http://127.0.0.1:8888/api/metrics 
{
  "bucket_count": 15, 
  "bucket_size": 60, 
  "buckets": {
    "0": {
      "rx": 2, 
      "tx": 0
    }, 
    "1": {
      "rx": 1, 
      "tx": 1
    }, 
    "5": {
      "rx": 1, 
      "tx": 1
    }, 
    "7": {
      "rx": 1, 
      "tx": 0
    }, 
    "8": {
      "rx": 1, 
      "tx": 0
    }, 
    "9": {
      "rx": 1, 
      "tx": 1
    }, 
    "10": {
      "rx": 1, 
      "tx": 0
    }, 
    "11": {
      "rx": 1, 
      "tx": 1
    }, 
    "13": {
      "rx": 0, 
      "tx": 0
    }
  }, 
  "totals": {
    "rx": 16, 
    "tx": 7
  }
}

```

### InfluxDB

Send messages to an InfluxDB server in the LAN:

```
> DB_HOST=192.168.42.10 DB_NAME=lorawan DB_MEASUREMENT=gw_metrics GATEWAY_ID=$(hostname) python -u log2idb.py
```

### JSON log

Log aggregated metrics from a legacy UDP packet forwarder to console:

```
> PROTOCOL=legacy CONTAINER_NAME=udp-packet-forwarder python -u log2json.py
{'totals': {'rx': 1, 'tx': 0}, 'buckets': {0: {'rx': 1, 'tx': 0}}, 'bucket_size': 60, 'bucket_count': 15}
{'totals': {'rx': 2, 'tx': 0}, 'buckets': {0: {'rx': 2, 'tx': 0}}, 'bucket_size': 60, 'bucket_count': 15}
{'totals': {'rx': 3, 'tx': 0}, 'buckets': {0: {'rx': 3, 'tx': 0}}, 'bucket_size': 60, 'bucket_count': 15}
{'totals': {'rx': 4, 'tx': 0}, 'buckets': {0: {'rx': 3, 'tx': 0}, 1: {'rx': 1, 'tx': 0}}, 'bucket_size': 60, 'bucket_count': 15}
...
```

### MQTT

Send messages to an MQTT broker:

```
# Start the logger on a terminal
> MQTT_HOST=192.168.42.10 python -u log2mqtt.py
# Switch to a different terminal to check messages in the broker
> mosquitto_sub -h 192.168.42.10 -t 'gateway/metrics'
{'type': 'rx', 'timestamp': 1653481174.637, 'frequency': 868.3, 'datarate': 5, 'snr': 14.0, 'rssi': -40, 'devaddr': '260BB4BE'}
{'type': 'rx', 'timestamp': 1653481216.979, 'frequency': 868.5, 'datarate': 0, 'snr': 7.5, 'rssi': -49, 'devaddr': '260B5F33'}
...
```

## Docker

You can run any of the parsers in a docker container. Check the `docker-compose.yml` file for an example on how to do it.

## Environment variables

These are the variables you can play with to configure the parsers and loggers.

|Name|Logger(s)|Description|Default|
|:--|:--|:--|:--|
|PROTOCOL|all|Parser to use, either `basicstation` or `legacy`|`basicstation`|
|CONTAINER_NAME|all|Name of the container to monitor its logs|`basicstation`|
|GATEWAY_ID|log2idb, log2mqtt|Gateway identification name|`my-gateway`|
|BUCKET_COUNT|log2api, log2json|Number of buckets to keep in memory and report|`15`|
|BUCKET_SIZE|log2api, log2json|Size of each bucket in seconds|`60`|
|DB_HOST|log2idb|InfluxDB host|`localhost`|
|DB_PORT|log2idb|InfluxDB port|`8086`|
|DB_USER|log2idb|InfluxDB username||
|DB_PASS|log2idb|InfluxDB password||
|DB_NAME|log2idb|InfluxDB database name|`gateways`|
|DB_MEASUREMENT|log2idb|InfluxDB measurement(table) name|`metrics`|
|MQTT_HOST|log2mqtt|MQTT broker host|`localhost`|
|MQTT_PORT|log2mqtt|MQTT broker port|`1883`|
|MQTT_USER|log2mqtt|MQTT broker username||
|MQTT_PASS|log2mqtt|MQTT broker password||
|MQTT_TOPIC|log2mqtt|MQTT topic to publish to|`gateway/metrics`|
|MQTT_DATA_FORMAT|log2mqtt|Format of the MQTT message, either `json` or `influx`|`json`|

## License

The contents of this repository are under BSD 3-Clause License.

Copyright (c) 2022 Xose Pérez <xose.perez@gmail.com>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. Neither the name of this project nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
