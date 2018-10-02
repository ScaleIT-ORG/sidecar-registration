# ScaleIT Registration Sidecar

## Standalone Usage

1. Clone this repository to your main application

2. Configure config.env in the cloned repository. To configure config.env appropriately, refer to configurations of the etcd, your application has to be registered in.

3. How to use:
    1. Run "docker-compose up" to start the script as standalone 
    2. Or add
        
```
  sidecarregistration:
    build: ./sidecar-registration/
    env_file:
      - ./sidecar-registration/config.env
``` 
to your docker-compose file. 

## Platform Integrated

If you have already pushed the Registration Sidecar Image to your docker registry, you can just use it in the docker-compose.yml of your App:

```
    de-kit-production-map:
        image: myAppImage
        ...
        
    de-kit-production-map-sidecar-registration:
        image: scaleit-app-pool.ondics.de:5000/scaleit-app-pool/de-kit-sidecar-registration:1.0
        environment:
          - ETCD_IP=10.0.200
          - ETCD_PORT=49501
          - APP_PORT=51100
          - APP_ID=de-kit-production-map-app_1
          - APP_NAME=de-kit-production-map-app
          - APP_TITLE=Production Map App
          - APP_SHORTDESCRIPTION=Digital Production Map
          - APP_DESCRIPTION=The Digital Production Map helps give an overview of the physical and digital production landscape
          - APP_CATEGORY=domainApp
          - APP_STATUS=online
          - APP_ICON_URL=http://10.0.200:51100/assets/icon/favicon.ico
          - APP_USER_URL=http://10.0.200:51100/#/pages/user
          - APP_USER_DOC_URL=
          - APP_USER_STATUS_URL=
          - APP_DEV_DOC_URL=
          - APP_DEV_SWAGGER_URL=
          - APP_ADMIN_URL=http://10.0.200:${APP_MAIN_PORT}/#/admin
          - APP_ADMIN_CONFIG_URL=
          - APP_ADMIN_DOC_URL=
          - APP_ADMIN_LOG_URL=
          - APP_ADMIN_STATUS_URL=
          - APP_API_ENTRYPOINT=
          - APP_UPDATEDAT=2018-09-19T13:32:16.581Z
          - APP_TYPE=domainApp
```

Checking the sidecar: in order to check whether the sidecar is configured correctly, open your etcd browser (http://$ETCD_IP:$ETCD_PORT) and find your app in the etcd filesystem. See the screenshot-example below. Furthmore you can also refer to the section "explanation". 
![Correctness check](https://github.com/ScaleIT-ORG/spsc-app-registration/blob/master/Resources/Documentation/check.png)

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

