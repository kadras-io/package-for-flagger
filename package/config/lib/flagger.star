load("@ytt:data", "data")
load("@ytt:struct", "struct")

# The namespace the upstream Helm chart is rendered into (see `task vendor`), replaced by the package namespace.
upstream_namespace = "flagger-system"

# The Deployment and ServiceAccount of Flagger, as rendered from the upstream Helm chart.
# Flagger runs in a `flagger` container.
deployment = "flagger"
service_account = "flagger"
container = "flagger"

# The port where Flagger exposes its metrics and health endpoints, as rendered from the upstream Helm chart.
metrics_port = 8080

# The labels selecting the Flagger Pods, as defined in the upstream Helm chart.
selector = {"app.kubernetes.io/name": "flagger", "app.kubernetes.io/instance": "flagger"}

# Additional replicas are standby via leader election.
def is_highly_available():
  return data.values.replicas > 1
end

# ###########
# FLAGS
# ###########

# The values of the logging flags, which Flagger calls `console` and `json`.
_log_encodings = {"text": "console", "json": "json"}

# The flags computed from the package values. `args` is merged on top of them.
def flagger_args():
  logging = data.values.observability.logging
  args = {
    "log-level": logging.level,
    "zap-encoding": _log_encodings[logging.format],
    "mesh-provider": data.values.mesh_provider,
    "metrics-server": data.values.metrics_server,
  }

  if is_highly_available():
    args["enable-leader-election"] = True
    args["leader-election-namespace"] = data.values.namespace
  end

  for name, value in struct.decode(data.values.args).items():
    args[name.lstrip("-")] = value
  end
  return args
end

def _format(value):
  if type(value) == "bool":
    return "true" if value else "false"
  end
  return str(value)
end

# Merges the given flags into the upstream command, keeping their order. The executable (`./flagger`) stays first.
# New flags are appended, and flags set to null are removed. Flagger flags start with a single dash.
def _merge_command(upstream, overrides):
  executable = [arg for arg in upstream if not arg.startswith("-")]
  flags = {}
  for arg in upstream:
    if arg.startswith("-"):
      name, separator, value = arg.lstrip("-").partition("=")
      flags[name] = value if separator else None
    end
  end
  for name, value in overrides.items():
    if value == None:
      flags.pop(name, None)
    else:
      flags[name] = _format(value)
    end
  end
  return executable + ["-" + name if value == None else "-" + name + "=" + value for name, value in flags.items()]
end

# The `via` function of the overlay replacing the upstream container command.
def command_merger(overrides):
  return lambda left, _: _merge_command(left, overrides)
end
