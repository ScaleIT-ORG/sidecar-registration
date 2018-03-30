#!/bin/bash

echo "Sidecar running"
echo "pid is $$"

ETCD_PORT=$ETCD_PORT
ETCD_IP=$ETCD_IP
echo $ETCD_IP

#check if etcd is up and running
STR='"health": "false"'
STR=$(curl -sb -H "Accept: application/json" "http://$ETCD_IP:$ETCD_PORT/health")
while [[ $STR != *'"health":"true"'* ]]
do
	echo "Waiting for etcd ..."
	STR=$(curl -sb -H "Accept: application/json" "http://$ETD_IP:$ETCD_PORT/health")
  echo $STR
	sleep 1
done

#Register Application
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/id -d value="$APP_ID"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/name -d value="$APP_NAME"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/title -d value="$APP_TITLE"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/shortDescription -d value="$APP_SHORTDESCRIPTION"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/description -d value="$APP_DESCRIPTION"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/category -d value="$APP_CATEGORY"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/status -d value="$APP_STATUS"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/apiEntrypoint -d value="$APP_APIENTRYPOINT"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/apiSpecificationUrl -d value="$APP_APISPECIFICATION"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/iconUrl -d value="$APP_ICONURL"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/adminUrl -d value="$APPHUB_ADMINURL"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/userUrl -d value="$APP_USERURL"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/createdAt -d value="$APP_CREATEDAT"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/updatedAt -d value="$APP_UPDATEDAT"
curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/appType -d value="$APP_TYPE"

# SIGTERM-handler
# Unregister this application on ctr+c
term_handler() {
  echo "[Sidecar] Shutting Down"

  #Delete Entry
  #curl -L -X PUT "http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME?recursive=true" -XDELETE

  #Set Status Offline
  curl -L -X PUT http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME/status -d value="Offline"

  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; term_handler' SIGTERM SIGINT

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done
