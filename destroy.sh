#!/bin/bash

this_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $this_dir

source common.sh

run_commands "Bringing it all down" "
minikube delete
docker rm -f minikube-registry-proxy
"
