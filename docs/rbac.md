# Access to the Resources

The package extends the Kubernetes [default roles](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) with the Flagger resources, via [aggregation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#aggregated-clusterroles). The users bound to `admin`, `edit`, or `view` in a namespace get the following permissions on the resources in that namespace.

| Resources | `admin`, `edit` | `view` |
|-----------|-----------------|--------|
| Canary, MetricTemplate, AlertProvider | Read and write | Read |

The progressive delivery of the applications of the namespace, with its metrics and alerts.

The permissions are granted by the `flagger-edit` and `flagger-view` ClusterRoles.
