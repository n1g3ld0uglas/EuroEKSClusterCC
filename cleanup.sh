# Some helper functions defined first


function remove_unwanted_policies(){
   kubectl patch felixconfiguration.p default -p '{"spec":{"flowLogsFlushInterval":"10s"}}'
   kubectl patch felixconfiguration.p default -p '{"spec":{"flowLogsFileAggregationKindForAllowed":1}}'
   kubectl patch felixconfiguration.p default -p '{"spec":{"flowLogsCollectTcpStats":true}}'
   kubectl patch logcollector.operator.tigera.io tigera-secure --type merge -p '{"spec":{"collectProcessPath":"Enabled"}}'
}

function remove_storefront_application() {
    kubectl delete -f https://installer.calicocloud.io/storefront-demo.yaml
    sleep 2
    #echo "kubectl get pods -n storefront -o yaml"
}

# Setup logging in elasticsearch
remove_unwanted_policies

kubectl apply -f stage0
sleep 2
kubectl apply -f stage1
sleep 2

#kubectl apply -f stage2/default-deny-egress-storefront.yaml
kubectl apply -f stage2/feodo-block-policy.yaml
kubectl apply -f stage2/FirewallZonesPolicies.yaml
kubectl apply -f stage2/restricted-resource-allow-policy.yaml

# Define the compliance reports
kubectl apply -f stage2/compliance-reports.yaml --validate=false
sleep 2

# Get the compliance reporter token and use our template to generate the reporter pod yamls
rm stage2/compliance-reporter-pods.yaml
COMPLIANCE_REPORTER_TOKEN=$(kubectl get secrets -n tigera-compliance | grep tigera-compliance-reporter-token* | awk '{print $1;}')
sed -e "s?<COMPLIANCE_REPORTER_TOKEN>?$COMPLIANCE_REPORTER_TOKEN?g" stage2/compliance-reporter-pods-template.yaml > stage2/compliance-reporter-pods.yaml
kubectl apply -f stage2/compliance-reporter-pods.yaml

# Create some "dummy" host endpoints
kubectl apply -f stage2/host-endpoints.yaml

# Create the hipstershop namespace and setup L7 logs with Envoy
kubectl apply -f hipstershop/hipstershop-ns.yaml
kubectl apply -f hipstershop/kubernetes-manifests.yaml -n hipstershop
./setup-l7-hipstershop.sh

# Remove GlobalThreatFeeds for Anonymization attacks
#kubectl delete -f https://docs.tigera.io/manifests/threatdef/ejr-vpn.yaml
kubectl delete -f https://docs.tigera.io/manifests/threatdef/tor-exit-feed.yaml

# Confirm all pods have been removed
kubectl get pods -A -w
