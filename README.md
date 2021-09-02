# EuroEKSClusterCC
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

If necessary, replace <region-code> with Region the cluster's in
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
eksctl create nodegroup --cluster nigel-eks-cluster --node-type t3.xlarge --max-pods-per-node 58
```

## Configure Calico Cloud:

If your cluster has an existing version of Calico installed, verify that Calico components are not managed by any kind of Kubernetes reconciler (for example, Addon-manager) - https://docs.calicocloud.io/install/system-requirements#general
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
kubectl apply -f https://raw.githubusercontent.com/n1g3ld0uglas/CCSecOps/main/Tiers/product.yaml
```

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
kubectl apply -f https://installer.calicocloud.io/rogue-demo.yaml 
```
 
Quarantine the Rogue Application: 
```
kubectl apply -f https://raw.githubusercontent.com/n1g3ld0uglas/CCSecOps/main/SecurityPolicies/quarantine.yaml
```

Delete the Rogue Application:
```
kubectl delete -f https://installer.calicocloud.io/rogue-demo.yaml 
```
