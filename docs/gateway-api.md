# Gateway API with Envoy Gateway

The default provider of the package is `gatewayapi:v1`: Flagger shifts the traffic of a Deployment between its primary and canary versions with an HTTPRoute, attached to a Gateway. With the [Envoy Gateway](https://github.com/kadras-io/package-for-envoy-gateway) package, attach it to the `external` Gateway to release applications exposed outside the cluster, or to the `internal` Gateway for traffic within the cluster. Both are in the `envoy-gateway-system` namespace and accept routes from any namespace. See [Gateway API progressive delivery](https://docs.flagger.app/main/tutorials/gatewayapi-progressive-delivery).

## Canary releases

For a Deployment named `podinfo`, whose Pods are selected by the `app: podinfo` label:

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: podinfo
  namespace: apps
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: podinfo
  # The HorizontalPodAutoscaler of the Deployment, if any. Flagger creates one for the primary.
  autoscalerRef:
    apiVersion: autoscaling/v2
    kind: HorizontalPodAutoscaler
    name: podinfo
  service:
    port: 9898
    hosts:
    - podinfo.example.com
    gatewayRefs:
    - name: external
      namespace: envoy-gateway-system
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
```

Flagger creates:

* the `podinfo-primary` Deployment, a copy of `podinfo` serving the production traffic, and scales `podinfo` to zero;
* the `podinfo`, `podinfo-primary`, and `podinfo-canary` Services;
* the `podinfo` HTTPRoute, routing the requests for the `hosts` to the primary and canary Services, with weights.

When the Pod template of `podinfo` changes, or a ConfigMap or Secret it references, Flagger scales up `podinfo` and shifts the traffic to it by `stepWeight` every `interval`, up to `maxWeight`, as long as the [analysis](analysis.md) succeeds. Then, it copies the new version to `podinfo-primary` and routes all the traffic back to it. After `threshold` failed checks, it rolls back. Follow the progress with:

```shell
kubectl get canaries -A --watch
kubectl describe canary podinfo -n apps
```

If the Envoy Gateway package serves HTTPS on the external Gateway, use a host covered by its certificates, like a subdomain of `gateways.external.domain`.

The selector of the Deployment must use the `app`, `name`, or `app.kubernetes.io/name` label. To use another label, set the `selector-labels` flag (see [configuration.md](configuration.md#container-flags)).

## A/B testing

Instead of weights, route the requests matching HTTP headers or cookies to the canary, for a number of iterations:

```yaml
  analysis:
    interval: 1m
    threshold: 5
    iterations: 10
    match:
    - headers:
        x-canary:
          exact: "insider"
    - headers:
        cookie:
          regex: "^(.*?;)?(canary=always)(;.*)?$"
```

## Blue/green with traffic mirroring

The canary receives a copy of the production requests for a number of iterations, while the responses still come from the primary. Use it for idempotent requests only.

```yaml
  analysis:
    interval: 1m
    threshold: 5
    iterations: 10
    mirror: true
```

## Session affinity

Once a user is routed to the canary, keep them there for the rest of the analysis:

```yaml
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    sessionAffinity:
      cookieName: flagger-cookie
      maxAge: 21600
```

## Zero-downtime deployments

Flagger scales the Deployments up and down during the analysis, and Envoy keeps sending requests to a Pod until it's removed from the endpoints. For no request to fail:

* give the containers a readiness probe, so they receive traffic only when ready;
* set `maxUnavailable: 0` in the rolling update strategy of the Deployment;
* delay the shutdown with a `preStop` hook, like `sleep 10`, so that Envoy stops routing requests to the Pod before it terminates;
* configure retries on the HTTPRoute via `spec.service.retries` in the Canary.

See [zero downtime deployments](https://docs.flagger.app/main/tutorials/zero-downtime-deployments).
