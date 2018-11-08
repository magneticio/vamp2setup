# Basic Tutorial

## Table of contents

* [Requirements](#requirements)
* [Creating a Virtual Cluster](#creating-a-virtual-cluster)
* [Creating an Application](#creating-an-application)
* [Exposing Your Application](#exposing-your-application)
* [Creating a Destination Rule](#creating-a-destination-rule)
* [Creating a Virtual Service](#creating-a-virtual-service)
* [Adding Routing Conditions](#adding-routing-conditions)
* [Performing a Canary Release](#performing-a-canary-release)
 * [Metric based canary release](#metric-based-canary-release)
 * [Custom canary release](#custom-canary-release)
* [Vamp Services](#vamp-services)
* [Creating an Experiment](#creating-an-experiment)
* [Setting up a custom data source](#setting-up-a-custom-data-source)

## Requirements

In this tutorial we will present all the steps required to use the canary releasing features of Vamp Lamia.

In order to perform a canary release you need to have an Application with at least two Deployments installed in the cluster.

Before you can create an Application, you need to set up a Virtual Cluster, or add the correct labels to an existing namespace.

## Creating a Virtual Cluster

In this section we guide you through the creation of a new Virtual Cluster, but you should be able to use these steps as a basis for updating a pre-existing namespace.

Lamia looks for some specific labels when detecting namespaces to be imported as Virtual Clusters.

These labels are:

- **vamp-managed**: this label indicates that Lamia should import and manage resources from this namespace. They are imported into a Virtual Cluster with the same name.
- **istio-injection**: this label indicates to Istio that it should perform automatic sidecar injection on the deployments in this namespace. 
- **cluster**: (optional) this is the name of the Cluster to which the Virtual Cluster belongs. Lamia creates this label will be automatically if it is missing.
- **project**: (optional) this name of the Project to which the Virtual Cluster belongs. Lamia creates this label will be automatically if it is missing.

Provided the first two labels are set, then, once Lamia is deployed, it will import all the resources from a namespace into the current Project and Cluster and add the two optinal labels to the namespace if they are missing.

You can use the sample [namespace.yaml](samples/namespace.yaml) to create a Virtual Cluster called `vamp-tutorial`.

````
kubectl create -f namespace.yaml
````

namespace.yaml:
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

Shortly after creating the namespace you will receive a notification from Lamia stating that a new Virtual Cluster has been found.
You can then click on List Virtual Cluster and see it as shown below.

![](images/screen1.png)

You can now edit the metadata of the Virtual Cluster.

For example, you can associate a Slack channel with a Virtual Cluster by adding the following keys:

- **slack_webhook**: a valid webhook
- **slack_channel**: the name of the channel you want to use. The default is `#vamp-notifications`

This will allow Lamia to send notifications to the specified Slack channel.

![](images/screen2.png)

## Creating an Application
Once the Virtual Cluster is set up, you need to sure that the Deployments for your Application are created and running.

All deployments require a set of three labels:

- **app**: identifies the Application to which the Deployment belongs.
- **deployment**: identifies the Deployment itself. This is used as a selector for the pods.
- **version**: the version of the Application to which the Deployment belongs. This is used by Istio to dispatch traffic.

You can use the sample [deployments.yaml](samples/deployments.yaml) to create an Application with two Deployments with the same app label and different deployment and version labels.

````
kubectl create -f deployments.yaml
````

deployment.yaml:
````
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: vamp-tutorial-app
    version: version1
  name: vamp-tutorial-deployment1
  namespace: vamp-tutorial
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vamp-tutorial-app
      deployment: vamp-tutorial-deployment1
      version: version1
  template:
    metadata:
      labels:
        app: vamp-tutorial-app
        deployment: vamp-tutorial-deployment1
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
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: vamp-tutorial-app
    version: version1
  name: vamp-tutorial-deployment2
  namespace: vamp-tutorial
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vamp-tutorial-app
      deployment: vamp-tutorial-deployment2
      version: version2
  template:
    metadata:
      labels:
        app: vamp-tutorial-app
        deployment: vamp-tutorial-deployment2
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

Assuming the command executed correctly, the deployments will be imported into Lamia.

First, open the Virtual Cluster tab, click on List Virtual Cluster and select `vamp-tutorial`.

Now, you can open the Application tab, click on List Application and you will be presented with the list of the available applications.

![](images/screen3.png)

Select `vamp-tutorial-app` to see the list of deployments you just created.

![](images/screen4.png)

You can compare this with the information presented through `kubectl` by running the following command:

````
kubectl get deploy -n=vamp-tutorial
````

## Exposing Your Application

Once you have your Application running, you can create a Service and a Gateway to expose the Application.

To do this using the UI, start by making sure that you have selected the Virtual Cluster and the Application that you want to expose.

Now open the Service tab, click Others - Service - Create Service and enter the following data, as shown in the screenshot below.

- **Name**: the name of the service, use `vamp-tutorial-service` for the tutorial 
- **Selectors**: the selectors for the Service, corresponding to the kubernetes selectors. In this case it is referencing the app name 
- **Ports: Number**: the port on which the Service will be exposed, use `9090` for the tutorial
- **Ports: Target Port**: the port on which the container accepts traffic, use `9090` for the tutorial
- **Ports: Protocol**: the network protocol the service uses, use `TCP` for the tutorial

![](images/screen5.png)

Then click Submit, to create the Service.
If there were no errors, a Service named `vamp-tutorial-service` will be accessible internally to the Cluster.
You can check the status of this Service using the UI by opening the Service tab, clicking on List Service and selecting `vamp-tutorial-service`.

![](images/screen6.png)

To check if the Service was created correctly, click Details. You also have the options to Edit or Delete the Service.

![](images/screen7.png)

You can compare this with the information presented through `kubectl` by running the following command:

````
kubectl get svc vamp-tutorial-service -n vamp-tutorial
````

Now it's time to expose the Service externally by creating an Gateway.
The first thing you neec to do, however, is provide the cluster configuration with a google project id and service account to allow access to google dns.
So go back to the Cluster list and select your cluster. Then, in the metadata, add two keys **google_service_account** and **google_project_id**, with the required values.
This is not strictly necessary for this tutorial but, if you don't do it, you will keep on getting notifications warning you that that information is missing.
Open the Gateway tab, click Create Gateway and enter the following data, as shown in the screenshot below.

![](images/screen8.png)

Then click Submit, to create the Gateway.
If there were no errors, the `vamp-tutorial-service` will now be available externally.
To find the external IP address the `vamp-tutorial-gateway` is using, open the Gateway tab and click on List Gateway.

![](images/screen9.png)

Then select Details and you will find the generated url for your Service.

![](images/screen10.png)

You can also retrieve this information using `kubectl` by running the following command:

````
kubectl get gateway vamp-tutorial-gateway -n vamp-tutorial
````

If the external IP address is `1.2.3.4` then you can access the service using the following URL:

````
http://1.2.3.4
````

By clicking on the url you will notice that the Service is still not reachable. 
The reason for that is that, unlike a Kuebrnetes Ingress, Istio Gateways need a Virtual Service bound to them in order to work properly.
Don't worry though, we will get to that soon.
Before continuing it's interesting to talk about what happened when the Gateway was created.
Normally all vamp Gateways rely on a single load balanced service residing in the istio-system namespace and named istio-ingressgateway. 
This means that, in most cases, you will create only one Gateway which will contain all hostnames you want to expose. 
This is an acceptable solution in some circumstances, but can be an hinderance in more complex scenarios, for example in cases where multiple persons or teams need to be able to configure hostnames.
While Vamp Lamia supports this more centralized setup, it also allows for the creation of multiple Gateways, each with its individual IP.
This is achieved by creating a new load balanced service and the underlying deployment in the istio-system every time a Gateway is created.
It's time to move on now and allow access to the Service through a new Virtual Service.
First of all, however, you need to setup a Destination Rule.

## Creating a Destination Rule

A Destination Rule is a Istio resource that abstracts from the set of labels defined on the Deployments underlying a Service, by defining one or more Subsets.
Subsets are then referenced by Virtual Services in order to route traffic through the Service.
You can create a new Destination Rule through Lamia by selecting Create DestinationRule and filling the presented form as shown below:

![](images/screen11.png)

When you filled in the required configuration, just click submit and then check the result in List DestinationRule - details.

![](images/screen12.png)

To retrieved the created resource through kubectl, run the following command:

````
kubectl get destinationrule vamp-tutorial-destination-rule -n vamp-tutorial
````

Now that the Destination Rule has been set up, it's time to work on the Virtual Service.

## Creating a Virtual Service

A Virtual Service can be used to regulate access to the different versions of an Application.

The Service we created to expose `vamp-tutorial-app` distributes all request equally between the two Deployments that are part of the application. 
To change this behaviour we need to create a Virtual Service that will sit in between the Gateway and the Service.

Open the Virtual Service tab, click Create Virtual Service and enter the following data, as shown in the screenshot below.

![](images/screen13.png)

Then click Submit, to create the Virtual Service.

If there were no errors, a Virtual Service named `vamp-tutorial-virtual-service` will now be available.

You can check the configuration of this Virtual Service using the UI by opening the Virtual Service tab, clicking on List Virtual Services and selecting `vamp-tutorial-virtual-service`. You should see a configuration like the one shown below.

![](images/screen14.png)

This configuration tells Istio to distribute traffic equally (50%/50%) among the two versions.

This is the same behaviour you would have with just the Service, so you won't be able to see any difference until you start experimenting with different weights.

**Keep in mind that the weights should always add up to 100, otherwise the configuration will not be applied.**

You can also retrieve the virtual service using `kubectl` by running the following command:

````
kubectl get virtualservice vamp-tutorial-virtual-service -n vamp-tutorial
````

It is also possible to add an additional gateway called mesh to the Virtual Service configuration.
Doing so enables the Virtual Service to be exposed internally, but mind the fact that it also requires you to provide a hostname, otherwise the Virtual Service creation will fail.

## Adding Routing Conditions

Let's try now adding more complex conditions to regulate the traffic on the Service.
In order to do that you will have to edit the Virtual Service configuration you just created.
Select List Virtual Service and click on edit.
Now specify the following condition and hit submit.

````
header "User-Agent" regex "^.*(Chrome).*$"  or header "User-Agent" regex "^.*(Nexus 6P).*$"
````

This will tell the Virtual Service to only pass requests to the Service when the `User-Agent` HTTP header contains either "Chrome" or "Nexus 6P".
You can test the effect of this condition from a browser or with a tool like `cURL`.
You can now check what happened on kubernetes by running the command:

````
kubectl get virtualservice vamp-tutorial-virtual-service -n vamp-tutorial -o yaml
````

You might also find yourself in a situation in which you want to specify different weights for each condtion.
In order to do that, click on the add button and you will be able to configure a new route with its own condition and set of weights.
It is also important to note that this allows for the selection of different destinations, effectively granting the ability to direct traffic towards multiple Services.
Fot those that dealt with Istio before or that tried the previous version of Vamp Lamia, this is a big change compared to Route Rules.
In the route you added, you can now specify the following condition:

````
header "User-Agent" regex "^(?:(?!Chrome|Nexus 6P).)*$"
````

You can then configure the route to forward all traffic towards subset1.
The virtual service configuration will then look like the one shown below.


![](images/screen15.png)


The effect of adding this new route is that requests with a `User-Agent` HTTP header that contains either "Chrome" or "Nexus 6P" will be equally split between subset1 and subset2, while all other requests will be sent to subset1.
Let's now edit again the gateway and remove the conditions you just specified and the extra route, before moving on to the next step.

## Performing a Canary Release

It's time to try something a bit more complex.
Vamp Lamia allow users to specify Policies on Virtual Services, i.e. automated processes than can alter the Virtual Service configuration over a period of time.
When specifying a new Policy of this kind there are several options, let's start with the simplest one.
Select Others - Virtual Services - List Virtual Service - edit and specify the values shown below in the Policies section, then submit.

![](images/screen16.png)

What you just did will trigger an automated process that will gradually shift the weights towards your target (subset2 in this case).
You will periodically get notifications that show the updates being applied to the virtual service.
As usual you will be able to check the weights status from the Virtual Service's detail.
It is also possible to configure the weight change at each update. The default value is 10, but you can specify it by adding the "step" parameter with the desired value.

This is, of course, a pretty limited example. Usually you would like to put some form of rule to decide which version should prevail.
Lamia can also help you in that scenario.
Go back to the edit screen, remove the policy and reset the weights to 50/50, then submit.

Let's say for example you want to rerun the previous scenario, but checking the healthiness of the two subsets before applying changes.
You can esaily achieve that by editing the Virtual Service as shown in the next image

![](images/screen17.png)

To verify that everything is working as expected just run this command

````
kubectl replace -f deployment-with-failures.yaml
````

Using the yaml provided in the sample folders, whose content you can find below

````
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: vamp-tutorial-app
    version: version2
  name: vamp-tutorial-deployment2
  namespace: vamp-tutorial
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vamp-tutorial-app
      deployment: vamp-tutorial-deployment2
      version: version2
  template:
    metadata:
      labels:
        app: vamp-tutorial-app
        deployment: vamp-tutorial-deployment2
        version: version2
    spec:
      containers:
      - env:
        - name: SERVICE_NAME
          value: version2
        - name: FAILURE
          value: "0.3"
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

This will inject errors on 30% of the requests going towards deployment2 and, consequently, cause the Policy to shift weights towards subset1, despite the fact that subset2 is the declared target.
Obviously nothing will happen unless you actually send requests to the service.
There's an easy way to do that thanks to the specific image we are using for this tutorial.
Go to List Gateway and open the details for the Gateway you previously created and click the link to your Service and add /ui at the end to get to this ui.

![](images/screen18.png)

Now just input the url to your service ( http://vamp-tutorial-service:9090 ) into the empty field and this will both trigger continuous requests towards the service and show the real distribution over the two deployments, including the errors (highlighted in red).
This tool is not really part of Vamp Lamia, but it comes in handy to test the behaviour of Virtual Services and Istio.

![](images/screen19.png)

You can check the distribution of traffic both from the tool itself or by selecting List Virtual Service and clicking on metrics.
This will present you with the interface shown below.

![](images/screen20.png)

After you are done experimenting with this Policy you can edit the Virtual Service back to normal, but keep the deployments in the current state for the next steps.

### Metric based canary release

You managed to create a canary release Policy that takes into account the health of your application, but what if you wanted to use some different metric to control the behaviour of the policy?
In order to do that you can edit the Virtual Service as shown below

![](images/screen21.png)

As you can see besides changing the type of Policy you also need to specify the **metric** parameter which will tell Lamia which metric or combination of metrics to use.
In this scenario the value we are using is:

````
internal_upstream_rq_2xx / upstream_rq_total
````

In this case we are basically replicating the behaviour from the health based canary release by calculating the ratio of successful responses over the total number of requests
Metrics names are loosely based on Prometheus metrics names stored by Envoy (they are usually the last part of the metric name).
Some of the available metrics are:

- **internal_upstream_rq_200**
- **internal_upstream_rq_2xx**
- **internal_upstream_rq_500**
- **internal_upstream_rq_503**
- **internal_upstream_rq_5xx**
- **upstream_rq_total**

This type of Policy, however, comes with a limitation: you can only specify one condition, that is "select the version with the best metric".
What if you wanted to have more complex conditions?

### Custom canary release

To do that you would have to use the last type of Policy available at the moment and configure the Gateway as shown below,
by specifying the condition

````
if ( ( metric "vamp-tutorial-service" 9090 "subset1" "internal_upstream_rq_2xx" / metric "vamp-tutorial-service" 9090 "subset1" "upstream_rq_total" ) > ( metric "vamp-tutorial-service" 9090 "subset2" "internal_upstream_rq_2xx" / metric "vamp-tutorial-service" 9090 "subset2" "upstream_rq_total" ) ) { result = "vamp-tutorial-service 9090 subset1"; } else if ( ( metric "vamp-tutorial-service" 9090 "subset1" "internal_upstream_rq_2xx" / metric "vamp-tutorial-service" 9090 "subset1" "upstream_rq_total" ) < ( metric "vamp-tutorial-service" 9090 "subset2" "internal_upstream_rq_2xx" / metric "vamp-tutorial-service" 9090 "subset2" "upstream_rq_total" ) ) { result = "vamp-tutorial-service 9090 subset2"; } else { result = nil; } result
````

in the value field for the metric parameter

![](images/screen22.png)

As you can probably understand by looking at the expression above, this Policy will again replicate the behaviour of the previous Policies, but it will allow for much greater flexibility.
You will now be able to specify different versions based on the conditions you are verifying and also to return no version at all (by returning nil) when you want the Policy to not apply any change.

You can now keep on experimenting with the Virtual Service, trying new things. Keep in mind that if you want to return the deployments to the previous state (in which no errors are returned) you can do that by executing

````
kubectl replace -f deployments.yaml
````

## Vamp Services

Setting up all of the above for every new service can be pretty tedious and time consuming. To solve this problem Vamp Lamia provides its users with the ability to create Vamp Services.
Vamp Services are abstractions that group together a Service, a Destination Rule and a Virtual Service.
To create a Vamp Service, select Vamp Service - Create Vamp Service from the menu and fill out the form as shown below.

![](images/screen44.png)

As you can see we are referencing app1 in the application and specifiying basically the same values we used in the Service, Virtual Service and Destination rule examples from the previous sections.
Once you submit a new Service, Destination Rule and Virtual Service with the name vamp-service-1 will be created automatically.
At this point you can add the new hostname defined in the Vamp Service specification to gateway gw-1 and you will be able to normally access the new Service.
Note that currently Vamp Services do not support the policies we just shown for Virtual Services, although there are plans to implement them in the near future.
On the other hand Vamp Services can use a much more powerful feature, that is Experiments.

## Creating an Experiment

Experiments are a new feature introduced with Lamia 0.2.0.
They allow to quickly set up A/B testing policies over different versions of the same service.
In order to try out Experiments you can execute [demo-setup.sh](samples/experiment-demo/demo-setup.sh).
If everything works correctly, this will produce the following output

````
namespace "vamp-demo" created
deployment "deployment1" created
deployment "deployment2" created
````

At this point you will have a new namespace named vamp-demo containing two versions of a simple e-commerce, that wil be imported by Lamia into a single application named application.
You will also notice a second application named vamp-datasource-app. It will be used in the next section, so you can ignore it for now.
Now, before you can proceed with setting up the Experiment, you will first have to create a new Gateway and Vamp Service for the Experment to use.
Since you already did that in the previous steps of this tutorial, you should be able to go through it quickly by referring to the configurations shown below.
Just make sure to select the new Virtual Cluster vamp-demo before going onward.
Also mind the fact that you should use a different hostname than the one we are using in the example.

![](images/screen23.png)

![](images/screen24.png)

Once everything is ready you can set up the Experiment itself.
Select Create Experiment and submit the following configuration.

![](images/screen26.png)

To clarify a bit what is going to happen when you submit, let's first go through the purpose of each field:

- **Vamp Service Name**: the name of the Vamp Service on which you want to run the A/B testing.
- **Period in minutes**: the time interval in minutes after which periodic updates to the configuration will happen.
- **Step**: the amount by which the route's weights will shift at each update.
- **Tags**: a descriptive value for a specific version of the service.
- **Subset**: the subset of the service.
- **Target**: the url that we want the users to reach to consider the test a success.

When the form has been correctly filled and submitted the Experiment will first save its configuration and then update the related Vamp Service with a new configuration.
By clicking on List Virtual Service and looking for the shop-vamp-service Virtual Service, you will be able to check its configuration, although you won't be able to change it or delete it directly.
Below you can see how ths configuraiton should look:

![](images/screen27.png)

We realise this configuration can feel rather obscure, so let's walk through it together.
The Virtual Service defines three routes. The first two are easy to understand: they each lead to one of the deployed versions. The third one is evenly load balancing between two versions of a Cookie Server.
The purpose of this configuration is to direct new visitors towards the Cookie Server which will then set cookies identifying them as a specific user and assigning them to one of the configured subsets.
Once this is done, the Cookie Server redirects the user back to the original url, sending him back through the Virtual Services. This time, however, having a Subset Cookie, one of the conditions set on the first two routes applies and the user is forwarded to a specific version of the landing page. This is seamless in browsers, so users don't experience any interruption, and adds a neglectable overhead, since it affect only one call per user .
Thanks to our reliance on cookies, we are able to provide users with a consistent experience while continuing our test, meaning that subsequent requests coming from the same user in a short period of time will always go to the same version.
Depending on the test results, the policy defined on the Virtual Service will then move more users to more successful version, i.e. versions with a better ratio of users that reached the target over total number of users that reached the landing page.
This is of course achieved by changing the weights of the Cookie Servers routes according to the Step value defined in the Experiment configuration.

Besides the Vamp Service itself, the Experiment is also managing one Cookie Server Deployment per Subset involved in the test.


## Setting up a custom data source

The previous example relies on Elasticsearch in order to obtain the data required to shift the Virtual Service's configuration as desired.
But what if one wanted to use some other data source or, rather, to use entirely different types of data?
That is also achievable through Vamp Lamia thanks to its support for custom data sources.
Vamp Lamia has been developed with the clear goal of making it as modular as possible. For that reason its architecture is based on the usage of Drivers, that is components that can be easily replaced for each of the entities that Vamp Lamia is managing. 
In this specific case you would want to replace the Driver responsible for gathering metrics from Elasticsearch with another one that can interface with a custom data source.
That can be very easily done, provided the data source meets some requirements. 
For the sake of simplicity we are providing a simple nodejs webservice that will return random values at each requests.
Everything that is required of this webservice is that it exposes a "/stats" endpoint that will respond to a request of the kind "/stats?subset=subset1" with the data pertaining to subset1 presented in json format. 
You can see below an example of such a json.

````
{
  average: 1.2,
  standardDeviation: 0.8,
  numberOfElements: 3875
}
````

In this sample the number of elements is the number of users that got to the landing page of the service we are testing, while the average and standard deviation are calculated over the number of successful interactions of each user, i.e. the interactions that reached the specified target.
If you run the [demo-setup.sh](samples/experiment-demo/demo-setup.sh) script in the previous step, then the mock data source will already be deployed and all you need to do is set up the Experiment using the following configuration

![](images/screen43.png)

Compared to the configuration used in the previous example the notable differences are that in this case you will be specifying a Data Source Path with value **http://vamp-datasource.vamp-test1.svc.cluster.local:9090/stats**, to tell Vamp to use the data source exposed by that Service, and you will also add a new metadata with key **complexmetricsdriver** and value **custom** in order to have Lamia use the custom implementation of the metrics driver. 
Once the experiment has been set up, it will behave in the same way as the previous one, but using the newly defined data source.
