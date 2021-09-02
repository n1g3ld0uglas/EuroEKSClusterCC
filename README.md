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
