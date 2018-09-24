#!/usr/bin/env bash

# check if kubernetes is installed
if ! type kubectl > /dev/null; then
    echo "kubectl is not installed"
    exit
fi

POSITIONAL=()
EXTERNALDB=false
DBURL="mongo-0.vamp-mongodb:27017,mongo-1.vamp-mongodb:27017,mongo-2.vamp-mongodb:27017"

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --externaldb)
    EXTERNALDB=true
    shift # past argument
    ;;
    --dburl)
    DBURL="$2"
    shift # past argument
    shift # past value
    ;;
    --dbname)
    DBNAME="$2"
    shift # past argument
    shift # past value
    ;;
    -u)
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# Read Password
echo "A password needed for the default user (root) to be used in the UI."
echo "This password will be set as your root user password"
echo "Password will be asked twice and it will not be visible while typing"
echo "please enter the password for root user"
echo -n Password:
read -s password1
echo
echo "please re enter the same password"
echo -n Password:
read -s password2
echo

if [ $password1 != $password2 ]; then
    echo "passwords do not match"
    exit
fi

# sed with password
encodedpassword=$(echo -n $password1 | base64)

echo $DBURL
echo $DBNAME

mkdir temp
sed -e 's/VAMP_ROOT_PASSWORD/'${encodedpassword}'/g' -e 's,VAMP_DB_URL,'${DBURL}',g'  -e 's,VAMP_DB_NAME,'${DBNAME}',g' ./templates/vamp-in-cluster-template.yaml > ./temp/vamp-in-cluster.yaml

kubectl create -f ./templates/vamp-namespace-in-cluster.yaml

if !($EXTERNALDB); then

echo "Setting up database"

kubectl create -f ./templates/vamp-db-in-cluster.yaml

fi

kubectl create -f ./temp/vamp-in-cluster.yaml

while true
do
    echo "Waiting for ingress to be ready ..."
    sleep 10
    ip=$(kubectl describe svc vamp -n vamp-system | grep "LoadBalancer Ingress:" |  awk '{print $3}')
    echo $ip
    if [ $ip ]; then
        echo "use http://$ip:8888/ui/#/login to connect"
        break
    fi
done



