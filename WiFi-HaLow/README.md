# How to use AHPI7292S in combination with RAK7391

[TOC]

## 1. Introduction

This guide explains how to use [Wi-Fi HaLow]() module [AHPI7292S](https://www.alfa.com.tw/products/ahpi7292s) in combination with RAK7391 board or Raspberry Pi board.

## 2. Hardware 

- 2x AHPI7292S 
- 2x antenna

- 2x RAK7391 or 2x Raspberry Pi 4B or 2x Raspberry Pi 3B+ 

## 3. Software

We provide a specfic [RAKPiOS image](https://drive.google.com/file/d/1QrR1LJYv7bMaHwGgTRIq-LPaGU8VzoKg/view?usp=sharing) for AHPI7292S, which has set  everything up, you just need to download and flash it to your RAK7391 or Raspberry Pi board. You can also build RAKPiOS image from our gitlib repo:

```
$ git clone -b arm64-halow https://git.rak-internal.net/product-rd/gateway/wis-developer/rak7391/rakpios.git
$ sudo ./build.sh -c config_rak
```

## 4. Usage

There is a NRC7292 Software Package in the folder */home/rak/nrc_pkg* , and “start.py” in folder */home/rak/nrc_pkg/script* is the unified script used to initiate AP, STA.

The following is the parameters for start.py script file.

```
Usage:
        start.py [sta_type] [security_mode] [country] [channel] [sniffer_mode]
        start.py [sta_type] [security_mode] [country] [mesh_mode] [mesh_peering] [mesh_ip]
Argument:
        sta_type      [0:STA   |  1:AP  |  2:SNIFFER  | 3:RELAY |  4:MESH]
        security_mode [0:Open  |  1:WPA2-PSK  |  2:WPA3-OWE  |  3:WPA3-SAE | 4:WPS-PBC]
        country       [US:USA  |  JP:Japan  |  TW:Taiwan  | EU:EURO | CN:China |
                       AU:Australia  |  NZ:New Zealand]
        -----------------------------------------------------------
        channel       [S1G Channel Number]   * Only for Sniffer
        sniffer_mode  [0:Local | 1:Remote]   * Only for Sniffer
        mesh_mode     [0:MPP | 1:MP | 2:MAP] * Only for Mesh
        mesh_peering  [Peer MAC address]     * Only for Mesh
        mesh_ip       [Static IP address]    * Only for Mesh
Example:
        OPEN mode STA for US                : ./start.py 0 0 US
        Security mode AP for US                : ./start.py 1 1 US
        Local Sniffer mode on CH 40 for Japan  : ./start.py 2 0 JP 40 0
        SAE mode Mesh AP for US                : ./start.py 4 3 US 2
        Mesh Point with static ip              : ./start.py 4 3 US 1 192.168.222.1
        Mesh Point with manual peering         : ./start.py 4 3 US 1 8c:0f:fa:00:29:46
        Mesh Point with manual peering & ip    : ./start.py 4 3 US 1 8c:0f:fa:00:29:46 192.168.222.1
Note:
        sniffer_mode should be set as '1' when running sniffer on remote terminal
        MPP, MP mode support only Open, WPA3-SAE security mode
```



#### Access Point (AP) running procedure

The following shows an example of AP running for US channel, and its channel can be configured in *nrc_pkg/script/conf/US/ap_halow_open.conf*. For WPA2/WPA3 modes, please refer to *nrc_pkg/script/conf/US/ap_halow_[sae|owe|wpa2].conf* files.

```
cd nrc_pkg/script
./start.py 1 0 US
```

#### Station (STA) running procedure

The following shows an example of STA running for US channel, and its channel can be configured in *nrc_pkg/script/conf/US/sta_halow_open.conf*. For WPA2/WPA3 modes, please refer to *nrc_pkg/script/conf/US/sta_halow_[sae|owe|wpa2].conf* files.

```
cd nrc_pkg/script
./start.py 0 0 US
```

