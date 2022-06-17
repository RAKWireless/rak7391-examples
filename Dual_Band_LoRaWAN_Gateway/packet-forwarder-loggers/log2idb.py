#!/usr/bin/env python

import os
import sys
import datetime
from influxdb import InfluxDBClient
from basicstation import parser as basicstation_parser
from legacy import parser as legacy_parser

PROTOCOL  = os.environ.get("PROTOCOL", "basicstation")

CONTAINER_NAME = os.environ.get("CONTAINER_NAME", "basicstation")
DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_PORT = os.environ.get("DB_PORT", 8086)
DB_USER = os.environ.get("DB_USER", "")
DB_PASS = os.environ.get("DB_PASS", "")
DB_NAME = os.environ.get("DB_NAME", "gateways")
DB_MEASUREMENT = os.environ.get("DB_MEASUREMENT", "metrics")
GATEWAY_ID = os.environ.get("GATEWAY_ID", "gateway")

client = InfluxDBClient(host=DB_HOST, port=DB_PORT, username=DB_USER, password=DB_PASS)
client.switch_database(DB_NAME)

if PROTOCOL == "basicstation":
    runner = basicstation_parser(CONTAINER_NAME, True)
elif PROTOCOL == "legacy":
    runner = legacy_parser(CONTAINER_NAME, True)
else:
    print("ERROR: Unkown protocol")
    sys.exit()

for value in runner.run():
    
    #print("Received: {}".format(value))
    
    type = value.pop('type', None)
    timestamp = value.pop('timestamp', None)
    data = [
        {
            "measurement": DB_MEASUREMENT,
            "tags": {
                "gateway_id": GATEWAY_ID,
                "type": type
            },
            "time": datetime.datetime.fromtimestamp(timestamp, datetime.timezone.utc).isoformat(),
            "fields": value
        }
    ]    
    client.write_points(data)

