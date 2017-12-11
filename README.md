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


# explanation

[!The process of application's registration](https://github.com/ScaleIT-ORG/spsc-app-registration/blob/master/Resources/Documentation/App%20-%20Registration.png)

This is where the Magic happens

At first it checks if ETCD is up and Running or waits till it gets a healthy signal from the ETCD Storage 

```bash
#check if etcd is up and running
STR='"health": "false"'
STR=$(curl -sb -H "Accept: application/json" "http://etcd:2379/health")
while [[ $STR != *'"health": "true"'* ]]
do
        echo "Waiting for etcd ..."
        STR=$(curl -sb -H "Accept: application/json" "http://etcd:2379/health")
        sleep 1
done
```

Then the application registers its keys
```bash
#Register Application
curl -L -X PUT http://etcd:2379/v2/keys/Example1/url -d value="localhost:3000"
curl -L -X PUT http://etcd:2379/v2/keys/Example1/icon -d value="/icon/favicon.png"
curl -L -X PUT http://etcd:2379/v2/keys/Example1/desc -d value="Description here  ...."
```

Additionaly there is a SIGTERM handler which catches the ctr+c command and unregisters the application with:
```bash
curl -L -X PUT 'http://etcd:2379/v2/keys/Example1?recursive=true' -XDELETE
```

The script also starts the main Application and executes a endless loop to catch the ctr+c Signal while the container is up and running
```bash
#run application
node example.js &
	# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done
```

