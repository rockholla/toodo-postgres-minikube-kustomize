#!/bin/bash

this_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $this_dir

source common.sh

run_commands "We'll start our cluster via minikube start" "
minikube start --insecure-registry '10.0.0.0/24'
"

run_commands "We can enable an ingress controller (nginx) pretty easily with minikube itself

For the sake of the interview, we could simply do other things more manually to enable/install an ingress controller
such as installing a helm chart for something like the nginx, ambassador, etc. ingress controllers which would also do the
job of the following" "
minikube addons enable ingress
"

run_commands "We're also going to enable a local docker registry in the cluster, and use that as our k8s container
image source. We'll build our container images to this location" "
minikube addons enable registry
docker run -d --name minikube-registry-proxy --rm -it --network=host alpine ash -c 'apk add socat && socat TCP-LISTEN:5000,reuseaddr,fork TCP:$(minikube ip):5000'
"

run_commands "We're going to wait for our internal registry to be ready" "
echo 'Waiting for the internal registry to be ready...'
while ! curl http://localhost:5000/v2/_catalog &>/dev/null; do
  sleep 5
done
"

info "Our cluster is now bootstrapped and ready, we can move on to building assets/artifacts and installing them"
