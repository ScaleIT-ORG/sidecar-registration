#!/bin/sh

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

APP_REGISTRY_URL="http://$ETCD_IP:$ETCD_PORT/v2/keys/apps/$APP_ID"

echo "PUTting App Information on $APP_REGISTRY_URL"

#Register Application
curl -L -X PUT "$APP_REGISTRY_URL/id" -d value="$APP_ID"
curl -L -X PUT "$APP_REGISTRY_URL/name" -d value="$APP_NAME"
curl -L -X PUT "$APP_REGISTRY_URL/title" -d value="$APP_TITLE"
curl -L -X PUT "$APP_REGISTRY_URL/shortDescription" -d value="$APP_SHORT_DESCRIPTION"
curl -L -X PUT "$APP_REGISTRY_URL/description" -d value="$APP_DESCRIPTION"
curl -L -X PUT "$APP_REGISTRY_URL/category" -d value="$APP_CATEGORY"
curl -L -X PUT "$APP_REGISTRY_URL/status" -d value="$APP_STATUS"
curl -L -X PUT "$APP_REGISTRY_URL/apiEntrypoint" -d value="$APP_API_ENTRYPOINT"
curl -L -X PUT "$APP_REGISTRY_URL/apiSpecificationUrl" -d value="$APP_API_SPECIFICATION"
curl -L -X PUT "$APP_REGISTRY_URL/iconUrl" -d value="$APP_ICON_URL"
curl -L -X PUT "$APP_REGISTRY_URL/adminUrl" -d value="$APPHUB_ADMIN_URL"
curl -L -X PUT "$APP_REGISTRY_URL/userUrl" -d value="$APP_USER_URL"
curl -L -X PUT "$APP_REGISTRY_URL/createdAt" -d value="$APP_CREATED_AT"
curl -L -X PUT "$APP_REGISTRY_URL/updatedAt" -d value="$APP_UPDATED_AT"
curl -L -X PUT "$APP_REGISTRY_URL/appType" -d value="$APP_TYPE"

# SIGTERM-handler
# Unregister this application on ctr+c
term_handler() {
  echo "[Sidecar] Shutting Down"

  #Delete Entry
  #curl -L -X PUT "http://$ETCD_IP:$ETCD_PORT/v2/keys/$APP_NAME?recursive=true" -XDELETE

  #Set Status Offline
  curl -L -X PUT "$APP_REGISTRY_URL/status" -d value="Offline"

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
