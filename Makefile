# builds the selected kustomizations (for testing purposes)
build: argocd cert-manager external-dns ingress-nginx # kube-prometheus

# builds and deploys argocd
bootstrap: argocd-up

# builds and deploys everything else (for testing purposes)
up: cert-manager-up external-dns-up ingress-nginx-up # kube-prometheus-up
down: cert-manager-down external-dns-down ingress-nginx-down # kube-prometheus-down

argocd:
	kustomize build argocd/248-sh > .cache/248-sh/argocd.yaml
argocd-up: argocd
	kubectl apply -f .cache/248-sh/argocd.yaml
argocd-down:
	kubectl delete -f .cache/248-sh/argocd.yaml

cert-manager:
	kustomize build cert-manager/248-sh > .cache/248-sh/cert-manager.yaml
cert-manager-up: cert-manager
	kubectl apply -f .cache/248-sh/cert-manager.yaml
cert-manager-down:
	kubectl delete -f .cache/248-sh/cert-manager.yaml

external-dns:
	kustomize build external-dns/248-sh > .cache/248-sh/external-dns.yaml
external-dns-up: external-dns
	kubectl apply -f .cache/248-sh/external-dns.yaml
external-dns-down:
	kubectl delete -f .cache/248-sh/external-dns.yaml

ingress-nginx:
	kustomize build ingress-nginx/248-sh > .cache/248-sh/ingress-nginx.yaml
ingress-nginx-up: ingress-nginx
	kubectl apply -f .cache/248-sh/ingress-nginx.yaml
ingress-nginx-down:
	kubectl delete -f .cache/248-sh/ingress-nginx.yaml

# kube-prometheus:
# 	kustomize build kube-prometheus/248-sh > .cache/248-sh/kube-prometheus.yaml
# kube-prometheus-up: kube-prometheus
# 	kubectl apply -f .cache/248-sh/kube-prometheus.yaml
# kube-prometheus-down:
# 	kubectl delete -f .cache/248-sh/kube-prometheus.yaml

use-do:
	kubectl config use-context do-fra1-main
tag:
	yarn standard-version
