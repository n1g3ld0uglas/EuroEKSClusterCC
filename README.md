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

<img width="1403" alt="Screenshot 2021-07-06 at 10 18 44" src="https://user-images.githubusercontent.com/82048393/124575911-b83b4800-de43-11eb-8a4c-286bba2dda9e.png">


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
  
