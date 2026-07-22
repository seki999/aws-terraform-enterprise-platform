#!/usr/bin/env bash
set -euo pipefail

environment="${1:-}"
confirmation="${2:-}"
if [[ ! "$environment" =~ ^(dev|staging|prod)$ || "$confirmation" != "apply-$environment" ]]; then
  echo "用法：apply.sh <dev|staging|prod> apply-<environment>" >&2
  exit 2
fi

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plan_file="$root_dir/environments/$environment/tfplan"
if [[ ! -f "$plan_file" ]]; then
  echo "未找到已审查的 tfplan；先运行 plan.sh。" >&2
  exit 2
fi

terraform -chdir="$root_dir/environments/$environment" apply tfplan

