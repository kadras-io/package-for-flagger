# Canary Analysis

At each `interval` of the analysis, Flagger checks the metrics of the canary and calls the webhooks. Each failed check counts towards the `threshold` of the Canary, after which Flagger rolls back. A Canary without metrics and webhooks always succeeds, so it only provides a gradual rollout. See [how it works](https://docs.flagger.app/main/usage/how-it-works).

## Metrics

### Built-in metrics

Flagger provides two built-in metrics, measured over the `interval` of the metric:

* `request-success-rate`: the percentage of requests not failing with a 5xx response, checked against `thresholdRange.min`;
* `request-duration`: the 99th percentile of the request duration in milliseconds, checked against `thresholdRange.max`.

```yaml
  analysis:
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
    - name: request-duration
      thresholdRange:
        max: 500
      interval: 1m
```

They're Prometheus queries, sent to the server configured in the package values:

```yaml
metrics_server: http://prometheus.monitoring.svc.cluster.local:9090
```

The queries depend on the provider. For `gatewayapi` and `kubernetes`, they read the `http_request_duration_seconds` histogram exposed by the application itself, with the `kubernetes_namespace` and `kubernetes_pod_name` labels, which Prometheus must add when scraping the Pods. For `knative`, they read the Envoy metrics of the Kourier networking layer, which the Kadras packages don't use. When your metrics don't match, use a MetricTemplate. See [metrics analysis](https://docs.flagger.app/main/usage/metrics).

### Metric templates

A MetricTemplate defines a custom query, for Prometheus or other providers like Datadog, New Relic, CloudWatch, or Dynatrace. The query can use the `namespace`, `target` (the name of the Deployment or Knative Service), `service`, `interval`, and `variables` placeholders. For example, the error rate of an application exposing the `http_request_duration_seconds` histogram, scraped by a Prometheus server adding the `namespace` and `pod` labels:

```yaml
apiVersion: flagger.app/v1beta1
kind: MetricTemplate
metadata:
  name: error-rate
  namespace: flagger-system
spec:
  provider:
    type: prometheus
    address: http://prometheus.monitoring.svc.cluster.local:9090
  query: |
    100 - sum(
      rate(http_request_duration_seconds_count{
        namespace="{{ namespace }}",
        pod=~"{{ target }}-[0-9a-zA-Z]+(-[0-9a-zA-Z]+)",
        status!~"5.*"
      }[{{ interval }}])
    )
    /
    sum(
      rate(http_request_duration_seconds_count{
        namespace="{{ namespace }}",
        pod=~"{{ target }}-[0-9a-zA-Z]+(-[0-9a-zA-Z]+)"
      }[{{ interval }}])
    )
    * 100
```

The `pod` regular expression matches the Pods of the canary Deployment, and not the ones of the primary. Reference the template from the Canary:

```yaml
  analysis:
    metrics:
    - name: error-rate
      templateRef:
        name: error-rate
        namespace: flagger-system
      thresholdRange:
        max: 1
      interval: 1m
```

When the metrics provider requires credentials, store them in a Secret in the namespace of the MetricTemplate and reference it via `spec.provider.secretRef`. The keys depend on the provider: `username` and `password`, or `token`, for Prometheus.

## Webhooks

Webhooks extend the analysis with tests and manual gates. Flagger sends a POST request with the name, namespace, and phase of the Canary, and the `metadata` of the webhook. A response other than 2xx counts as a failed check. The type of the webhook determines when it's called:

* `confirm-rollout`: before the canary is scaled up, to approve the start of the analysis;
* `pre-rollout`: before routing traffic to the canary, like smoke tests;
* `rollout`: at each interval of the analysis, before the metric checks, like load tests;
* `confirm-traffic-increase`: before each traffic increase;
* `confirm-promotion`: before the promotion;
* `post-rollout`: after the promotion or the rollback, without affecting it;
* `rollback`: during the analysis, to roll back on demand;
* `event`: on every event of the Canary, for notifications.

See [webhooks](https://docs.flagger.app/main/usage/webhooks).

### Load tester

The Flagger load tester is a webhook receiver running load tests with `hey`, gRPC tests with `ghz`, and shell commands, and providing manual gates. Install it in a namespace of your choice, like `test`:

```shell
kubectl create namespace test
kubectl apply -n test -k "https://github.com/fluxcd/flagger//kustomize/tester?ref=v1.45.0"
```

Then generate traffic for the canary during the analysis, and gate the promotion:

```yaml
  analysis:
    webhooks:
    - name: load-test
      type: rollout
      url: http://flagger-loadtester.test/
      timeout: 5s
      metadata:
        cmd: "hey -z 1m -q 10 -c 2 http://podinfo-canary.apps:9898/"
    - name: promotion-gate
      type: confirm-promotion
      url: http://flagger-loadtester.test/gate/check
```

The `/gate/check` endpoint waits until the gate is opened by a POST request to `/gate/open` on the load tester, with the name and namespace of the Canary. The sum of the timeouts of the `rollout` webhooks must be lower than the `interval` of the analysis.

The webhooks are called from the Flagger Pod. Through a corporate proxy, exclude their hosts via `proxy.no_proxy` (see [corporate-proxy.md](corporate-proxy.md)).
