# Eurozone EKS Cluster Calico Cloud
Eurozone EKS Cluster for Calico Cloud
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
eksctl create cluster  --name tigera-workshop  --with-oidc  --without-nodegroup
```
## Make the cluster EU compatible
If necessary, replace region-code with Region the cluster is in:
```
sed -i.bak -e 's/us-west-2/eu-west-1/' aws-k8s-cni.yaml
```
If necessary, replace <account> with Account from the EKS addon
```
sed -i.bak -e 's/602401143452/602401143452/' aws-k8s-cni.yaml
```
Address for Region that your cluster is in:
```
kubectl apply -f aws-k8s-cni.yaml
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
eksctl create nodegroup --cluster tigera-workshop --node-type t3.xlarge --nodes=3 --nodes-min=0 --nodes-max=3 --max-pods-per-node 58
```
## Configure Calico Cloud:
If your cluster has an existing version of Calico installed, verify that Calico components are not managed by any kind of Kubernetes reconciler / Addon-manager - https://docs.calicocloud.io/install/system-requirements#general
```
kubectl get addonmanager.kubernetes.io/mode -n tigera-operator tigera-operator -o yaml | grep ' addonmanager.kubernetes.io/mode:'
```
```
kubectl get addonmanager.kubernetes.io/mode -n kube-system calico-node -o yaml | grep ' addonmanager.kubernetes.io/mode:'
```
Get your Calico Cloud installation script from the Web UI - https://qq9psbdn-management.calicocloud.io/clusters/grid
```
curl https://installer.calicocloud.io/*****.*****-management_install.sh | bash
```
Check for cluster security group of cluster:
```
aws eks describe-cluster --name tigera-workshop --query cluster.resourcesVpcConfig.clusterSecurityGroupId
```
If your cluster does not have applications, you can use the following storefront application:
```
kubectl apply -f https://installer.calicocloud.io/storefront-demo.yaml
```
Create the Product Tier:
```
kubectl apply -f https://raw.githubusercontent.com/n1g3ld0uglas/CCSecOps/main/Tiers/product.yaml
```
## Zone-Based Architecture  
Create the DMZ Policy:
```
kubectl apply -f https://raw.githubusercontent.com/n1g3ld0uglas/CCSecOps/main/ZBA/dmz.yaml
```
Create the Trusted Policy:
```
kubectl apply -f https://raw.githubusercontent.com/n1g3ld0uglas/CCSecOps/main/ZBA/trusted.yaml
``` 
Create the Restricted Policy:
```
kubectl apply -f https://raw.githubusercontent.com/n1g3ld0uglas/CCSecOps/main/ZBA/restricted.yaml
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
Delete the Rogue Application:
```
kubectl delete -f https://installer.calicocloud.io/rogue-demo.yaml -n storefront
```
## Introduce Threat Feeds:
Create the FeodoTracker globalThreatFeed: 
``` 
kubectl apply -f https://raw.githubusercontent.com/n1g3ld0uglas/CCSecOps/main/ThreatFeeds/feodo-tracker.yaml
```
Verify the GlobalNetworkSet is configured correctly:
``` 
kubectl get globalnetworksets threatfeed.feodo-tracker -o yaml
``` 
Create the 'Security' Tier:
``` 
kubectl apply -f https://raw.githubusercontent.com/n1g3ld0uglas/CCSecOps/main/Tiers/security.yaml
```  
Applies to anything that IS NOT listed with the namespace selector = 'acme' 
```
kubectl apply -f https://raw.githubusercontent.com/n1g3ld0uglas/CCSecOps/main/SecurityPolicies/block-feodo.yaml
```
Determine a DNS provider of your cluster (mine is 'coredns')
```
kubectl get deployments -l k8s-app=kube-dns -n kube-system
```  
Allow traffic for Kube-DNS / CoreDNS:
```
kubectl apply -f https://raw.githubusercontent.com/n1g3ld0uglas/calico-enterprise-eks-workshop/main/policies/allow-kubedns.yaml
```
Create a Default-Deny in the 'Default' namespace:
```
kubectl apply -f https://raw.githubusercontent.com/n1g3ld0uglas/calico-enterprise-eks-workshop/main/policies/default-deny.yaml
```
## Anonymization Attacks:
Quarantine the Rogue Application: 
```
kubectl apply -f https://raw.githubusercontent.com/n1g3ld0uglas/CCSecOps/main/SecurityPolicies/quarantine.yaml
```  
Create the threat feed for EJR-VPN: 
``` 
kubectl apply -f https://docs.tigera.io/manifests/threatdef/ejr-vpn.yaml
```
Create the threat feed for Tor Bulk Exit Nodes: 
``` 
kubectl apply -f https://docs.tigera.io/manifests/threatdef/tor-exit-feed.yaml
```
Additionally, feeds can be checked using following command:
``` 
kubectl get globalthreatfeeds 
```  
## Deploy the Boutique Store Application

```
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml
```  
We also offer a test application for Kubernetes-specific network policies:
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/tigera-eks-workshop/main/demo/dev/app.manifests.yaml
``` 
Deploy policies for the Boutique application:
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/tigera-eks-workshop/main/demo/boutiqueshop/policies.yaml
``` 
Deploy policies for the K8 test application:
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/tigera-eks-workshop/main/demo/dev/policies.yaml
```
## Alerting
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/tigera-eks-workshop/main/demo/50-alerts/globalnetworkset.changed.yaml
```
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/tigera-eks-workshop/main/demo/50-alerts/unsanctioned.dns.access.yaml
```
```
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/tigera-eks-workshop/main/demo/50-alerts/unsanctioned.lateral.access.yaml
``` 
## Compliance Reporting
```   
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/tigera-eks-workshop/main/demo/40-compliance-reports/daily-cis-results.yaml
```
```  
kubectl apply -f https://raw.githubusercontent.com/tigera-solutions/tigera-eks-workshop/main/demo/40-compliance-reports/cluster-reports.yaml
```  

## Scaling-down the cluster
Scale deployment down to '0' replicas to avoid scaling conflicts:
```
kubectl scale deployments/coredns --replicas=0 -n kube-system
```
Find a Node Group associated with the cluster - tigera-workshop
```
eksctl get nodegroup --cluster tigera-workshop
```
Scale the Node Group ID to 0 nodes (which should stop K8 activity)
```
eksctl scale nodegroup --cluster tigera-workshop --name ng-590ee331 --nodes 0
```
