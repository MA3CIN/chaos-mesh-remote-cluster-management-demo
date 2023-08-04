#Two k8s clusters - base (1 Control plane / 0 Workers) and external (1 Control plane / 1 Worker). 
kind create cluster --config kind-base-cluster-config.yaml
kind create cluster --config kind-external-cluster-config.yaml