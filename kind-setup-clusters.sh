#!/bin/bash

set -e
set -o pipefail
set -o errexit

GREEN='\033[1;32m'
NoColor='\033[0m'
function output_information () { 
    echo -e "${GREEN}$1${NoColor}"
}

#Two k8s clusters - base (1 Control plane / 0 Workers) and external (1 Control plane / 1 Worker). 
./kind-files/create-clusters.sh
output_information "Cluster creation completed"

#Verfiy access to both clusters
kubectl config get-contexts

#Retrieve kubeconfig from external cluster, store it in a secret for Chaos mesh
kubectl config use kind-external

external_control_plane_address=$(docker inspect \
  -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' external-control-plane)

kubectl config view --raw --minify | sed "s/127.0.0.1/$external_control_plane_address/g" > debug/kubeconfig_output.txt


kubectl config view --raw --minify | sed "s/127.0.0.1/$external_control_plane_address/g" | base64 -w 0 >> K8s-yaml-files/secret-kubeconfig.yaml


#Create deploy for external cluster, create namespace for chaos-mesh
kubectl apply -f K8s-yaml-files/nginx-deployment.yaml
kubectl create namespace chaos-mesh
kubectl wait pods -n default -l app=nginx --for condition=Ready --timeout=600s 
output_information "External cluster workload deployment completed"

#Go to base cluster, install chaos mesh
kubectl config use kind-base
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm search repo chaos-mesh
kubectl create ns chaos-mesh
helm install chaos-mesh chaos-mesh/chaos-mesh -n=chaos-mesh --version 2.6.1 --set dashboard.securityMode=false

#Verify installation
kubectl wait pods -n chaos-mesh -l app.kubernetes.io/instance=chaos-mesh --for condition=Ready --timeout=600s 
kubectl get po -n chaos-mesh
output_information "Chaos mesh installation on base cluster completed"

#Add cluster to chaos mesh
kubectl apply -f K8s-yaml-files/secret-kubeconfig.yaml
kubectl apply -f K8s-yaml-files/remote-cluster.yaml

#Run chaos experiment
kubectl apply -f K8s-yaml-files/remote-chaos-experiment.yaml

#See results in external cluster (ammount of restarts for pods should change)
kubectl config use kind-external
kubectl get po -o wide