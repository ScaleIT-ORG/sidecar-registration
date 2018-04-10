Work in progress

example docker-compose for app rancher deployment:

	examples/docker-compose.yml

These are the values you should fill into the docker-compose for Rancher - works over the rancher questions mechanism (similar to .env in docker-compose):

	# entries that are empty here are optional
	ETCD_IP=10.28.230.25
	ETCD_PORT=49501
	
	APP_ID=myID123
	APP_NAME=App1
	APP_TITLE=MyTitle
	APP_SHORTDESCRIPTION=Your Description here
	APP_DESCRIPTION=More Information
	APP_CATEGORY=productivity
	APP_STATUS=online
	APP_API_ENTRYPOINT=https=//<ip>=<port>/api/v1
	APP_ICON_URL=https://<ip>:<port>/user/icon.svg
	
	APP_ADMIN_URL=https://<ip>:<port>/admin
	APP_ADMIN_CONFIG_URL=
	APP_ADMIN_DOC_URL=
	APP_ADMIN_LOG_URL=
	APP_ADMIN_STATUS_URL=
	
	APP_USER_URL=https://<ip>:<port>/user
	APP_USER_DOC_URL=
	APP_USER_STATUS_URL=
	APP_DEV_DOC_URL=
	APP_DEV_SWAGGER_URL=
	APP_USER_URL=
	
	APP_UPDATEDAT=2018-03-30T12:32:16.581Z
	APP_TYPE=domainApp

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

Then the application registers its keys. For example the following:
* $APP_URL
* $APP_ICON
* $APPHUB_ICON
* $APP_DESCRIPTION
* $APP_VISIBLEFORROLE
* $APP_TYPE

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

