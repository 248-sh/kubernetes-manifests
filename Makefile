apply-all: argocd cert-manager external-dns ingress-nginx kube-prometheus

argocd:
	kustomize build argocd/248-sh | kubectl apply -f -

cert-manager:
	kustomize build cert-manager/248-sh | kubectl apply -f -

external-dns:
	kustomize build external-dns/248-sh | kubectl apply -f -

ingress-nginx:
	kustomize build ingress-nginx/248-sh | kubectl apply -f -

kube-prometheus:
	kustomize build kube-prometheus/248-sh | kubectl apply -f -

tag:
	yarn standard-version
