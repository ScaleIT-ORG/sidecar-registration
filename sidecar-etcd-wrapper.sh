#!/bin/sh

echo "Sidecar running"
echo "pid is $$"

APP_REGISTRY_ADDRESS=$APP_REGISTRY_ADDRESS
echo $APP_REGISTRY_ADDRESS

#check if YP is up and running
STR='"health": "false"'
STR=$(curl -k -s -H "Accept: application/json" "$APP_REGISTRY_ADDRESS/api/v1/health")
while [[ $STR != *'"health":"true"'* ]]
do
	echo "Waiting for YP ..."
	STR=$(curl -k -s -H "Accept: application/json" "$APP_REGISTRY_ADDRESS/api/v1/health")
	sleep 10
done

echo "response of GET /api/v1/health: " $STR

# function to generate post data
generate_post_data() {
cat <<EOF
{
  "id":"$APP_ID",
  "name": "$APP_NAME",
  "title": "$APP_TITLE",
  "shortDescription": "$APP_SHORT_DESCRIPTION",
  "description":"$APP_DESCRIPTION",
  "category":"$APP_CATEGORY",
  "appType":"$APP_TYPE",
  "apiEntrypoint": "$APP_API_ENTRYPOINT",
  "adminUrl": "$APP_ADMIN_URL",
  "adminConfigUrl": "$APP_ADMIN_CONFIG_URL",
  "adminDocUrl": "$APP_ADMIN_DOC_URL",
  "adminLogUrl": "$APP_ADMIN_LOG_URL",
  "adminStatusUrl": "$APP_ADMIN_STATUS_URL",
  "userUrl": "$APP_USER_URL",
  "userDocUrl": "$APP_USER_DOC_URL",
  "userStatusUrl": "$APP_USER_STATUS_URL",
  "devDocUrl": "$APP_DEV_DOC_URL",
  "devSwaggerUrl": "$APP_DEV_SWAGGER_URL",
  "iconUrl": "$APP_ICON_URL",
  "status":"online"
}
EOF
}

echo $(generate_post_data)

#Register Application
response=$(curl -X POST -k -i -f \
                --write-out %{http_code} --silent --output /dev/null \
                -H "Accept: application/json" \
                -H "Content-Type: application/json" \
                --data "$(generate_post_data)" \
                "$APP_REGISTRY_ADDRESS/api/v1/apps")

echo "response of POST /api/v1/apps: " $response

if [ "$response" != 200 ]
    then
      echo '{"lifecycleStatus":"online"}'
      echo "response of PUT /api/v1/apps/$APP_NAME: " \
           $(curl -X PUT -k -i -f \
                  --write-out %{http_code} --silent --output /dev/null \
                  -H "Accept: application/json" \
                  -H "Content-Type: application/json" \
                  -d '{"lifecycleStatus":"online"}' \
                  "$APP_REGISTRY_ADDRESS/api/v1/apps/$APP_NAME")
fi

# SIGTERM-handler
# Unregister this application on ctr+c
term_handler() {
  echo "[Sidecar] Shutting Down"

  #Set Status Offline
  echo '{"lifecycleStatus":"offline"}'
  echo "response of PUT /api/v1/apps/$APP_NAME: " \
        $(curl -L -X PUT -k -i -f \
               --write-out %{http_code} --silent --output /dev/null \
               -H "Accept: application/json" \
               -H "Content-Type: application/json" \
               -d '{"lifecycleStatus":"offline"}' \
               "$APP_REGISTRY_ADDRESS/api/v1/apps/$APP_NAME")

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
