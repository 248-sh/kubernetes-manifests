generate:
	helm dependency update chart
	helm template cert-manager chart --namespace cert-manager --include-crds > base/generated.yaml
