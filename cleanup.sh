# Some helper functions defined first


function remove_unwanted_policies(){
   kubectl patch felixconfiguration.p default -p '{"spec":{"flowLogsFlushInterval":"10s"}}'
   kubectl patch felixconfiguration.p default -p '{"spec":{"flowLogsFileAggregationKindForAllowed":1}}'
   kubectl patch felixconfiguration.p default -p '{"spec":{"flowLogsCollectTcpStats":true}}'
}

function remove_storefront_application() {
    kubectl delete -f https://installer.calicocloud.io/storefront-demo.yaml
    sleep 2
    #echo "kubectl get pods -n storefront -o yaml"
}

# Remove zone based architecture policies
remove_unwanted_policies

kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/dmz.yaml
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/trusted.yaml
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/restricted.yaml
sleep 2


# Delete the compliance reports
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/reporting/daily-cis-report.yaml --validate=false
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/reporting/half-hour-inventory-report.yaml
 --validate=false
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/reporting/half-hour-network-access.yaml  
 --validate=false
sleep 2


# Delete the Rogue application
kubectl delete -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml
sleep 2
kubectl get pods -n default

# Remove the Honeypod configs
kubectl delete -f kubectl apply -f https://docs.tigera.io/manifests/threatdef/honeypod/common.yaml
kubectl delete -f https://docs.tigera.io/manifests/threatdef/honeypod/vuln-svc.yaml 
sleep 2
kubectl get pods -n tigera-internal -o wide

# Remove GlobalThreatFeeds for Anonymization attacks
#kubectl delete -f https://docs.tigera.io/manifests/threatdef/ejr-vpn.yaml
kubectl delete -f https://docs.tigera.io/manifests/threatdef/tor-exit-feed.yaml

# Confirm all pods have been removed
kubectl get pods -A -w
