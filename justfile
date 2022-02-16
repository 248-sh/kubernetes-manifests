# builds and deploys argocd
bootstrap: up-argocd

tag:
  yarn standard-version

sync: sync-argocd sync-aws-node sync-cert-manager sync-cockroach sync-external-dns sync-grafana-cloud sync-ingress-nginx sync-rabbitmq
build: build-argocd build-cert-manager build-cockroach build-external-dns build-grafana-cloud build-ingress-nginx build-rabbitmq

# argocd
sync-argocd:
  #!/usr/bin/env bash
  just clone "/manifests" v2.2.5 https://github.com/argoproj/argo-cd.git argocd/base/upstream/argoproj/argo-cd
build-argocd:
  kustomize build argocd/248-sh > .cache/248-sh/argocd.yaml
up-argocd: build-argocd
  kubectl apply -f .cache/248-sh/argocd.yaml
down-argocd:
  kubectl delete -f .cache/248-sh/argocd.yaml

#  aws-vpc-cni
sync-aws-node:
  #!/usr/bin/env bash
  just clone "/config/master" v1.10.2 https://github.com/aws/amazon-vpc-cni-k8s.git aws-node/base/upstream/aws/amazon-vpc-cni-k8s

# cert-manager
sync-cert-manager:
  #!/usr/bin/env bash
  helm repo add jetstack https://charts.jetstack.io
  helm template cert-manager jetstack/cert-manager --namespace cert-manager --include-crds --version 1.6.1 -f - <<EOF > cert-manager/base/helm-cert-manager.yaml
  nodeSelector:
    env: shared
  webhook:
    nodeSelector:
      env: shared
  cainjector:
    nodeSelector:
      env: shared
  startupapicheck:
    nodeSelector:
      env: shared
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
    nodeSelector:
      env: shared
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

# rabbitmq
sync-rabbitmq:
  #!/usr/bin/env bash
  just clone "/config" v1.11.1 https://github.com/rabbitmq/cluster-operator.git rabbitmq/base/upstream/rabbitmq/cluster-operator
build-rabbitmq:
  kustomize build rabbitmq/248-sh > .cache/248-sh/rabbitmq.yaml
up-rabbitmq: build-rabbitmq
  kubectl apply -f .cache/248-sh/rabbitmq.yaml
down-rabbitmq:
  kubectl delete -f .cache/248-sh/rabbitmq.yaml

clone FILES TAG REPOSITORY FOLDER:
  #!/usr/bin/env bash
  # set -euxo pipefail

  tput setaf 2
  echo "SYNCING {{ REPOSITORY }}@{{ TAG }}"
  tput sgr0

  rm -Rf {{ FOLDER }} 2> /dev/null

  git clone --depth 1 --filter=blob:none --no-checkout --branch {{ TAG }} {{ REPOSITORY }} {{ FOLDER }}
  pushd {{ FOLDER }} 1> /dev/null
  git sparse-checkout set {{ FILES }}
  git read-tree -mu HEAD
  rm -Rf .git
  popd 1> /dev/null
