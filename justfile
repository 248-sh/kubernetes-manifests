# argocd
sync-argocd:
  #!/usr/bin/env bash
  just clone "/manifests" v2.2.5 https://github.com/argoproj/argo-cd.git argocd/base/upstream/argoproj/argo-cd

# aws-vpc-cni
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

# cockroach
sync-cockroach:
  #!/usr/bin/env bash
  just clone "/config" v2.5.0 https://github.com/cockroachdb/cockroach-operator.git cockroach/base/upstream/cockroachdb/cockroach-operator

# ingress-nginx
sync-ingress-nginx:
  #!/usr/bin/env bash
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm repo update
  helm template ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --include-crds --version 4.0.17 -f - <<EOF > ingress-nginx/base/helm-ingress-nginx.yaml
  admissionWebhooks:
    timeoutSeconds: 29
  controller:
    admissionWebhooks:
      patch:
        nodeSelector:
          env: shared
    affinity:
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app.kubernetes.io/name: ingress-nginx
                  app.kubernetes.io/component: controller
                  app.kubernetes.io/instance: ingress-nginx
              topologyKey: kubernetes.io/hostname
    extraArgs:
      default-ssl-certificate: "cert-manager/certificate-secret"
    ingressClassResource:
      default: true
      enabled: true
    kind: DaemonSet
    metrics:
      enabled: "true"
      serviceMonitor:
        enabled: "true"
        additionalLabels:
          release: prometheus
    service:
      type: LoadBalancer
      # externalTrafficPolicy: Local
      # internalTrafficPolicy: Local
      externalTrafficPolicy: Cluster
      internalTrafficPolicy: Cluster
    updateStrategy:
      type: RollingUpdate
      rollingUpdate:
        maxSurge: 0
        maxUnavailable: 1
    watchIngressWithoutClass: true
  EOF

# monitoring
sync-monitoring:
  #!/usr/bin/env bash
  just clone "/example/prometheus-operator-crd" v0.54.0 https://github.com/prometheus-operator/prometheus-operator.git monitoring/crds/upstream/prometheus-operator/prometheus-operator
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo add grafana https://grafana.github.io/helm-charts
  helm repo update
  helm template monitoring prometheus-community/kube-prometheus-stack --namespace monitoring --version 32.2.1 --skip-crds --skip-tests -f - <<EOF > monitoring/base/helm-kube-prometheus-stack.yaml
  coreDns:
    enabled: false
  kubeControllerManager:
    enabled: false
  kubeEtcd:
    enabled: false
  kubeProxy:
    enabled: false
  kubeScheduler:
    enabled: false
  defaultRules:
    rules:
      etcd: false
      kubeProxy: false
      kubeScheduler: false
  alertmanager:
    alertmanagerSpec:
      alertmanagerConfigSelector:
        matchLabels:
          role: alertmanager-config
      nodeSelector:
        env: monitoring
  grafana:
    nodeSelector:
      env: monitoring
    persistence:
      enabled: true
      size: 1Gi
    additionalDataSources:
      - name: Loki
        type: loki
        url: http://monitoring-loki.monitoring:3100
        access: proxy
        version: 1
  prometheusOperator:
    admissionWebhooks:
      patch:
        nodeSelector:
          env: monitoring
    nodeSelector:
      env: monitoring
  prometheus:
    prometheusSpec:
      nodeSelector:
        env: monitoring
      # scrapeInterval: 15s
      # scrapeTimeout: 5s
      # evaluationInterval: 30s
      storageSpec:
        volumeClaimTemplate:
          spec:
            storageClassName: do-block-storage
            accessModes: ["ReadWriteOnce"]
            resources:
              requests:
                storage: 20Gi
      podMonitorSelectorNilUsesHelmValues: false
      serviceMonitorSelectorNilUsesHelmValues: false
  EOF
  helm template monitoring grafana/loki --namespace monitoring --version 2.9.1 --skip-crds --skip-tests -f - <<EOF > monitoring/base/helm-loki.yaml
  nodeSelector:
    env: monitoring
  persistence:
    enabled: true
    size: 10Gi
  ruler:
    storage:
      type: local
      local:
        directory: /rules
    rule_path: /tmp/scratch
    alertmanager_url: http://monitoring-kube-prometheus-alertmanager.monitoring.svc.cluster.local:9093
    ring:
      kvstore:
        store: inmemory
    enable_api: true
  EOF
  helm template monitoring grafana/promtail --namespace monitoring --version 3.11.0 --skip-crds --skip-tests -f - <<EOF > monitoring/base/helm-promtail.yaml
  config:
    lokiAddress: http://monitoring-loki.monitoring:3100/loki/api/v1/push
    # too expensive..
    # snippets:
    #   pipelineStages:
    #     - cri: {}
    #     - match:
    #         selector: '{app="eventrouter"}'
    #         stages:
    #           - json:
    #               expressions:
    #                 event_verb: verb
    #                 event_kind: event.involvedObject.kind
    #                 event_reason: event.reason
    #                 event_namespace: event.involvedObject.namespace
    #                 event_name: event.metadata.name
    #                 event_source_host: event.source.host
    #                 event_source_component: event.source.component
    #           - labels:
    #               event_verb:
    #               event_kind:
    #               event_reason:
    #               event_namespace:
    #               event_name:
    #               event_source_host:
    #               event_source_component:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 100%
  EOF

# rabbitmq-operator
sync-rabbitmq-operator:
  #!/usr/bin/env bash
  just clone "/config" v1.11.1 https://github.com/rabbitmq/cluster-operator.git rabbitmq-operator/base/upstream/rabbitmq/cluster-operator

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
