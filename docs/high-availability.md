# High Availability

Flagger runs a single active replica. Additional replicas are standby, ready to take over via leader election, using the `flagger-leader-election` Lease in the package namespace.

```yaml
replicas: 2
```

With more than 1 replica, the package:

* enables leader election;
* rolls out new versions one Pod at a time, instead of replacing the single Pod with the `Recreate` strategy;
* creates a PodDisruptionBudget keeping at least 1 replica available during node drains.

The upstream anti-affinity rule spreads the replicas across nodes, when possible.

While Flagger is unavailable, the Canaries pause: the primary workloads keep serving the traffic, and the analysis resumes when Flagger is back. So a single replica is often enough, and additional replicas mostly shorten the pause during node failures.

## Resources

Tune the resources with a ytt overlay, as described in [configuration.md](configuration.md#resources).
