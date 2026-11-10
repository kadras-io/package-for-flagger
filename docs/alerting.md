# Alerting

Flagger notifies the progress of the Canaries to Slack, Microsoft Teams, Discord, or Rocket.Chat. See [alerting](https://docs.flagger.app/main/usage/alerting).

## Alert providers

An AlertProvider defines where to send the alerts. Store the webhook address, and the token if any, in a Secret, rather than in the AlertProvider:

```yaml
apiVersion: flagger.app/v1beta1
kind: AlertProvider
metadata:
  name: on-call
  namespace: flagger-system
spec:
  type: slack
  channel: on-call-alerts
  username: flagger
  secretRef:
    name: on-call-url
---
apiVersion: v1
kind: Secret
metadata:
  name: on-call-url
  namespace: flagger-system
stringData:
  address: https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

Reference it from the Canaries, with a severity: `info` for all the events, `warn` when waiting for an approval or failing, `error` when failing.

```yaml
  analysis:
    alerts:
    - name: on-call
      severity: error
      providerRef:
        name: on-call
        namespace: flagger-system
```

With the `no-cross-namespace-refs` flag (see [security.md](security.md#permissions)), the AlertProviders must be in the namespace of the Canaries.

## Global notifications

To notify all the Canaries to the same Slack channel or Microsoft Teams webhook, configure Flagger via its flags. The address then ends up in the Pod specification, so prefer an AlertProvider for confidential addresses.

```yaml
args:
  slack-url: https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
  slack-channel: deployments
  cluster-name: production
```

The `cluster-name` flag adds the name of the cluster to all the alerts. To send all the events of the Canaries to a webhook, set the `event-webhook` flag. The alert providers are reached through the corporate proxy, if configured (see [corporate-proxy.md](corporate-proxy.md)).

## Prometheus alerts

To alert on failed Canaries via Alertmanager, use the metrics of Flagger (see [observability.md](observability.md#metrics)):

```yaml
- alert: canary_rollback
  expr: flagger_canary_status > 1
  for: 1m
  labels:
    severity: warning
  annotations:
    summary: "Canary failed"
    description: "Workload {{ $labels.name }} namespace {{ $labels.namespace }}"
```
