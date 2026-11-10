# Blue/Green Deployments

With the `kubernetes` provider, Flagger runs blue/green deployments with plain Kubernetes Services, without a Gateway or a service mesh. The new version is deployed next to the primary and tested for a number of iterations via its `-canary` Service, without receiving production traffic. If the analysis succeeds, it's promoted to the primary. See [Kubernetes blue/green deployments](https://docs.flagger.app/main/tutorials/kubernetes-blue-green).

Set the provider on the Canary, or make it the default via `mesh_provider: kubernetes`:

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: podinfo
  namespace: apps
spec:
  provider: kubernetes
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: podinfo
  service:
    port: 9898
    portDiscovery: true
  analysis:
    interval: 30s
    threshold: 2
    iterations: 10
    webhooks:
    - name: smoke-test
      type: pre-rollout
      url: http://flagger-loadtester.test/
      timeout: 15s
      metadata:
        type: bash
        cmd: "curl -sd 'anon' http://podinfo-canary.apps:9898/token | grep token"
    - name: load-test
      url: http://flagger-loadtester.test/
      timeout: 5s
      metadata:
        cmd: "hey -z 1m -q 10 -c 2 http://podinfo-canary.apps:9898/"
```

Flagger creates the `podinfo-primary` Deployment and the `podinfo`, `podinfo-primary`, and `podinfo-canary` Services. The `podinfo` Service always points to the primary, so expose it as usual, for example with an HTTPRoute on a Gateway of the Envoy Gateway package.

Since the new version receives no production traffic, generate it with the load tester during the analysis (see [analysis.md](analysis.md#webhooks)), and run your conformance tests against the `-canary` Service. The [zero-downtime recommendations](gateway-api.md#zero-downtime-deployments) apply to the promotion as well.
