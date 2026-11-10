#!/usr/bin/env bash
#
# Removes what uninstalling the package leaves behind on purpose: the Flagger resources, their CustomResourceDefinitions,
# and the namespace. The finalizers are removed first, since Flagger isn't running anymore to handle them.
# Deleting the Canaries garbage-collects the primary workloads they own.
#
#   ../cleanup.sh <flagger-namespace>

set -eo pipefail

for crd in canaries.flagger.app metrictemplates.flagger.app alertproviders.flagger.app; do
  kubectl get "$crd" -A -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' |
    while read -r namespace name; do
      kubectl patch "$crd" "$name" -n "$namespace" --type=merge -p '{"metadata":{"finalizers":null}}'
    done
done
kubectl delete crds canaries.flagger.app metrictemplates.flagger.app alertproviders.flagger.app --wait
kubectl delete namespace "$1" --wait
