# Metrics Analysis

Flagger can analyze Prometheus metrics to determine the success of a canary deployment. To enable this functionality, you need to configure the `metricsServer` value in your Flagger configuration to point to your Prometheus server.

```yaml
metricsServer: http://prometheus-prometheus.observability:9090
```
