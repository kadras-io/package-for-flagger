# Configuration

The package values cover the decisions most installations need to make: the default provider, the metrics server, high availability, observability, trust, and the corporate proxy. Everything else can still be customized in two ways.

## Container flags

Flagger is configured via flags. The package computes some of them from the values (log level and format, provider, metrics server, leader election) and merges them into the upstream ones, then merges `args` on top, so its flags take precedence. The flags are written without the leading dash, and a flag set to `null` is removed.

```yaml
args:
  cluster-name: production
  include-label-prefix: app.kubernetes.io
```

An unknown flag prevents Flagger from starting. Check the flags of the Flagger version you install before adding one: they're defined in [main.go](https://github.com/fluxcd/flagger/blob/main/cmd/flagger/main.go). A change rolls out Flagger.

Some useful flags:

* `selector-labels`: the labels selecting the Pods of the target Deployments, `app,name,app.kubernetes.io/name` by default;
* `include-label-prefix`: the prefixes of the labels copied from the target Deployment to the primary one, `*` for all;
* `enable-config-tracking`: whether to copy the ConfigMaps and Secrets referenced by the target to the primary, `true` by default. A single ConfigMap or Secret can opt out with the `flagger.app/config-tracking: disabled` annotation;
* `no-cross-namespace-refs`: whether to forbid the Canaries from referencing MetricTemplates and AlertProviders in other namespaces;
* `cluster-name`, `slack-url`, `msteams-url`, `event-webhook`: see [alerting.md](alerting.md);
* `threadiness`: the number of Canaries reconciled in parallel, `2` by default.

## ytt overlays

Any Kubernetes resource of the package can be customized with a [ytt overlay](https://carvel.dev/ytt/docs/latest/ytt-overlays/). Store it in a Secret and reference it from the PackageInstall via the `ext.packaging.carvel.dev/ytt-paths-from-secret-name.0` annotation.

```shell
kubectl create secret generic flagger-overlays -n kadras-system --from-file=overlays.yml
kubectl annotate packageinstall flagger -n kadras-system \
  ext.packaging.carvel.dev/ytt-paths-from-secret-name.0=flagger-overlays
```

Flagger runs in a container named `flagger`.

### Resources

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata": {"name": "flagger"}})
---
spec:
  template:
    spec:
      containers:
        #@overlay/match by="name"
        - name: flagger
          resources:
            limits:
              memory: 1Gi
```

### Node placement

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata": {"name": "flagger"}})
---
spec:
  template:
    spec:
      #@overlay/match missing_ok=True
      nodeSelector:
        node-restriction.kubernetes.io/reserved-for: platform
      #@overlay/match missing_ok=True
      tolerations:
        - key: node-restriction.kubernetes.io/reserved-for
          operator: Equal
          value: platform
          effect: NoExecute
```

### Workload identity

To authenticate with a cloud metrics provider via workload identity, annotate the `flagger` ServiceAccount. For example, on GKE:

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "ServiceAccount", "metadata": {"name": "flagger"}})
---
metadata:
  #@overlay/match missing_ok=True
  annotations:
    iam.gke.io/gcp-service-account: flagger@my-project.iam.gserviceaccount.com
```
