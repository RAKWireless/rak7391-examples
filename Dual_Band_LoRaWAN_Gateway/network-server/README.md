# Automate LNS configuration

## 1. Run The Things Stack

You can use the next `docker-compose.yml` file to configure and run your instance of The Things Stack.

If you want to learn more about this container,  please visit  [xoseperez/the-things-stack-docker](https://github.com/xoseperez/the-things-stack-docker/#cli-auto-login) .

```
version: '3.7'

volumes:
    redis: 
    postgres:
    stack-blob:
    stack-data:

services:

  postgres:
    image: postgres:14.3-alpine3.15
    container_name: postgres
    restart: unless-stopped
    environment:
        - POSTGRES_PASSWORD=root
        - POSTGRES_USER=root
        - POSTGRES_DB=ttn_lorawan
    volumes:
        - 'postgres:/var/lib/postgresql/data'
    ports:
        - "127.0.0.1:5432:5432"
    
  redis:
    image: redis:7.0.0-alpine3.15
    container_name: redis
    command: redis-server --appendonly yes
    restart: unless-stopped
    volumes:
        - 'redis:/data'
    ports:
        - "127.0.0.1:6379:6379"
  
  stack:
    image: xoseperez/the-things-stack:latest
    container_name: stack
    restart: unless-stopped
    depends_on:
        - redis
        - postgres
    volumes:
        - 'stack-blob:/srv/ttn-lorawan/public/blob'
        - 'stack-data:/srv/data'
    environment:
        TTS_DOMAIN: 192.168.42.1        # set this to the IP or domain name of the host you will be using to access the stack
        TTN_LW_BLOB_LOCAL_DIRECTORY: /srv/ttn-lorawan/public/blob
        TTN_LW_REDIS_ADDRESS: redis:6379
        TTN_LW_IS_DATABASE_URI: postgres://root:root@postgres:5432/ttn_lorawan?sslmode=disable
        WAIT_HOSTS: redis:6379, postgres:5432
        WAIT_HOSTS_TIMEOUT: 300
        WAIT_SLEEP_INTERVAL: 30
        WAIT_HOST_CONNECT_TIMEOUT: 30
    labels:
        io.balena.features.balena-api: '1'

    ports:
    
        - "80:1885"
        - "443:8885"
    
        - "1881:1881"
        - "1882:1882"
        - "1883:1883"
        - "1884:1884"
        - "1885:1885"
        - "1887:1887"
    
        - "8881:8881"
        - "8882:8882"
        - "8883:8883"
        - "8884:8884"
        - "8885:8885"
        - "8887:8887"
    
        - "1700:1700/udp"
```

Modify the `TTS_DOMAIN` environment variable to match your setup. Then run `docker-compose up` to start the container.

![image-20220609110556845](assets/image-20220609110556845.png)

Then, copy the value of `TTS_DOMAIN` to brower to open the console page. The User ID and Password are `admin` and `changeme`.

![image-20220609110616456](assets/image-20220609110616456.png)

Log in,  The page will be shown as follows.

![image-20220609111907342](assets/image-20220609111907342.png)



If you see this page, it indicates that the container is working properly. Then you can create applicaitons, gateways and devices using this page.  But if you have too many devices to create, that will be a big wok. Here is a script for quickly adding devices. If you are interested, please keep reading.

## 2. Create configuration file

Create a JSON file as configure file with the  format as follows. You can add more enough devices as you like.

```
{
  "gateways": [
    {
      "gateway-id": "gw01",
      "frequency-plan-id": "EU_863_870",
      "gateway-eui": "0011223344556677"
    }
  ],
  "applications": [
    {
      "application-id": "app01",
      "devices": [
        {
          "device-id": "dev01",
          "frequency-plan-id": "EU_863_870",
          "dev-eui": "0011223344556677",
          "app-eui": "0011223344556677",
          "app-key": "00112233445566778899AABBCCDDEEFF"
        },
        {
          "device-id": "dev02",
          "frequency-plan-id": "EU_863_870",
          "dev-eui": "1122334455667788",
          "app-eui": "0011223344556677",
          "app-key": "00112233445566778899AABBCCDDEEFF"
        }
      ]
    }
  ]
}

```

`frequency-plan-id`: 

​	Please use `docker exec -it stack ttn-lw-cli gateways list-frequency-plans` and `docker exec -it stack ttn-lw-cli end-devices list-frequency-plans` to query the frequency plans of gateway and end devices. 

## 3. Run script

Run `./auto_lns_config.sh ./configure.json` to add devices which you add in configure file.

Then, you will find the gateway, applications and end devices added on the console page.



## 4. License

This project is licensed under MIT license.