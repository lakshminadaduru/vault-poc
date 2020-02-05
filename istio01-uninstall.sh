kubectl delete --ignore-not-found=true -f istio01-03-virtualservice.yaml
kubectl delete --ignore-not-found=true -f istio01-02-gateway.yaml
kubectl delete --ignore-not-found=true -f istio01-01-httpbin.yaml
