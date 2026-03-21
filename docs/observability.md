# Configuring Observability

Monitor and observe the operation of Flagger using metrics.

## Logging

Log configuration for the Flagger deployment can be customized as follows:

```yaml
logLevel: info
```

## Metrics

Flagger produces Prometheus metrics by default. This package comes pre-configured with the necessary annotations to let Prometheus scrape metrics automatically from Flagger.

If you'd rather use a ServiceMonitor (Prometheus Operator) to scrape Flagger metrics, you can enable it as follows:

```yaml
serviceMonitor:
  enabled: true
  honorLabels: true
```
