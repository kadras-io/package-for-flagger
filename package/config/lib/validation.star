load("@ytt:regexp", "regexp")

# Validation helpers used by the values schema, and by the overlays to interpret the values they validate.
# They must not depend on data values, since they run while the schema is evaluated.

_dns_label = "[a-z0-9]([-a-z0-9]*[a-z0-9])?"

def is_dns_label(value):
  return len(value) <= 63 and regexp.match("^" + _dns_label + "$", value)
end

# The traffic management providers supported by Flagger. Some accept an API version, like `gatewayapi:v1`.
# See: https://github.com/fluxcd/flagger/blob/main/pkg/apis/flagger/v1beta1/provider.go
_mesh_providers = ["apisix", "appmesh", "contour", "gatewayapi", "gloo", "istio", "knative", "kubernetes", "kuma", "linkerd", "nginx", "osm", "skipper", "smi", "traefik"]

def is_mesh_provider(value):
  return value.partition(":")[0] in _mesh_providers
end
