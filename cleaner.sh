# Patch Felix agent to the original configuration
kubectl patch felixconfiguration.p default -p '{"spec":{"flowLogsFlushInterval":"10s"}}'
kubectl patch felixconfiguration.p default -p '{"spec":{"flowLogsFileAggregationKindForAllowed":1}}'
kubectl patch felixconfiguration.p default -p '{"spec":{"flowLogsCollectTcpStats":true}}'


# Delete zone based architecture policies
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/dmz.yaml
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/trusted.yaml
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/restricted.yaml
sleep 2
kubectl delete -f https://installer.calicocloud.io/storefront-demo.yaml
sleep 2


# Delete host endpoint tier and policies
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/etcd.yaml
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/master.yaml
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/worker.yaml
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/node-tier.yaml
sleep 2


# Remove all tigera-security configurations
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/allow-kubedns.yaml
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/quarantine.yaml
sleep 2
kubectl delete -f https://installer.calicocloud.io/rogue-demo.yaml -n storefront
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/threatfeed/block-feodo.yaml
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/threatfeed/feodo-tracker.yaml
sleep 2

# Remove Boutique stuff
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/boutique-policies.yaml
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/test-app.yaml
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/default-deny.yaml
sleep 2

# Remove all alerting configurations
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/alerting/networksets.yaml
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/alerting/dns-access.yaml
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/restricted.yaml
sleep 2


# Delete the compliance reports
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/reporting/daily-cis-report.yaml
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/reporting/half-hour-inventory-report.yaml
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/alerting/lateral-access.yaml
sleep 2


# Delete the Rogue application
kubectl delete -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/policies/product.yaml
sleep 2
kubectl delete -f https://raw.githubusercontent.com/tigera-solutions/aws-howdy-parter-calico-cloud/main/workloads/test.yaml
sleep 2
kubectl delete -f https://docs.tigera.io/manifests/threatdef/honeypod/vuln-svc.yaml 
sleep 2
kubectl apply -f https://docs.tigera.io/manifests/threatdef/honeypod/common.yaml
sleep 2

# Remove the Honeypod configs
kubectl delete -f kubectl apply -f https://docs.tigera.io/manifests/threatdef/honeypod/common.yaml
sleep 2
kubectl delete -f https://docs.tigera.io/manifests/threatdef/honeypod/vuln-svc.yaml 
sleep 2


# Remove GlobalThreatFeeds for Anonymization attacks
kubectl delete -f https://docs.tigera.io/manifests/threatdef/ejr-vpn.yaml
sleep 2
kubectl delete -f https://docs.tigera.io/manifests/threatdef/tor-exit-feed.yaml
sleep 2

# Disable Host Endpoints Config
kubectl patch kubecontrollersconfiguration default --patch='{"spec": {"controllers": {"node": {"hostEndpoint": {"autoCreate": "Disabled"}}}}}'
sleep 2

# Cleanup pcap's and the kubectl-calico utility
rm *.pcap
sleep 2
ls *.pcap
sleep 2
rm kubectl-calico
sleep 2
rm ad-jobs-deployment-managed.yaml
sleep 2





# Cleanup leftover files in local directory
rm cleaner.sh
