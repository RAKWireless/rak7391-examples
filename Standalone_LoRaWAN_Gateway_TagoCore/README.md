# Standalone LoraWAN Gateway with TagoCore

[TOC]

## 1. Introduction

This guide explains how to create a Standalone LoraWAN Gateway with [TagoCore](https://tagocore.com) for edge processing. 

### 2. Services

We have 5 services defined in the [docker compose](./docker-compose.yml) file: 

- `udp-packet-forwarder` interacts with the LoRa chip to receive and transfer LoRa packets
- `stack` is a TTN stack service which depends on `redis` and `postgres` service. This service enables connectivity, management, and monitoring of devices, gateways and end-user applications
- `redis` is the main data store for the Network Server, Application Server and Join Server, and it is also used by Identity Server and event system.
- `postgres` is another databased used by `stack` 
- `tagocore` service is a open-source edge computing platform for IoT you can use to process, persist, filter and analyze data from your sensors right on the gateway.

### 3. Getting started

The `./run.sh` script performs different actions:

* modifies the `docker-compose.yml` file with sensible data
* pulls or builds the different services
* brings the services up

Once the services are running and you have access to the TTS web UI, you can populate gateway, apps and devices using the same script like this: `./run.sh populate`. This will:

* create the gateway in the Stack service connected to the local packet forwarder
* create apps and loads devices from the `devices.csv` file if it exists
* configure the app to use CayenneLPP as default uplink parser 
* configure a webhook from the app to TagoCore

## 4. License

This project is licensed under MIT license.
