# Chaos Mesh Remote Cluster management demo
The aim of this demo is to showcase the capabilities of [Chaos Mesh](https://chaos-mesh.org/), and especially its capabilities of orchestrating Chaos Experiments in remote clusters using the remoteCluster CRD and KubeConfig to connect with the kube-api in the remote cluster.
The demo features scripts creating two multi node clusters using [kind](https://kind.sigs.k8s.io/), installing Chaos mesh on one of them, connecting the two clusters together, deploying containers to the remote cluster and then orchestrating the Chaos Experiment on the remote cluster.

![Architecture diagram](images/chaos-mesh-multi-cluster.png)

# Quick start
Start by running the __kind-setup-clusters.sh__ script. 
```
./kind-setup-clusters.sh
```
Next, change context between the clusters (base and external) using this command:
```
kubectl config use kind-external
```
And observe the outcomes of the Chaos Experiment in the remote cluster. More Chaos Experiments will be added in the __K8s-yaml-files__ folder as support for remote experiments increases.

# Cleanup
After you're done with the experiments, remove the kind clusters (purging ALL kind clusters) using this script:
```
./teardown-kind.sh
```

# Requirements
To ensure the stability of the demo environment, make sure that you have these tools installed:
```
Docker >= 23.0.6
Kind >= v0.20.0
Helm >= 3.11.2
```

# Known issues
If the kubelet on the worker node on the External cluster will not join to the cluster, you might have reached maximum allowed number of concurrently opened files. To temporarily resolve this issue (until next OS restart), increase the hard limit:
```
sudo sysctl fs.inotify.max_user_watches=524288
sudo sysctl fs.inotify.max_user_instances=512
```
Alternatively, if you want these changes to be permanent, add these lines to /etc/sysctl.conf

# Expected outcome
After applying the Kubernetes secret with your auto generated kubeconfig for the external cluster, you should be able to describe the newly created RemoteCluster object, and the outcome should look similiar to this:

```
$ kubectl describe RemoteCluster external-cluster
Name:         external-cluster
Namespace:    
Labels:       <none>
Annotations:  <none>
API Version:  chaos-mesh.org/v1alpha1
Kind:         RemoteCluster
Metadata:
  Creation Timestamp:  2023-08-08T10:00:29Z
  Generation:          1
  Managed Fields:
    API Version:  chaos-mesh.org/v1alpha1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .:
          f:kubectl.kubernetes.io/last-applied-configuration:
      f:spec:
        .:
        f:kubeConfig:
          .:
          f:secretRef:
            .:
            f:key:
            f:name:
            f:namespace:
        f:namespace:
        f:version:
    Manager:         kubectl-client-side-apply
    Operation:       Update
    Time:            2023-08-08T10:00:29Z
  Resource Version:  4069
  UID:               5fcb080c-f7b7-441c-9ada-0536117d1f90
Spec:
  Kube Config:
    Secret Ref:
      Key:        kubeconfig
      Name:       chaos-mesh.kubeconfig
      Namespace:  default
  Namespace:      chaos-mesh
  Version:        2.6.1
Events:           <none>
```