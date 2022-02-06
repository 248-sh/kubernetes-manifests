# builds and deploys argocd
bootstrap: up-argocd

tag:
  yarn standard-version

sync: sync-argocd sync-cert-manager sync-cockroach sync-external-dns sync-grafana-cloud sync-ingress-nginx
build: build-argocd build-cert-manager build-cockroach build-external-dns build-grafana-cloud build-ingress-nginx

# argocd
sync-argocd:
  #!/usr/bin/env bash
  just clone "/manifests" v2.2.3 https://github.com/argoproj/argo-cd.git argocd/base/upstream/argoproj/argo-cd
build-argocd:
  kustomize build argocd/248-sh > .cache/248-sh/argocd.yaml
up-argocd: build-argocd
  kubectl apply -f .cache/248-sh/argocd.yaml
down-argocd:
  kubectl delete -f .cache/248-sh/argocd.yaml

# cert-manager
sync-cert-manager:
  #!/usr/bin/env bash
  helm repo add jetstack https://charts.jetstack.io
  helm template cert-manager jetstack/cert-manager --namespace cert-manager --include-crds --version 1.6.1 -f - <<EOF > cert-manager/base/helm-cert-manager.yaml
  EOF
build-cert-manager:
  kustomize build cert-manager/248-sh > .cache/248-sh/cert-manager.yaml
up-cert-manager: build-cert-manager
  kubectl apply -f .cache/248-sh/cert-manager.yaml
down-cert-manager:
  kubectl delete -f .cache/248-sh/cert-manager.yaml

# cockroach
sync-cockroach:
  #!/usr/bin/env bash
  just clone "/config" v2.5.0 https://github.com/cockroachdb/cockroach-operator.git cockroach/base/upstream/cockroachdb/cockroach-operator
build-cockroach:
  kustomize build cockroach/248-sh > .cache/248-sh/cockroach.yaml
up-cockroach: build-cockroach
  kubectl apply -f .cache/248-sh/cockroach.yaml
down-cockroach:
  kubectl delete -f .cache/248-sh/cockroach.yaml

# external-dns
sync-external-dns:
build-external-dns:
  kustomize build external-dns/248-sh > .cache/248-sh/external-dns.yaml
up-external-dns: build-external-dns
  kubectl apply -f .cache/248-sh/external-dns.yaml
down-external-dns:
  kubectl delete -f .cache/248-sh/external-dns.yaml

# grafana-cloud
sync-grafana-cloud:
  #!/usr/bin/env bash
  just clone "/production/operator/crds" v0.22.0 https://github.com/grafana/agent.git grafana-cloud/base/upstream/grafana/agent
  helm repo add grafana https://grafana.github.io/helm-charts
  helm template grafana-agent-operator grafana/grafana-agent-operator --namespace monitoring --version 0.1.5 -f - <<EOF > grafana-cloud/base/helm-grafana-agent-operator.yaml
  EOF
build-grafana-cloud:
  kustomize build grafana-cloud/248-sh > .cache/248-sh/grafana-cloud.yaml
up-grafana-cloud: build-grafana-cloud
  kubectl apply -f .cache/248-sh/grafana-cloud.yaml
down-grafana-cloud:
  kubectl delete -f .cache/248-sh/grafana-cloud.yaml

# ingress-nginx
sync-ingress-nginx:
  #!/usr/bin/env bash
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm template ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --include-crds --version 4.0.13 -f - <<EOF > ingress-nginx/base/helm-ingress-nginx.yaml
  admissionWebhooks:
    timeoutSeconds: 29
  controller:
    # config:
    #   use-proxy-protocol: "true"
    extraArgs:
      default-ssl-certificate: "cert-manager/certificate-secret"
    ingressClassResource:
      default: true
      enabled: true
    service:
      type: LoadBalancer
      externalTrafficPolicy: Local
  EOF
build-ingress-nginx:
  kustomize build ingress-nginx/248-sh > .cache/248-sh/ingress-nginx.yaml
up-ingress-nginx: build-ingress-nginx
  kubectl apply -f .cache/248-sh/ingress-nginx.yaml
down-ingress-nginx:
  kubectl delete -f .cache/248-sh/ingress-nginx.yaml

clone FILES TAG REPOSITORY FOLDER:
  #!/usr/bin/env bash
  # set -euxo pipefail

  tput setaf 2
  echo "SYNCING {{ REPOSITORY }}@{{ TAG }}"
  tput sgr0

  git clone --depth 1 --filter=blob:none --no-checkout --sparse {{ REPOSITORY }} {{ FOLDER }} 2> /dev/null || true
  cd {{ FOLDER }}
  git sparse-checkout set {{ FILES }}
  git fetch origin tag {{ TAG }} --no-tags
  git checkout {{ TAG }}
  # git switch --force-create main {{ TAG }}
