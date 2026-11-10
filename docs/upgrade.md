# Upgrading

Read the [release notes](https://github.com/fluxcd/flagger/releases) of the new Flagger version, then update the package. The CustomResourceDefinitions are updated with it.

```shell
kctrl package installed update -i flagger -v ${VERSION} -n kadras-system
```

While Flagger restarts, the Canaries pause, and resume when it's back.

## Upgrading from the Helm values

The first versions of the package accepted the values of the upstream Helm chart. The package now has its own values (see the [README](../README.md#values)), and the other settings are flags (see [configuration.md](configuration.md#container-flags)):

| Helm value | Package value |
|------------|---------------|
| `meshProvider` | `mesh_provider`. The default changed from `knative` to `gatewayapi:v1`: set `mesh_provider: knative`, or `spec.provider: knative` on the Canaries of Knative Services. |
| `metricsServer` | `metrics_server` |
| `logLevel` | `observability.logging.level` |
| `leaderElection.enabled`, `leaderElection.replicaCount`, `podDisruptionBudget` | `replicas` |
| `serviceMonitor` | A PodMonitor (see [observability.md](observability.md#metrics)) |
| `slack.*`, `msteams.*`, `clusterName`, `eventWebhook`, `selectorLabels`, `includeLabelPrefix`, `noCrossNamespaceRefs`, `configTracking.enabled` | `args`, with the flag names, like `slack-url` or `cluster-name` |
| `resources`, `nodeSelector`, `tolerations`, `affinity` | ytt overlays (see [configuration.md](configuration.md#ytt-overlays)) |

## Uninstalling

Flagger owns the workloads it creates for each Canary: the primary Deployment serving the production traffic, the Services, and the copies of the HorizontalPodAutoscaler, ConfigMaps, and Secrets. Deleting a Canary deletes them. Uninstalling the package doesn't: it keeps the CRDs and the Flagger namespace, with all the Canaries, MetricTemplates, and AlertProviders, and only deletes Flagger. The workloads keep serving the traffic, and installing the package again resumes the Canaries.

To stop using Flagger without downtime, restore each application to its original state before uninstalling the package, while Flagger still runs: set `spec.revertOnDeletion: true` on its Canary, and delete it. Flagger scales the original Deployment back up, points the Services to it, removes its routing, and then deletes the primary workloads. After uninstalling the package, delete the CRDs and the namespace:

```shell
kubectl delete crds canaries.flagger.app metrictemplates.flagger.app alertproviders.flagger.app
kubectl delete namespace flagger-system
```
