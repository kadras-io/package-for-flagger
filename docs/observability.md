# Observability

## Logs

```yaml
observability:
  logging:
    level: info
    format: json
```

* `level` is one of `debug`, `info`, `warn`, `error`.
* `format` is one of `text` and `json`. Flagger calls the text format `console`.

The logs describe each step of the analysis, like `Advance podinfo.apps canary weight 10` or `Promotion completed! podinfo.apps`. Flagger also records Kubernetes events on the Canaries (`kubectl describe canary`), and can send them to a webhook or to alert providers (see [alerting.md](alerting.md)).

## Metrics

Flagger exposes metrics in the Prometheus format on port 8080 (`/metrics`), on the `http` container port. Its Pods are annotated for Prometheus scraping (`prometheus.io/scrape`, `prometheus.io/port`). To remove the annotations:

```yaml
observability:
  metrics:
    enabled: false
```

If you use the Prometheus Operator, create a PodMonitor instead:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: flagger
  namespace: flagger-system
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: flagger
  podMetricsEndpoints:
    - port: http
```

The main metrics:

* `flagger_canary_status`: the status of each Canary, `0` while running, `1` when succeeded, `2` when failed;
* `flagger_canary_weight`: the traffic weight of the primary and the canary;
* `flagger_canary_duration_seconds`: the duration of the analysis;
* `flagger_canary_metric_analysis`: the last result of each metric of the analysis;
* `flagger_canary_successes_total`, `flagger_canary_failures_total`: the completed analyses, by deployment strategy;
* `flagger_info`: the version and the provider of Flagger.

See [monitoring](https://docs.flagger.app/main/usage/monitoring), and the Grafana dashboards in the [Flagger repository](https://github.com/fluxcd/flagger/tree/main/charts/grafana).
