Steps to run:

- run `chmod +x init_env.sh` to enable execution of the init script
- run `./init_env.sh`
- run `terraform apply`
    - to check if we can access the golang webapp run `minikube tunnel` and try to access `http://127.0.0.1/` and `http://127.0.0.1/webapp/test`
    - to check the consul dashboard run `kubectl --namespace consul port-forward service/consul-consul-ui 18500:80 --address 0.0.0.0` and access `http://localhost:18500`
    - to check if the backend works run `kubectl port-forward service/backend -n tfs 8080:8080 --address 0.0.0.0` and access `http://localhost:8080` to see if it runs properly and `http://localhost:8080/friend/8081` to see if it can access backend2
    - to check if the prometheus server works run `kubectl --namespace consul port-forward service/prometheus-server 9090:80 --address 0.0.0.0` and access `http://localhost:9090`

---

Consul Getting Started Guide - https://learn.hashicorp.com/tutorials/consul/service-mesh-deploy?in=consul/gs-consul-service-mesh#overview

TODO:
- add circuit break logic using consul and envoy - https://learn.hashicorp.com/tutorials/consul/service-mesh-circuit-breaking?in=consul/service-mesh-traffic-management
- add postgres deployment and set the backend to interact withit
- read more about acl and intentions and how they work together to use them
- bring back the nginx ingress - at the moment its not working, the ingress controller cant access the gateway containers
    - when we run the command `minikube addons enable ingress` it creates a new namespace called `ingress-nginx` and the controller pods are there.
    maybe all of the actions in the articles below should be on those pods.
    - read https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/ about how ingress controllers work in general
    - read https://www.consul.io/docs/k8s/connect/ingress-controllers on how to configure ingress controllers with consul on kubernetes
    - someone has the same problem as me but he is not running in kubernetes, maybe i can use the same deployments as he did, idk - https://discuss.hashicorp.com/t/not-able-to-reach-to-a-consul-mesh-from-kubernetes-nginx-ingress/26343

postgres kube terraform module
- https://registry.terraform.io/modules/ballj/postgresql/kubernetes/latest

minikube consul ingress problems
- https://discuss.hashicorp.com/t/minikube-consul-ingress-gateway/29684



More information for later use:
- prometheus:
    - all of the pods have an additional sidecar that is responsible for generating the metrics (because of the configurations in the consul chart related to the metrics)
    - the deployment itself of prometheus is done by the consul chart ATM because it is the fastest way.
    to see how its done we can go to https://github.com/hashicorp/consul-k8s and into `charts/consul/templates/prometheus`.
    - the only problem that is left is that for some reason when prometheus tries to scrape metrics from the pods it receive `"INVALID" is not a valid start token`, ive opened an issue on stackoverflow, maybe the answer will come from there because I could not find any configuration that could fix that.
- 



