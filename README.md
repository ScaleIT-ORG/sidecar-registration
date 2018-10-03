# ScaleIT Registration Sidecar

## Platform Integrated

If you have already pushed the Registration Sidecar Image to your docker registry, add this sidecar to your launch configuration (eg. docker-compose) in order to register it to the ETCD App Registry.

In the Rancher Catalog entry for your app, you need to have the following files. Add all environment variables to the 

	|---de-kit-black-cylinder/
	  |---catalogIcon-de-kit-black-cylinder.png
	  |---config.yml
	  \---0/
	    |-----docker-compose.yml
	    \-----rancher-compose.yml

This is how your docker-compose.yml for the catalog should look like:

	version: '2'
	services:
	    de-kit-black-cylinder:
	        image: scaleit-app-pool.ondics.de:5000/scaleit-app-pool/de-kit-black-cylinder:1.0
	        ports:
	          - "51102:80"
        
	    de-kit-black-cylinder-sidecar-registration:
	    	image: scaleit-app-pool.ondics.de:5000/scaleit-app-pool/de-kit-sidecar-registration:1.0
	    	environment:
	          - ETCD_IP=10.0.0.200
	          - ETCD_PORT=49501
	          - APP_PORT=51102
	          - APP_ID=de-kit-black-cylinder_1
	          - APP_NAME=de-kit-black-cylinder
	          - APP_TITLE=Black Cylinder Nutzen
	          - APP_SHORTDESCRIPTION=Black Cylinder Nutzen Digital Twin
	          - APP_DESCRIPTION=Proof of Concept Black Cylinder Nutzen Digital Twin
	          - APP_CATEGORY=domainApp
	          - APP_STATUS=online
	          - APP_ICON_URL=http://10.0.0.200:51102/assets/icon/appHubIcon-de-kit-black-cylinder.png
	          - APP_USER_URL=http://10.0.0.200:51102/#/user
	          - APP_USER_DOC_URL=
	          - APP_USER_STATUS_URL=
	          - APP_DEV_DOC_URL=
	          - APP_DEV_SWAGGER_URL=
	          - APP_ADMIN_URL=http://10.0.0.200:51102/#/admin
	          - APP_ADMIN_CONFIG_URL=
	          - APP_ADMIN_DOC_URL=
	          - APP_ADMIN_LOG_URL=
	          - APP_ADMIN_STATUS_URL=
	          - APP_API_ENTRYPOINT=
	          - APP_UPDATEDAT=2018-04-11T12:32:16.581Z
	          - APP_TYPE=domainApp

If this docker-compose is launched in Rancher as a stack it will pull the images and start the containers. The registration sidecar will register the values of the env variables above in the registry.

You could query the registry via the ETCD Browser usually located at `<server-address>:45902`

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

## Checking Proper Configuration

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

