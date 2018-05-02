#!/usr/bin/env bash

# check if kubernetes is installed
if ! type kubectl > /dev/null; then
    echo "kubectl is not installed"
    exit
fi
# Read Password
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

mkdir temp
sed 's/VAMP_ROOT_PASSWORD/'${encodedpassword}'/g' ./templates/vamp-in-cluster-template.yaml > ./temp/vamp-in-cluster.yaml

kubectl create -f ./temp/vamp-in-cluster.yaml

while true
do
    echo "Waiting for ingress to be ready ..."
    sleep 10
    ip=$(kubectl describe svc vamp -n vamp-system | grep "LoadBalancer Ingress:" |  awk '{print $3}')
    echo $ip
    if [ $ip ]; then
        echo "use http://$ip:8888 to connect"
        break
    fi
done
