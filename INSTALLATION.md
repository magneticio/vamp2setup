# Installation

## Table of Contents

* [Prerequisites](#prerequisites)
* [Installation steps](#installation-steps)
 * [In cluster installation](#in-cluster-installation)
    * [External database](#external-database)
 * [Out of Cluster installation](#out-of-cluster-installation)

## Prerequisites 
* An existing kubernetes cluster with Kubernetes version 1.9 or above installed. 
* The current version has been tested only on Google Cloud, so it's recommended that you use that as well, in order to avoid issues.
* Kubectl should be installed on the local computer with authorizations to access the cluster.

**Keep in mind that this is an Alpha release targeted at developers and dev/ops. Many of the features are currently limited and will likely change and improve in future versions.**

## Installation steps

The first step is, of course, to git clone this repo or download [setup zip](https://github.com/magneticio/vamp2setup/archive/0.6.1.zip)

```
git clone https://github.com/magneticio/vamp2setup.git
```
or
```
wget https://github.com/magneticio/vamp2setup/archive/0.1.96.zip
unzip 0.1.96.zip
```

After that you should decide whether you want to run vamp inside a cluster or outside of it.

### In cluster installation

Running Vamp Lamia inside a cluster is pretty straightforward and it just requires you to connect to the cluster via kubectl and run:

```
./vamp-bootstrap.sh
```

Enter a new password when asked and re-enter it for confirmation.

When the installation procedure is complete, the installer will tell you where to connect by printing an url similar to the one shown below:

```
use http://111.222.333.444:8888/ui/#/login to connect
```

If you need to retrieve the IP afterwards you can do it via kubectl

```
kubectl get svc vamp -n=vamp-system
```

Copy the url and paste it on your browser to login and start using.

The default username is root.

#### External database

Installing Vamp Lamia inside a cluster will also, by default, create a mongodb running inside the cluster, where all Vamp Lamia configurations will be stored.
It is also possible to use an external mongodb. 
To achieve this run:

```
./vamp-bootstrap.sh --externaldb --dburl mongodb://someurl --dbname db-name
```

Where someurl is your mongodb instance url and db-name is obviously the db name you want to use.
Once installed inside the cluster Vamp Lamia will automatically create a 

### Out of Cluster installation

If you'd rather have Vamp Lamia run outside the cluster, you should instead run:

```
./vamp-bootstrap.sh --outcluster  --dburl mongodb://someurl --dbname db-name
```

Where someurl is your mongodb instance url and db-name is obviously the db name you want to use.
