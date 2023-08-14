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

# Troubleshooting
If the experiment is created without issues but the pods in external clusters are not affected, make sure that the secret contains the correct KubeConfig file. To get the data from the secret and decode it, run this command:
```
kubectl get secret chaos-mesh.kubeconfig -o json | jq -r '.data.kubeconfig' | base64 -d
```
If the file contains the correct KubeConfig, proceed with the usual troubleshooting steps - describe the experiment, see if the labels match, etc. 

If your kind clusters time out while waiting for pods to be ready, check your internet download speed - base images for kind nodes take up to 900MB, and chaos mesh images can range from 45 to 450Mi. You can inspect image size using this command:

```
docker manifest inspect -v ghcr.io/chaos-mesh/chaos-daemon:v2.6.1 | grep size | awk -F ':' '{sum+=$NF} END {print sum}' | numfmt --to=iec-i
449Mi

```
To verify if the advertised control plane address matches the docker container address, use this command to quickly learn all container addresses on your computer:
```
docker inspect $(docker ps -q ) \
--format='{{ printf "%-50s" .Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}'
```


# Expected outcome
After creating the Kubernetes secret with your auto generated kubeconfig for the external cluster, you should see a remoteCluster object in the base cluster, as well as a podChaos object.
```
$ kubectl get remoteclusters
NAME               AGE
cluster-external   95s
$ kubectl get podchaos
NAME       AGE
pod-kill   56s

```
On the external cluster, you should be able to see the newly installed Chaos Mesh components in the chaos-mesh namespace

```
$ kubectl get po -n chaos-mesh
NAME                                        READY   STATUS    RESTARTS   AGE
chaos-controller-manager-8676548b77-m8xr4   1/1     Running   0          2m14s
chaos-controller-manager-8676548b77-n8v5w   1/1     Running   0          2m14s
chaos-controller-manager-8676548b77-t5w6f   1/1     Running   0          2m14s
chaos-daemon-5wx5p                          1/1     Running   0          2m14s
chaos-dashboard-64765f4dd6-qdl9l            1/1     Running   0          2m14s
chaos-dns-server-6fbbd87547-v4v97           1/1     Running   0          2m14s

```
As a result of the experiment, one of the pods will be recreated (indicated by the AGE column)
```
NAME                                 READY   STATUS              RESTARTS   AGE    IP           NODE              NOMINATED NODE   READINESS GATES
sample-deployment-57d84f57dc-dqm8z   0/1     ContainerCreating   0          0s     <none>       external-worker   <none>           <none>
sample-deployment-57d84f57dc-xltmt   1/1     Running             0          118s   10.244.1.4   external-worker   <none>           <none>
sample-deployment-57d84f57dc-zmmjx   1/1     Running             0          118s   10.244.1.3   external-worker   <none>           <none>

```

More experiments are described in [this](https://github.com/MA3CIN/chaos-mesh-remote-cluster-management-demo/tree/main/K8s-yaml-files/chaos-experiments-remote) folder.