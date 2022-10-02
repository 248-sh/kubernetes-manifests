apply crds manually, before deploying monitoring stack
```
kustomize build "https://github.com/248-sh/kubernetes-manifests//monitoring/crds/?ref=TAG" | kubectl create -f -
```