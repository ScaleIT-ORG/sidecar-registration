#!/bin/sh

echo "Sidecar running"
echo "pid is $$"

echo Current config:
echo APP_ID: $APP_ID
echo APP_NAME: $APP_NAME
echo APP_TITLE: $APP_TITLE
echo APP_SHORT_DESCRIPTION: $APP_SHORT_DESCRIPTION
echo APP_DESCRIPTION: $APP_DESCRIPTION
echo APP_CATEGORY: $APP_CATEGORY
echo APP_STATUS: $APP_STATUS
echo APP_API_ENTRYPOINT: $APP_API_ENTRYPOINT
echo APP_ICON_URL: $APP_ICON_URL
echo APP_ADMIN_URL: $APP_ADMIN_URL
echo APP_ADMIN_CONFIG_URL: $APP_ADMIN_CONFIG_URL
echo APP_ADMIN_DOC_URL: $APP_ADMIN_DOC_URL
echo APP_ADMIN_LOG_URL: $APP_ADMIN_LOG_URL
echo APP_ADMIN_STATUS_URL: $APP_ADMIN_STATUS_URL
echo APP_USER_DOC_URL: $APP_USER_DOC_URL
echo APP_USER_STATUS_URL: $APP_USER_STATUS_URL
echo APP_DEV_DOC_URL: $APP_DEV_DOC_URL
echo APP_DEV_SWAGGER_URL: $APP_DEV_SWAGGER_URL
echo APP_USER_URL: $APP_USER_URL
echo APP_UPDATED_AT: $APP_UPDATED_AT
echo APP_TYPE: $APP_TYPE

# ETCD_PORT=$ETCD_PORT
# ETCD_IP=$ETCD_IP
echo ETCD IP: $ETCD_IP
echo ETCD PORT: $ETCD_IP

echo "Check if etcd is up and running ..."

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
echo APP_REGISTRY_URL: $APP_REGISTRY_URL

echo "PUTting App Information on $APP_REGISTRY_URL"

# Register Application
# See App Swagger file for details
# https://github.com/ScaleIT-Org/etcd-api-wrapper/blob/master/server/api/definitions/schemas/App.yaml

curl -L -X PUT "$APP_REGISTRY_URL/id" -d value="$APP_ID"
curl -L -X PUT "$APP_REGISTRY_URL/name" -d value="$APP_NAME"
curl -L -X PUT "$APP_REGISTRY_URL/title" -d value="$APP_TITLE"
curl -L -X PUT "$APP_REGISTRY_URL/shortDescription" -d value="$APP_SHORT_DESCRIPTION"
curl -L -X PUT "$APP_REGISTRY_URL/description" -d value="$APP_DESCRIPTION"
curl -L -X PUT "$APP_REGISTRY_URL/category" -d value="$APP_CATEGORY"
curl -L -X PUT "$APP_REGISTRY_URL/status" -d value="$APP_STATUS"
curl -L -X PUT "$APP_REGISTRY_URL/apiEntrypoint" -d value="$APP_API_ENTRYPOINT"
curl -L -X PUT "$APP_REGISTRY_URL/iconUrl" -d value="$APP_ICON_URL"
curl -L -X PUT "$APP_REGISTRY_URL/adminUrl" -d value="$APP_ADMIN_URL"
curl -L -X PUT "$APP_REGISTRY_URL/adminConfigUrl" -d value="$APP_ADMIN_CONFIG_URL"
curl -L -X PUT "$APP_REGISTRY_URL/adminDocUrl" -d value="$APP_ADMIN_DOC_URL"
curl -L -X PUT "$APP_REGISTRY_URL/adminLogUrl" -d value="$APP_ADMIN_LOG_URL"
curl -L -X PUT "$APP_REGISTRY_URL/adminStatusUrl" -d value="$APP_ADMIN_STATUS_URL"
curl -L -X PUT "$APP_REGISTRY_URL/userDocUrl" -d value="$APP_USER_DOC_URL"
curl -L -X PUT "$APP_REGISTRY_URL/userStatusUrl" -d value="$APP_USER_STATUS_URL"
curl -L -X PUT "$APP_REGISTRY_URL/devDocUrl" -d value="$APP_DEV_DOC_URL"
curl -L -X PUT "$APP_REGISTRY_URL/devSwaggerUrl" -d value="$APP_DEV_SWAGGER_URL"
curl -L -X PUT "$APP_REGISTRY_URL/userUrl" -d value="$APP_USER_URL"
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
