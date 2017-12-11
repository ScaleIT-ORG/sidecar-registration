# sidecar-script
1. Clone this repository to your main application

2. Configure config.env

3. How to use:
	1. Run "docker-compose up" to start the script as standalone 
	2. Or add
		
```
  sidecarregistration:
    build: ./sidecar-registration/
    env_file:
      - ./sidecar-registration/config.env
``` 
to your docker-compose file

# architecture

![Registration Sidecar Architecture Concept](https://github.com/ScaleIT-ORG/spsc-app-registration/blob/master/Resources/Documentation/architecture.png)

# explanation

![The process of application's registration](https://github.com/ScaleIT-ORG/spsc-app-registration/blob/master/Resources/Documentation/App%20-%20Registration.png)

This is where the Magic happens

At first it checks if ETCD is up and Running or waits till it gets a healthy signal from the ETCD Storage 

```bash
#check if etcd is up and running
STR='"health": "false"'
STR=$(curl -sb -H "Accept: application/json" "http://$ETCD_IP:$ETCD_PORT/health")
while [[ $STR != *'"health": "true"'* ]]
do
        echo "Waiting for etcd ..."
        STR=$(curl -sb -H "Accept: application/json" "http://$ETCD_IP:$ETCD_PORT/health")
        sleep 1
done
```

Then the application registers its keys
```bash
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/url -d value="$APP_URL"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/App_Icon -d value="$APP_ICON"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/AppHub_Icon -d value="$APPHUB_ICON"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/description -d value="$APP_DESCRIPTION"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/lifecycleStatus -d value="Online"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/visibleForRole -d value="$APP_VISIBLEFORROLE"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/appType -d value="$APP_TYPE"
```

Additionaly there is a SIGTERM handler which catches the ctr+c command and unregisters the application with:
```bash
curl -L -X PUT 'http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME?recursive=true' -XDELETE
```

The script also starts the main Application and executes a endless loop to catch the ctr+c Signal while the container is up and running
```bash
# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done
```

