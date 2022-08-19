#!/bin/sh

if [ "$CLUSTER_TOKEN" == "" ]; 
then
    tagocore start --no-daemon
else
    tagocore start --no-daemon --cluster $CLUSTER_TOKEN
fi