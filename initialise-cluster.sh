#!/usr/bin/env bash

kubectl apply -f ./templates/vamp-namespace-in-cluster.yaml

SECRET_NAME=$( kubectl get sa default -n=vamp-system -o go-template='{{(index .secrets 0).name}}' )

echo Cluster URL: $(kubectl cluster-info | awk 'NR==1{print $6}')
echo
echo Certificate: $(kubectl get secret ${SECRET_NAME} -n=vamp-system -o go-template='{{index .data "ca.crt"}}')
echo
echo Token: $(kubectl get secret ${SECRET_NAME} -n=vamp-system -o go-template='{{index .data.token }}')
