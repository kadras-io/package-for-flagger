# Corporate Proxy

When running Flagger behind a corporate proxy, configure it to reach external services through it: metrics providers, webhooks, and alert providers.

```yaml
proxy:
  http_proxy: http://proxy.example.com:3128
  https_proxy: http://proxy.example.com:3128
  no_proxy: .cluster.local.,.cluster.local,.svc,10.0.0.0/8
```

Flagger reaches Prometheus and the webhooks, like the load tester, within the cluster, so include the cluster domain in `no_proxy`, together with the address of the Kubernetes API server and the Pod and Service networks. The webhooks addressed by a short name, like `http://flagger-loadtester.test/`, are excluded via the `.<namespace>` suffix, or with the full name, like `flagger-loadtester.test.svc.cluster.local`.

An AlertProvider can set its own proxy via `spec.proxy`, which takes precedence.
