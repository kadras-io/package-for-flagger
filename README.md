# Flagger

![Test Workflow](https://github.com/kadras-io/package-for-flagger/actions/workflows/test.yml/badge.svg)
![Release Workflow](https://github.com/kadras-io/package-for-flagger/actions/workflows/release.yml/badge.svg)
[![The SLSA Level 3 badge](https://slsa.dev/images/gh-badge-level3.svg)](https://slsa.dev/spec/v1.0/levels)
[![The Apache 2.0 license badge](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Follow us on Bluesky](https://img.shields.io/static/v1?label=Bluesky&message=Follow&color=1DA1F2)](https://bsky.app/profile/kadras.bsky.social)

A Carvel package for [Flagger](https://docs.flagger.app), a progressive delivery tool that automates the release process for applications running on Kubernetes. It reduces the risk of introducing a new software version in production by gradually shifting traffic to the new version while measuring metrics and running conformance tests.

## ✨&nbsp; What's Included

* **Progressive delivery**. Canary releases, A/B testing, and blue/green deployments, with the traffic shifted via the Gateway API (like the Gateways of the Kadras Envoy Gateway package) or between the revisions of Knative Services. The Canary, MetricTemplate, and AlertProvider CRDs are part of the package.
* **High availability**. Standby replicas via leader election, protected by a PodDisruptionBudget.
* **Observability**. Structured logs, and metrics annotated for Prometheus scraping.
* **Security**. Flagger complies with the `restricted` [Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/), enforced on its namespace, and mounts the service account token explicitly. Optionally, Kyverno verifies the signature of the Flagger image.

## 🚀&nbsp; Getting Started

### Prerequisites

* Kubernetes 1.35+
* Carvel [`kctrl`](https://carvel.dev/kapp-controller/docs/latest/install/#installing-kapp-controller-cli-kctrl) CLI.
* Carvel [kapp-controller](https://carvel.dev/kapp-controller) deployed in your Kubernetes cluster. You can install it with Carvel [`kapp`](https://carvel.dev/kapp/docs/latest/install) (recommended choice) or `kubectl`.

```shell
kapp deploy -a kapp-controller -y \
  -f https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yml
```

### Dependencies

Flagger has no required dependencies, but it needs a way to route the traffic of the applications it releases:

* [Envoy Gateway](https://github.com/kadras-io/package-for-envoy-gateway), to shift the traffic of Deployments via HTTPRoutes. It's the default provider (`gatewayapi:v1`).
* [Knative Serving](https://github.com/kadras-io/package-for-knative-serving), to shift the traffic between the revisions of Knative Services.

Blue/green deployments without traffic shifting only need Kubernetes. The canary analysis measures metrics from a Prometheus server, which you can configure via `metrics_server`. To authenticate with private registries, install [secretgen-controller](https://github.com/kadras-io/package-for-secretgen-controller). To verify the Flagger image, install [Kyverno](https://github.com/kadras-io/package-for-kyverno) 1.19 or later. You can install them from the [Kadras package repository](https://github.com/kadras-io/kadras-packages).

### Installation

Add the Kadras [package repository](https://github.com/kadras-io/kadras-packages) to your Kubernetes cluster:

```shell
kctrl package repository add -r kadras-packages \
  --url ghcr.io/kadras-io/kadras-packages \
  -n kadras-system --create-namespace
```

<details><summary>Installation without package repository</summary>
The recommended way of installing the Flagger package is via the Kadras <a href="https://github.com/kadras-io/kadras-packages">package repository</a>. If you prefer not using the repository, you can add the package definition directly using <a href="https://carvel.dev/kapp/docs/latest/install"><code>kapp</code></a> or <code>kubectl</code>.

```shell
kubectl create namespace kadras-system
kapp deploy -a flagger-package -n kadras-system -y \
  -f https://github.com/kadras-io/package-for-flagger/releases/latest/download/metadata.yml \
  -f https://github.com/kadras-io/package-for-flagger/releases/latest/download/package.yml
```
</details>

Install the Flagger package:

```shell
kctrl package install -i flagger \
  -p flagger.packages.kadras.io \
  -v ${VERSION} \
  -n kadras-system
```

> **Note**
> You can find the `${VERSION}` value by retrieving the list of package versions available in the Kadras package repository installed on your cluster.
> 
> ```shell
> kctrl package available list -p flagger.packages.kadras.io -n kadras-system
> ```

Verify the installed packages and their status:

```shell
kctrl package installed list -n kadras-system
```

### Try It Out

With the Envoy Gateway package installed, deploy the [podinfo](https://github.com/stefanprodan/podinfo) application and a Canary that releases its new versions through the `external` Gateway:

```shell
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo
  namespace: default
spec:
  selector:
    matchLabels:
      app: podinfo
  template:
    metadata:
      labels:
        app: podinfo
    spec:
      containers:
      - name: podinfod
        image: ghcr.io/stefanprodan/podinfo:6.16.0
        ports:
        - containerPort: 9898
---
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: podinfo
  namespace: default
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: podinfo
  service:
    port: 9898
    hosts:
    - podinfo.example.com
    gatewayRefs:
    - name: external
      namespace: envoy-gateway-system
  analysis:
    interval: 30s
    threshold: 5
    maxWeight: 50
    stepWeight: 10
EOF
```

Flagger creates the `podinfo-primary` Deployment serving the traffic, and the HTTPRoute splitting it between the primary and the canary. Wait for the Canary to be initialized:

```shell
kubectl wait canary/podinfo -n default --for=jsonpath='{.status.phase}'=Initialized --timeout=5m
```

Release a new version, and watch Flagger shift the traffic to it step by step, then promote it:

```shell
kubectl set image deployment/podinfo -n default podinfod=ghcr.io/stefanprodan/podinfo:6.17.0
kubectl get canary podinfo -n default --watch
```

This Canary has no metrics, so each step succeeds. See [canary analysis](docs/analysis.md) to measure metrics and run tests before shifting more traffic.

## 📙&nbsp; Documentation

Documentation, tutorials and examples for this package are available in the [docs](docs) folder.
For documentation specific to Flagger, check out [docs.flagger.app](https://docs.flagger.app).

Progressive delivery:

* [Gateway API with Envoy Gateway](docs/gateway-api.md)
* [Knative Serving](docs/knative.md)
* [Blue/green deployments](docs/blue-green.md)
* [Canary analysis: metrics and webhooks](docs/analysis.md)
* [Alerting](docs/alerting.md)

Features:

* [High availability](docs/high-availability.md)
* [Observability](docs/observability.md)
* [Security](docs/security.md)

Operations:

* [Configuration and ytt overlays](docs/configuration.md)
* [Custom certificate authorities](docs/custom-ca.md)
* [Corporate proxy](docs/corporate-proxy.md)
* [Upgrading and uninstalling](docs/upgrade.md)
* [Verifying the release](docs/verify-release.md)

## 🎯&nbsp; Configuration

The Flagger package can be customized via a `values.yml` file.

```yaml
mesh_provider: gatewayapi:v1
metrics_server: http://prometheus.monitoring.svc.cluster.local:9090
replicas: 2
args:
  cluster-name: production
```

Reference the `values.yml` file from the `kctrl` command when installing or upgrading the package.

```shell
kctrl package install -i flagger \
  -p flagger.packages.kadras.io \
  -v ${VERSION} \
  -n kadras-system \
  --values-file values.yml
```

The flags of Flagger can be customized beyond the values, as well as any resource via ytt overlays. See [configuration.md](docs/configuration.md).

### Values

The Flagger package has the following configurable properties.

<details><summary>Configurable properties</summary>

<!-- values-table:start -->

| Config | Default | Description |
|--------|---------|-------------|
| `namespace` | `"flagger-system"` | The namespace in which to deploy Flagger. |
| `mesh_provider` | `"gatewayapi:v1"` | The default provider managing the traffic of the Canaries, used when a Canary doesn't set `spec.provider`. With `gatewayapi:v1`, Flagger shifts the traffic via HTTPRoutes, like the ones attached to the Gateways of the Kadras Envoy Gateway package. With `knative`, it shifts the traffic between the revisions of Knative Services. With `kubernetes`, it runs blue/green deployments without shifting traffic. See https://docs.flagger.app/main/usage/deployment-strategies. |
| `metrics_server` | `"http://prometheus-prometheus.observability:9090"` | The URL of the Prometheus server queried by the built-in metrics of the canary analysis (`request-success-rate` and `request-duration`). MetricTemplates set their own address. |
| `replicas` | `1` | The number of replicas. Additional replicas are standby via leader election. With more than 1 replica, a PodDisruptionBudget is created. |
| `args` | `{}` | Container flags, merged on top of the ones computed by the package. Set a flag to null to remove it. See https://github.com/fluxcd/flagger/blob/main/cmd/flagger/main.go. |
| `ca_cert_data` | `""` | PEM-encoded certificates of additional certificate authorities to trust, for example to reach a metrics provider, a webhook, or an alert provider. The system ones are still trusted. |
| `observability.logging.level` | `"info"` | The log level of Flagger. |
| `observability.logging.format` | `"json"` | The format of the logs. |
| `observability.metrics.enabled` | `true` | Whether to annotate the Pods for Prometheus scraping. Flagger always exposes metrics on port 8080 (`/metrics`). |
| `policies.enabled` | `false` | Whether to include the Kyverno policies that validate and secure the package installation. They require Kyverno 1.19 or later. |
| `proxy.http_proxy` | `""` | The HTTP proxy to use for network traffic. |
| `proxy.https_proxy` | `""` | The HTTPS proxy to use for network traffic. |
| `proxy.no_proxy` | `""` | A comma-separated list of hostnames, IP addresses, or IP ranges in CIDR format that should not use the proxy. Include the in-cluster domains, since Flagger reaches Prometheus and the webhooks, like the load tester, within the cluster. |

<!-- values-table:end -->

</details>

## 🛠️&nbsp; Development

The development environment is defined with [devenv](https://devenv.sh). Enter it with `devenv shell`, or automatically with [direnv](https://direnv.net) after running `direnv allow`. Run `task --list` to see all the available tasks.

```shell
# Run the unit tests, which render the package and check the result without a cluster.
task test:config

# Create a local kind cluster and run the integration tests on it.
task cluster:setup
task test:integration

# Deploy the package from the local sources to the current cluster.
task dev

# Vendor a new version of the upstream Helm chart (see package/vendir.yml) and render it.
task vendor

# Update the table of configurable values in this README after changing the values schema.
task docs:values
```

The unit tests are described in [test/unit/README.md](test/unit/README.md).

## 🛡️&nbsp; Security

The security process for reporting vulnerabilities is described in [SECURITY.md](SECURITY.md).

## 🖊️&nbsp; License

This project is licensed under the **Apache License 2.0**. See [LICENSE](LICENSE) for more information.
