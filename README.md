# vamp2setup
Vamp2 Setup Guide

This Guide will help you set up Vamp2 on a kubernetes cluster.

# Prerequisites 
* An existing kubernetes cluster with Kubernetes version 1.9 or above installed.
* Kubectl is should be installed on the local computer with authorised to use the cluster.

# installation steps

git clone this repo or download [link]

```console
$ git clone https://github.com/magneticio/vamp2setup.git
```
or
```console
$ wget https://github.com/magneticio/vamp2setup/releases/download/pre0.0.1/setup.zip
$ unzip setup.zip
```

Run:
```console
$ ./vamp-bootstrap.sh
```

Enter password when asked, password will not be visable and it will be asked twice.

In a happy world, installer will tell you where to connect like:

```console
use http://111.122.133.144:8888 to connect
```

If you need to retrieve the IP afterawrds you can do it via kubectl

```console
kubectl get svc vamp -n=vamp-system
```

Copy the url and paste on your browser and add /ui/#/login

http://111.122.133.144:8888/ui/#/login 

to login and start using.

The default username is root.


## Istio Setup

Once installed, Vamp will automatically check for Istio on the default cluster.
Vamp expects to find the following resources inside the istio-system namesapce:

**Deployments:**

istio-ca              
istio-ingress         
istio-mixer           
istio-pilot           
istio-sidecar-injector
prometheus            

**Services:**

istio-ingress
istio-mixer
istio-pilot
istio-sidecar-injector
prometheus
prometheus-external

**Service Accounts:**

default
istio-ca-service-account
istio-ingress-service-account
istio-mixer-service-account
istio-pilot-service-account
istio-sidecar-injector-service-account
prometheus


Should some of these be missing, Vamp will try to install Istio.
Just keep in mind that if you happen to have pre-existing deployments, after the installation has been completed you will have to restart them or trigger a rolling update in order for the Istio Sidecar to be injected.

## Performing a canary release

### Requirements

In order to perform a canary release you must make sure that you have an Application with at least two Deployments installed in the cluster.
First of all, however you need to set up a Virtual Cluster, or add the correct labels to an existing one.
In this example we will guide you through the creation of a new Virtual Cluster, but you should be able to use these steps as a basis to easily update your pre-existing namespace.
Vamp looks for some specific labels when detecting namespaces to be imported as Virtual Clusters.
These labels are:

- vamp-managed: a label that tells vamp to import and manage resources from this namespace into a Virtual Cluster with the same name.
- istio-injection: a label that allows istio to perform automatic sidecar injection on the deployments in this namespace. 
- cluster: the name of the cluster to which the Virtual Cluster belongs. This label will be addedd if it is missing.
- project: the name of the cluster to which the Virtual Cluster belongs. This label will be addedd if it is missing.

Provided the first two labels are set, upon being deployed, Vamp will import all resources into the current Project and Cluster and add the two missing labels to the namespace.
For this example you can just use the following yaml

````
apiVersion: v1
kind: Namespace
metadata:
  labels:
    project: default
    cluster: default
    istio-injection: enabled
    vamp-managed: "true"
  name: vamp-tutorial
````

Just copy it into a file and run 

````
kubectl create -f namespace.yaml
````

The new Virtual Cluster will be shown in the corresponding panel on the UI.

![](images/screen1.png)


Once Vamp is running and you have a virtual cluster set up you should make sure that the Deployments for your Application are deployed and running.
If you don't have an Application yet you can just use the following yaml to create any number of Deployments.
You just have to copy it into a file and adjust the version labels and selectors and the deployment name.
Then you can simply execute:

````
kubectl create -f deployment.yaml
````

````
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: application
    version: version1
  name: deployment1
  namespace: vamp-tutorial
spec:
  replicas: 1
  selector:
    matchLabels:
      app: application
      deployment: deployment1
      version: version1
  template:
    metadata:
      labels:
        app: application
        deployment: deployment1
        version: version1
    spec:
      containers:
      - env:
        - name: SERVICE_NAME
          value: version1
        image: magneticio/nodewebservice:2.0.11
        livenessProbe:
          failureThreshold: 5
          httpGet:
            path: /health
            port: 9090
            scheme: HTTP
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 20
        name: deployment1-0
        ports:
        - containerPort: 9090
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /ready
            port: 9090
            scheme: HTTP
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 20
````

The version label is used by Istio to redirect requests to the corret Deployment in your Application. 
For that reason you should always pay extra care in setting them so that every deployment has a different version.
For our example we need a minimum of two Deployments in the same Application, so we will submit another yaml, similar to the previous one

````
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: application
    version: version1
  name: deployment2
  namespace: vamp-tutorial
spec:
  replicas: 1
  selector:
    matchLabels:
      app: application
      deployment: deployment2
      version: version2
  template:
    metadata:
      labels:
        app: application
        deployment: deployment2
        version: version2
    spec:
      containers:
      - env:
        - name: SERVICE_NAME
          value: version2
        image: magneticio/nodewebservice:2.0.11
        livenessProbe:
          failureThreshold: 5
          httpGet:
            path: /health
            port: 9090
            scheme: HTTP
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 20
        name: deployment1-0
        ports:
        - containerPort: 9090
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /ready
            port: 9090
            scheme: HTTP
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 20
````

Assuming you set up everything correctly the deployments will be imported into Vamp and you will be able to check their status, either from the UI or by calling the appropriate endpoint.
You can find below an example of a curl call to retrieve said status:

````
curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer your-token"  http://111.122.133.144/1.0/api/deployments?project_name=project&cluster_name=cluster&virtual_cluster_name=vamp-tutorial&application_name=application&deployment_name=deployment1
````

Mind the fact that, in order to query the API, you will have to provide a valid token and the correct project, cluster and virtual cluster names, which might differ from the provided example.
You can also get a list of deloyments in the application with the following call

````
curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer your-token"  http://111.122.133.144/1.0/api/deployments/list?project_name=project&cluster_name=cluster&virtual_cluster_name=vamp-tutorial&application_name=application
````

And the application itself with

````
curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer your-token"  http://111.122.133.144/1.0/api/applications?project_name=project&cluster_name=cluster&virtual_cluster_name=vamp-tutorial&application_name=application
````

Finally you can check the deployments also through kubectl by executing

````
kubectl get deploy -n=vamp-tutorial
````

### Exposing your application

Now that you have your Application running and two Deployments for it you can create a Service and an Ingress to expose them.
Again you can simply use the UI to achieve both tasks or rely on the API.
In the second case you can just send a POST request to following url

````
http://localhost:8888/1.0/api/services?project_name=project&cluster_name=cluster&virtual_cluster_name=vamp-tutorial&application_name=application&service_name=tutorial-service
````

providing of course a valid token and the following json body

````
{
  "ports" : [
    {
      "name":"http",
      "port": 9090,
      "targetPort": 9090,
      "protocol": "TCP"
    }
  ],
  "metadata": {
    "additionalProp1": 0,
    "additionalProp2": 0,
    "additionalProp3": 0
  },
  "labels" : {
    "test" : "test1"
  }
}
````

Once the Service has been created it will be accessible internally.
As usua you can check the service statu through the UI or through the API performing the following call

````
curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer your-token"  http://localhost:8888/1.0/api/services?project_name=project&cluster_name=cluster&virtual_cluster_name=vamp-tutorial&application_name=application&service_name=tutorial-service
````

Alternatively you can check it using kubectl with

````
kubectl get svc tutorial-service -n-vamp-tutorial
````

It's now time to expose the Service externally by creating an Ingress.
You can achieve that by sending a POST request to the url 

````
http://localhost:8888/1.0/api/ingresses?project_name=project&cluster_name=cluster&virtual_cluster_name=vamp-tutorial&application_name=application&ingress_name=tutorial-ingress
````

with a valid token and the following body

````
{
  "paths": [
    {
      "path": "/.*",
      "port": 9090,
      "serviceName": "demo-service"
    }
  ],
  "metadata": {
    "meta1": "test1"
  }
}
````

When this step is done you should check the status of the Ingress, waiting for it to be assigned an ip.
As with the Service you can check through the API by executing

````
curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer your-token"  http://localhost:8888/1.0/api/ingresses?project_name=project&cluster_name=cluster&virtual_cluster_name=vamp-tutorial&application_name=application&ingress_name=tutorial-ingress
````

or through kubectl with

````
kubectl get ing tutorial-ingress -n-vamp-tutorial
````

When you have foudn the ip you can just call

````
http://1.2.3.4:9090
````

by replacing the example ip with your own you will get a response from the service. 
Since you just created a standard Service on top of your application, for the time being all request will be distributed equally aming the two Deployments that are part of the application.
To change that behaviour it is necessary to create a gateway.

### Creating a Gateway

In order to regulate access to the different versions of your application you now need to create a Gateway for it.
You can do that either through the ui or by simly sending a POST request to the path 

````
http://localhost:8888/1.0/api/gateways?project_name=project&cluster_name=cluster&virtual_cluster_name=vamp-tutorial&application_name=application&gateway_name=tutorial-gateway
````

with the following body

````
{
  "destination": "tutorial-service",
  "routes": [
    {
      "weights": [
        {
          "version": "version1",
          "weight": 50
        },
        {
          "version": "version2",
          "weight": 50
        }
      ]
    }
  ]
}
````

This will tell istio to distribute traffic equally among the two versions, so, for the time being you will not be able to see any difference.
You can however change the weight int he body and send a PUT request with the same url in order to experimnet with different settings.



### Performing a Canary Release