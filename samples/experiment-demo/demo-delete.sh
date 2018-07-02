#!/usr/bin/env bash

kubectl delete -f namespace.yaml
kubectl delete -f deployment1.yaml
kubectl delete -f deployment2.yaml