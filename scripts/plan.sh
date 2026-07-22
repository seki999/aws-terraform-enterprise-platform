#!/usr/bin/env bash
set -euo pipefail

environment="${1:-dev}"
case "$environment" in
  dev|staging|prod) ;;
  *) echo "ENV 必须是 dev、staging 或 prod" >&2; exit 2 ;;
esac

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_dir="$root_dir/environments/$environment"

if [[ ! -f "$env_dir/backend.hcl" || ! -f "$env_dir/terraform.tfvars" ]]; then
  echo "请先从 example 文件创建 backend.hcl 和 terraform.tfvars。" >&2
  exit 2
fi

terraform -chdir="$env_dir" init -backend-config=backend.hcl -input=false
terraform -chdir="$env_dir" fmt -check
terraform -chdir="$env_dir" validate
terraform -chdir="$env_dir" plan -var-file=terraform.tfvars -out=tfplan
terraform -chdir="$env_dir" show -no-color tfplan

