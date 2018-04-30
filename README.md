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

Copy the url and paste on your browser and add /ui

http://111.122.133.144:8888/ui/#/login to login and start using.

PS: username is root
