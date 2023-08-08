#Two k8s clusters - base (1 Control plane / 0 Workers) and external (1 Control plane / 1 Worker). 
kind create cluster --config kind-base-cluster-config.yaml
kind create cluster --config kind-external-cluster-config.yaml

#Verfiy access to both clusters
kubectl config get-contexts

#Retrieve kubeconfig from external cluster, store it in a secret for Chaos mesh
kubectl config use kind-external
kubectl config view --raw --minify | base64 >> K8s-yaml-files/secret-kubeconfig.yaml

#Create deploy for external cluster
kubectl apply -f K8s-yaml-files/nginx-deployment.yaml

#Go to base cluster, install chaos mesh
kubectl config use kind-base
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm search repo chaos-mesh
kubectl create ns chaos-mesh
helm install chaos-mesh chaos-mesh/chaos-mesh -n=chaos-mesh --version 2.6.1
#Verify installation
kubectl get po -n chaos-mesh
echo "Chaos mesh installation completed"

#Add cluster to chaos mesh
kubectl apply -f K8s-yaml-files/remote-cluster.yaml
kubectl apply -f K8s-yaml-files/secret-kubeconfig.yaml

#Run chaos experiment
kubectl apply -f K8s-yaml-files/remote-chaos-experiment.yaml

#See results in external cluster (ammount of restarts for pods should change)
kubectl config use kind-external
kubectl get po -o wide