# Configuring Flagger for Knative

Flagger can automate canary deployments for Knative services. To enable this functionality, the `meshProvider` value in your Flagger configuration should be set to `knative`, which is the default value.

```yaml
meshProvider: knative
```
