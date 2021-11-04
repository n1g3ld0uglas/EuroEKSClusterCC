# Kubernetes Security Workshop | Calico Cloud
This repository was created for a Kubernetes security workshop on the 21st of October 2021.

## Download EKSCTL
Download and extract the latest release of eksctl with the following command
```
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
``` 
Move the extracted binary to /usr/local/bin.
```
sudo mv /tmp/eksctl /usr/local/bin
``` 
Test that your installation was successful with the following command
```
eksctl version
``` 
First, create an Amazon EKS cluster without any nodes
```
eksctl create cluster  --name nigel-eks-cluster  --with-oidc  --without-nodegroup
```

## Create a node group for the cluster
Confirm regions are configured correctly:
```
kubectl get node -o=jsonpath='{range .items[*]}{.metadata.name}{"\tProviderId: "}{.spec.providerID}{"\n"}{end}'
```
Verify VPC Networking & CNI plugin is used. Confirm the aws-node pod exists on each node
```
kubectl get pod -n kube-system -o wide
```
Finally, add nodes to your EKS cluster
```
eksctl create nodegroup --cluster nigel-eks-cluster --node-type t3.xlarge --nodes=3 --nodes-min=0 --nodes-max=3 --max-pods-per-node 58
```
Check pod status again:  
```
kubectl get pod -n kube-system -o wide
```

## Configure Calico Cloud:
Get your Calico Cloud installation script from the Web UI - https://qq9psbdn-management.calicocloud.io/clusters/grid
```
curl https://installer.calicocloud.io/*****.*****-management_install.sh | bash
```
Check for cluster security group of cluster:
```
aws eks describe-cluster --name nigel-eks-cluster --query cluster.resourcesVpcConfig.clusterSecurityGroupId
```
If your cluster does not have applications, you can use the following storefront application:
```
kubectl apply -f https://installer.calicocloud.io/storefront-demo.yaml
```
Create the Product Tier:
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/product.yaml
```  
## Zone-Based Architecture  
Create the DMZ Policy:
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/dmz.yaml
```
Create the Trusted Policy:
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/trusted.yaml
``` 
Create the Restricted Policy:
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/restricted.yaml
```

#### Confirm all policies are running:
```
kubectl get networkpolicies.p -n storefront -l projectcalico.org/tier=product
```

## Allow Kube-DNS Traffic: 
We need to create the following policy within the ```tigera-security``` tier <br/>
Determine a DNS provider of your cluster (mine is 'coredns' by default)
```
kubectl get deployments -l k8s-app=kube-dns -n kube-system
```    
Allow traffic for Kube-DNS / CoreDNS:
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/allow-kubedns.yaml
```
  
## Increase the Sync Rate: 
``` 
kubectl patch felixconfiguration.p default -p '{"spec":{"flowLogsFlushInterval":"10s"}}'
kubectl patch felixconfiguration.p default -p '{"spec":{"dnsLogsFlushInterval":"10s"}}'
kubectl patch felixconfiguration.p default -p '{"spec":{"flowLogsFileAggregationKindForAllowed":1}}'
```
Introduce the Rogue Application:
```
kubectl apply -f https://installer.calicocloud.io/rogue-demo.yaml -n storefront
``` 
Quarantine the Rogue Application: 
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/quarantine.yaml
```
## Introduce Threat Feeds:
Create the FeodoTracker globalThreatFeed: 
``` 
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/threatfeed/feodo-tracker.yaml
```
Verify the GlobalNetworkSet is configured correctly:
``` 
kubectl get globalnetworksets threatfeed.feodo-tracker -o yaml
``` 

Applies to anything that IS NOT listed with the namespace selector = 'acme' 

```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/threatfeed/block-feodo.yaml
```

Create a Default-Deny in the 'Default' namespace:

```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/default-deny.yaml
```

## Anonymization Attacks:  
Create the threat feed for ```EJR-VPN```: 

``` 
kubectl apply -f https://docs.tigera.io/manifests/threatdef/ejr-vpn.yaml
```

Create the threat feed for ```Tor Bulk Exit``` Nodes: 

``` 
kubectl apply -f https://docs.tigera.io/manifests/threatdef/tor-exit-feed.yaml
```

Additionally, feeds can be checked using following command:

``` 
kubectl get globalthreatfeeds 
```

As you can see from the below example, it's making a pull request from a dynamic feed and labelling it - so we have a static selector for the feed:
```
apiVersion: projectcalico.org/v3
kind: GlobalThreatFeed
metadata:
  name: ejr-vpn
spec:
  pull:
    http:
      url: https://raw.githubusercontent.com/ejrv/VPNs/master/vpn-ipv4.txt
  globalNetworkSet:
    labels:
      feed: ejr-vpn
```
  
## Configuring Honeypods

Create the Tigera-Internal namespace and alerts for the honeypod services:

```
kubectl apply -f https://docs.tigera.io/manifests/threatdef/honeypod/common.yaml
```

Expose a vulnerable SQL service that contains an empty database with easy access.<br/>
The pod can be discovered via ClusterIP or DNS lookup:

```
kubectl apply -f https://docs.tigera.io/manifests/threatdef/honeypod/vuln-svc.yaml 
```

Verify the deployment - ensure that honeypods are running within the tigera-internal namespace:

```
kubectl get pods -n tigera-internal -o wide
```

And verify that global alerts are set for honeypods:

```
kubectl get globalalerts
```

  
  
  
## Deploy the Boutique Store Application

```
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml
```  

We also offer a test application for Kubernetes-specific network policies:

```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/workloads/test.yaml
```

#### Block the test application

Deny the frontend pod traffic:

```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/frontend-deny.yaml
```

Allow the frontend pod traffic:

```
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/frontend-deny.yaml
```

#### Introduce segmented policies
Deploy policies for the Boutique application:
  
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/boutique-policies.yaml
``` 
Deploy policies for the K8 test application:
  
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/test-app.yaml
```
  
## Alerting
  
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/alerting/networksets.yaml
```
  
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/alerting/dns-access.yaml
```
  
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/alerting/lateral-access.yaml
``` 
  
## Compliance Reporting
  
```   
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/reporting/daily-cis-report.yaml
```
  
```  
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/reporting/half-hour-inventory-report.yaml
```
  
``` 
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/reporting/half-hour-network-access.yaml  
```
  
Run the below .YAML manifest if you had configured audit logs for your EKS cluster:<br/>
https://docs.tigera.io/compliance/compliance-reports/compliance-managed-cloud#enable-audit-logs-in-eks

```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/reporting/half-hour-policy-audit.yaml  
```

## Securing EKS hosts:

Automatically register your nodes as Host Endpoints (HEPS). To enable automatic host endpoints, edit the default KubeControllersConfiguration instance, and set spec.controllers.node.hostEndpoint.autoCreate to true:

```
kubectl patch kubecontrollersconfiguration default --patch='{"spec": {"controllers": {"node": {"hostEndpoint": {"autoCreate": "Enabled"}}}}}'
```

Add the label kubernetes-host to all nodes and their host endpoints:
```
kubectl label nodes --all kubernetes-host=  
```
This tutorial assumes that you already have a tier called 'aws-nodes' in Calico Cloud:  
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/node-tier.yaml
```
Once the tier is created, Build 3 policies for each scenario: 
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/etcd.yaml
```
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/master.yaml
```
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/worker.yaml
```

#### Label based on node purpose
To select a specific set of host endpoints (and their corresponding Kubernetes nodes), use a policy selector that selects a label unique to that set of host endpoints. For example, if we want to add the label environment=dev to nodes named node1 and node2:

```
kubectl label node ip-192-168-22-46.eu-west-1.compute.internal env=master
kubectl label node ip-192-168-62-23.eu-west-1.compute.internal env=worker
kubectl label node ip-192-168-74-2.eu-west-1.compute.internal env=etcd
```

Confirm the labels are now assigned:

```
kubectl get nodes --show-labels | grep etcd
```

## Dynamic Packet Capture:

Check that there are no packet captures in this directory  
```
ls *pcap
```
A Packet Capture resource (PacketCapture) represents captured live traffic for debugging microservices and application interaction inside a Kubernetes cluster.</br>
https://docs.tigera.io/reference/calicoctl/captured-packets  
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/workloads/packet-capture.yaml
```
Confirm this is now running:  
```  
kubectl get packetcapture -n storefront
```
Once the capture is created, you can delete the collector:
```
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/workloads/packet-capture.yaml
```
#### Install a Calicoctl plugin  
Use the following command to download the calicoctl binary:</br>
https://docs.tigera.io/maintenance/clis/calicoctl/install#install-calicoctl-as-a-kubectl-plugin-on-a-single-host
``` 
curl -o kubectl-calico -O -L  https://docs.tigera.io/download/binaries/v3.7.0/calicoctl
``` 
Set the file to be executable.
``` 
chmod +x kubectl-calico
```
Verify the plugin works:
``` 
./kubectl-calico -h
``` 
#### Move the packet capture
```
./kubectl-calico captured-packets copy storefront-capture -n storefront
``` 
Check that the packet captures are now created:
```
ls *pcap
```
#### Install TSHARK and troubleshoot per pod 
Use Yum To Search For The Package That Installs Tshark:</br>
https://www.question-defense.com/2010/03/07/install-tshark-on-centos-linux-using-the-yum-package-manager
```  
sudo yum install wireshark
```  
```  
tshark -r frontend-75875cb97c-2fkt2_enib222096b242.pcap -2 -R dns | grep microservice1
``` 
```  
tshark -r frontend-75875cb97c-2fkt2_enib222096b242.pcap -2 -R dns | grep microservice2
```  

## Anomaly Detection:

For the managed cluster (like Calico Cloud):

If it is a managed cluster, you have to set up the CLUSTER_NAME environment variable. 
``` 
curl https://docs.tigera.io/manifests/threatdef/ad-jobs-deployment-managed.yaml -O
``` 

Grab your pull secret from the ```tigera-system``` namespace:
``` 
kubectl get secret tigera-pull-secret -n tigera-system -o yaml > secret.yaml
``` 

Swap the name of your cluster into the managed deployment manifest:
``` 
sed -i 's/CLUSTER_NAME/nigel-eks-cluster/g' ad-jobs-deployment-managed.yaml
``` 

If it is a managed cluster, you have to set up the CLUSTER_NAME environment variable. </br>
Automated the process (keep in mind the cluster name specified is - ``` nigel-eks-cluster``` 
``` 
kubectl apply -f ad-jobs-deployment-managed.yaml
``` 

To get this real pod name use:
``` 
kubectl get pods -n tigera-intrusion-detection -l app=anomaly-detection
``` 

Use this command to read logs:
``` 
kubectl logs ad-jobs-deployment-86db6d5d9b-fmt5p -n tigera-intrusion-detection | grep INFO
``` 

If anomalies are detected, you see a line like this:
``` 
2021-10-14 14:06:13 : INFO : AlertClient: sent 5 alerts with anomalies.
``` 

![anomaly-detection-alert](https://user-images.githubusercontent.com/82048393/137357313-e29f6158-5cd9-4f3a-b68f-466331d85186.png)

A description of the alert started with the ```anomaly_detection.job_id``` where ```job_id``` can be found on Description page

## Wireguard In-Transit Encryption:

To begin, you will need a Kubernetes cluster with WireGuard installed on the host operating system.</br>
https://www.tigera.io/blog/introducing-wireguard-encryption-with-calico/
```
sudo yum install kernel-devel-`uname -r` -y
sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
sudo curl -o /etc/yum.repos.d/jdoss-wireguard-epel-7.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
sudo yum install wireguard-dkms wireguard-tools -y
```
Enable WireGuard encryption across all the nodes using the following command:
```
kubectl patch felixconfiguration default --type='merge' -p '{"spec":{"wireguardEnabled":true}}'
```
To verify that the nodes are configured for WireGuard encryption:
```
kubectl get node ip-192-168-30-158.eu-west-1.compute.internal -o yaml | grep Wireguard
```
Show how this has applied to traffic in-transit:
```
sudo wg show
```

## Cleaner Script (Removes unwanted policies after workshop)
```
wget https://raw.githubusercontent.com/n1g3ld0uglas/EuroEKSClusterCC/main/cleaner.sh
```

```
chmod +x cleaner.sh
```

```
./cleaner.sh
```


## Scale down your EKS Cluster
Confirm the cluster name
```
eksctl get cluster
```
Find the Node Group ID associated with the cluster	
```
eksctl get nodegroup --cluster nigel-eks-cluster2
```
Scale the Node Group down to 0 nodes to reduce AWS costs
```
eksctl scale nodegroup --cluster nigel-eks-cluster2 --name ng-f22ea39f --nodes 0
```
