# Security

## Pod Security Standards

Flagger complies with the `restricted` [Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/), enforced on the package namespace. It runs as a non-root user, with a read-only root filesystem, no capabilities, no privilege escalation, and the default seccomp profile.

## Service account token

The service account token isn't auto-mounted. Flagger mounts a projected token instead, which expires after an hour and is rotated by the kubelet.

## Permissions

The `flagger` ClusterRole lets Flagger manage the workloads it releases in all namespaces: Deployments, DaemonSets, Services, HorizontalPodAutoscalers, ConfigMaps, and Secrets, plus the routing resources of all the supported providers, like HTTPRoutes and Knative Services.

On clusters shared by multiple teams, prevent the Canaries from referencing MetricTemplates and AlertProviders in other namespaces, so that a team can't read the credentials of another one:

```yaml
args:
  no-cross-namespace-refs: true
```

## Kyverno policies

The package can include a Kyverno policy verifying that the Flagger image is signed by the Flagger release workflow on GitHub Actions, with Cosign keyless signatures recorded in the Rekor transparency log. It requires Kyverno 1.19 or later, and access to the Rekor and Sigstore services.

```yaml
policies:
  enabled: true
```
