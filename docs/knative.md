# Knative Serving

With the `knative` provider, Flagger releases the new revisions of a Knative Service progressively, by shifting the traffic between the primary revision and the latest one via the `traffic` field of the Service. It works with the [Knative Serving](https://github.com/kadras-io/package-for-knative-serving) package, which routes the traffic through the Gateways of the Envoy Gateway package. See [Knative progressive delivery](https://docs.flagger.app/main/tutorials/knative-progressive-delivery).

Set the provider on each Canary targeting a Knative Service:

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: podinfo
  namespace: apps
spec:
  provider: knative
  targetRef:
    apiVersion: serving.knative.dev/v1
    kind: Service
    name: podinfo
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
```

If you only release Knative Services, make `knative` the default provider instead, so that Canaries don't need to set it:

```yaml
mesh_provider: knative
```

Flagger records the revision serving the production traffic in the `flagger.app/primary-revision` annotation of the Knative Service. Each new revision, created when the template of the Service changes, triggers the analysis: Flagger shifts the traffic to it by `stepWeight` every `interval`, up to `maxWeight`, then promotes it. After `threshold` failed checks, it routes all the traffic back to the primary revision.

```shell
kubectl get canaries -A --watch
kubectl get ksvc podinfo -n apps -o jsonpath='{.spec.traffic}'
```

Don't change the `traffic` field of a Knative Service managed by Flagger, since Flagger overwrites it.

## Metrics

The built-in metrics of the `knative` provider query the Envoy metrics of the Kourier networking layer, which the Knative Serving package doesn't use. Measure the canary revision with a MetricTemplate instead, for example on the request metrics of the queue-proxy, which the Knative Serving package exposes on port 9091 when enabled:

```yaml
observability:
  request_metrics:
    enabled: true
```

See [analysis.md](analysis.md#metric-templates).
