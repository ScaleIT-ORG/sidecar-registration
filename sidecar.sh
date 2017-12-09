#!/bin/bash

echo "Sidecar running"
echo "pid is $$"

ETCD_IP=$ETCD_IP
APP_NAME=$APP_NAME
APP_URL=$APP_URL
APP_DESCRIPTION=$APP_DESCRIPTION
APP_ICON=$APP_ICON
echo "test: $ETCD_IP"
#check if etcd is up and running
STR='"health": "false"'
STR=$(curl -sb -H "Accept: application/json" "http://$ETCD_IP:49501/health")
while [[ $STR != *'"health": "true"'* ]]
do
	echo "Waiting for etcd ..."
	STR=$(curl -sb -H "Accept: application/json" "http://$ETD_IP:49501/health")
	sleep 1
done

#Register Application
curl -L -X PUT http://$ETCD_IP:49501/v2/keys/$APP_NAME/url -d value="$APP_URL"
curl -L -X PUT http://$ETCD_IP:49501/v2/keys/$APP_NAME/icon -d value="$APP_ICON"
curl -L -X PUT http://$ETCD_IP:49501/v2/keys/$APP_NAME/desc -d value="$APP_DESCRIPTION"


# SIGTERM-handler
# Unregister this application on ctr+c
term_handler() {
  echo "[Sidecar] Shutting Down"

  curl -L -X PUT "http://$ETCD_IP:49501/v2/keys/$APP_NAME?recursive=true" -XDELETE

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
