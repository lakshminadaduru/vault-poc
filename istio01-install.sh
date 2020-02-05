#https://istio.io/docs/tasks/traffic-management/ingress/ingress-control/

echo "Default namespace will not inject automatically the istio sidecar"
kubectl get namespace -L istio-injection

echo "--- Deploying applications"
kubectl apply -f <(istioctl kube-inject -f istio01-01-httpbin.yaml)

echo "--- Creating istio gateway"
kubectl apply -f istio01-02-gateway.yaml

echo "--- Creating istio virtualservice"
kubectl apply -f istio01-03-virtualservice.yaml

export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
export INGRESS_HOST=$(minikube ip)
#export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

sleep 10 

HOSTMACHINE="httpbin.dev.pocs.myorg.com"
echo ""
echo ""
echo "------------------------------------------------------------------"
echo "--- Valid request"
echo "------------------------------------------------------------------"

#cat myorg_pocs_dev.crt root_CA_myorg.crt > intermediate.bundle.crt


echo ""
echo "Calling server providing certificates"
COMMANDCURL="curl -v -HHost:$HOSTMACHINE --resolve $HOSTMACHINE:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert ./vault/tmp/$INTERMEDIATE_CERTIFICATE_CRT_FILE_BUNDLE --key ./vault/tmp/$IDENTITY_CERTIFICATE_KEY_FILE --cert ./vault/tmp/$IDENTITY_CERTIFICATE_SSL_CERT_FILE https://$HOSTMACHINE:32386/status/418"
echo "$COMMANDCURL"
$COMMANDCURL



#following command works
#curl -v -HHost:httpbin.dev.pocs.myorg.com --resolve httpbin.dev.pocs.myorg.com:32386:192.168.99.103 --cacert ./vault/tmp/myorg_pocs_dev.crt.bundle --key ./vault/tmp/httpbin-dev-pocs-myorg-com.key --cert ./vault/tmp/httpbin-dev-pocs-myorg-com.ssl_cert  https://httpbin.dev.pocs.myorg.com:32386/status/418



#https://istio.io/docs/tasks/observability/logs/access-log/
#istioctl manifest apply --set values.global.proxy.accessLogFile="/dev/stdout"
echo "To see logs run kubectl logs -l app=httpbin -c istio-proxy -f -n pocsdev"
