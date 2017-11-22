#!/bin/bash

echo "Sidecar running"
echo "pid is $$"

#check if etcd is up and running
STR='"health": "false"'
STR=$(curl -sb -H "Accept: application/json" "http://etcd:2379/health")
while [[ $STR != *'"health": "true"'* ]]
do
	echo "Waiting for etcd ..."
	STR=$(curl -sb -H "Accept: application/json" "http://etcd:2379/health")
	sleep 1
done

#Register Application
curl -L -X PUT http://etcd:2379/v2/keys/Example1/url -d value="localhost:3000"
curl -L -X PUT http://etcd:2379/v2/keys/Example1/icon -d value="/icon/favicon.png"
curl -L -X PUT http://etcd:2379/v2/keys/Example1/desc -d value="Description here  ...."


# SIGTERM-handler
# Unregister this application on ctr+c
term_handler() {
  echo "[Sidecar] Shutting Down"

  curl -L -X PUT 'http://etcd:2379/v2/keys/Example1?recursive=true' -XDELETE

  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; term_handler' SIGTERM SIGINT


#run application
node example.js &

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done
