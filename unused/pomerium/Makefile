generate:
	helm dependency update chart
	helm template pomerium chart --namespace pomerium --include-crds > base/generated.yaml
