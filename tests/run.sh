#!/bin/bash

this_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $this_dir

source ../common.sh

run_commands "We have our ingress operational, let's load test it" "
ingress_ip=\$(kubectl get ingress toodo -n toodo --output 'jsonpath={.status.loadBalancer.ingress[0].ip}')
locust -f ./locustfile.py --host http://\${ingress_ip} --no-web -c 30 -r 5 --run-time 30s
"

run_commands "Now let's scale out our app to have more replicas. It's easiest just to do this
via kubectl here, but in a real situation we would probably go back to our kustomize config and
do it there as this would be a clearer flow for something like a GitOps approach" "
kubectl scale deployment toodo -n toodo --replicas=5
"

run_commands "Let's wait for the scaling to complete" "
watch 'kubectl get all -n toodo'
"

run_commands "And we'll run our same load tests against this scaled set" "
ingress_ip=\$(kubectl get ingress toodo -n toodo --output 'jsonpath={.status.loadBalancer.ingress[0].ip}')
locust -f ./locustfile.py --host http://\${ingress_ip} --no-web -c 30 -r 5 --run-time 30s
"
