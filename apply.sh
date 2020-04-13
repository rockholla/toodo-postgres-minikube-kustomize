#!/bin/bash

this_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $this_dir

source common.sh

info "We have some source locations, which would be git repos we would use for building
out whatever artifacts we need for install/upgrade time:

 * source/app-postgres: for building out our container image
 * source/kustomize-config: our kustomize config source used in generating our k8s resources to install or patch"

run_commands "Let's start by building artifacts for source/app-postgres which will:

 * pull the postgres:12.2 public image and put it into our local minikube registry
 * clone the toodo app repo so we can build the todoo app container image

It's worth noting that the master branch of the toodo app is broken, the Dockerfile still trying to
use go dep when the rest of the source has been moved to go mod, so we'll patch the Dockerfile as well" "
docker pull postgres:12.2
docker tag postgres:12.2 localhost:5000/postgres:12.2
docker push localhost:5000/postgres:12.2
cd $this_dir/source/app-postgres
if [ ! -d ./toodo ]; then
  git clone https://github.com/gobuffalo/toodo
fi
cd toodo
git reset --hard HEAD
git checkout master
git pull origin master
cd ..
cp Dockerfile.fixed ./toodo/Dockerfile
cp database.yml ./toodo/database.yml
docker build -t localhost:5000/gobuffalo/toodo:example ./toodo
docker push localhost:5000/gobuffalo/toodo:example
"

info "Now that we have our app and postgres artifacts built and staged, we can move on to generating the
k8s resources via kustomize. We want some build-time variables to be injected/made available:
"
read -p "What will the postgres db username be for the toodo database? " postgres_username
read -s -p "What will the postgres db password be for the toodo database? " postgres_password

run_commands "We can write our postgres user/password values to an ignored files in our kustomize-config source
and kustomize will use them to generate the appropriate resources to be applied to the cluster" "
cd $this_dir
cat > $this_dir/source/kustomize-config/app-secrets.patch.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: toodo-secrets
data:
  DATABASE_URL: $(echo -n postgres://${postgres_username}:${postgres_password}@postgres:5432/toodo?sslmode=disable | base64 -w 0)
EOF
cat > $this_dir/source/kustomize-config/postgres-configmap.patch.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres
data:
  POSTGRES_DB: toodo
  POSTGRES_USER: ${postgres_username}
  POSTGRES_PASSWORD: ${postgres_password}
EOF
"

run_commands "Our kustomize-config is ready to be rendered and applied. Let's first look at the full contents of
our rendered kustomize config" "
kustomize build $this_dir/source/kustomize-config
"

run_commands "Now we can simply apply this all using kubectl apply" "
kustomize build $this_dir/source/kustomize-config | kubectl apply -f -
"

run_commands "Let's watch our toodo namespace to make sure everything comes up OK" "
watch 'kubectl get pvc,all -n toodo'
"

run_commands "Now, let's just make sure your ingress works by first getting the ingress address
and then using it to see what an http request to it gives us" "
ingress_ip=\$(kubectl get ingress toodo -n toodo --output 'jsonpath={.status.loadBalancer.ingress[0].ip}')
curl http://\${ingress_ip}/
"

info "We're now ready to move over to running some load tests, scaling out our app, etc."
