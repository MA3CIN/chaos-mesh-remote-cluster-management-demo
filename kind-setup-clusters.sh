#Two k8s clusters - base (1 Control plane / 0 Workers) and external (1 Control plane / 1 Worker). 
kind create cluster --config kind-base-cluster-config.yaml
kind create cluster --config kind-external-cluster-config.yaml

#Verfiy access to both clusters
kubectl config get-contexts

#retrieve kubeconfig from external cluster
kubectl config use-context kind-external
kubectl config view --raw --minify | base64 >> K8s-yaml-files/secret-kubeconfig.yaml