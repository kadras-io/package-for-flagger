# Configuring High Availability

High availability for Flagger can be configured based on a leader election strategy. This allows you to run multiple replicas of the Flagger components, ensuring that if one instance fails, another can take over without downtime.

The leader election strategy is disabled by default, but you can enable it and configure the number of replicas as follows:

```yaml
leaderElection:
  enabled: true
  replicaCount: 2
``` 

In that case, you might also want to configure a `PodDisruptionBudget` to prevent downtime during node unavailability. This can be done as follows:

```yaml
podDisruptionBudget:
  enabled: true
  minAvailable: 1
```
