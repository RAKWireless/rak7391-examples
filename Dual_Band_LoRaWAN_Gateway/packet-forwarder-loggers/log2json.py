#!/usr/bin/env python

import os
import sys
from basicstation import parser as basicstation_parser
from legacy import parser as legacy_parser

PROTOCOL  = os.environ.get("PROTOCOL", "basicstation")
CONTAINER_NAME = os.environ.get("CONTAINER_NAME", "basicstation")
BUCKET_SIZE = int(os.environ.get("BUCKET_SIZE", 60))
BUCKET_COUNT = int(os.environ.get("BUCKET_COUNT", 15))

buckets = {}
totals = {
    'rx': 0,
    'tx': 0
}
previous_bucket = 0

if PROTOCOL == "basicstation":
    runner = basicstation_parser(CONTAINER_NAME, True)
elif PROTOCOL == "legacy":
    runner = legacy_parser(CONTAINER_NAME, True)
else:
    print("ERROR: Unkown protocol")
    sys.exit()

for value in runner.run():
    
    #print("Received: {}".format(value))

    new_bucket = int(value['timestamp'] / BUCKET_SIZE)
    if new_bucket != previous_bucket:
        previous_bucket = new_bucket
        buckets = {key: value for key, value in buckets.items() if key > new_bucket - BUCKET_COUNT}
        buckets[new_bucket] = {
            'rx': 0,
            'tx': 0
        }
    totals[value['type']] = totals[value['type']] + 1
    buckets[new_bucket][value['type']] = buckets[new_bucket][value['type']] + 1
    
    offset = list(buckets.keys())[0]
    print(dict({
        'totals': totals,
        'buckets': { (key - offset): value for key, value in buckets.items() },
        'bucket_size': BUCKET_SIZE,
        'bucket_count': BUCKET_COUNT
    }))
