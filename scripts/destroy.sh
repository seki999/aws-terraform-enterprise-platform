#!/usr/bin/env bash
set -euo pipefail

environment="${1:-}"
confirmation="${2:-}"
if [[ ! "$environment" =~ ^(dev|staging)$ ]]; then
  echo "自动脚本禁止销毁 prod；只允许 dev 或 staging。" >&2
  exit 2
fi
if [[ "$confirmation" != "destroy-$environment" ]]; then
  echo "必须提供精确确认：destroy-$environment" >&2
  exit 2
fi

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_dir="$root_dir/environments/$environment"
terraform -chdir="$env_dir" plan -destroy -var-file=terraform.tfvars -out=destroy.tfplan
terraform -chdir="$env_dir" show -no-color destroy.tfplan
read -r -p "输入 DESTROY 确认执行已显示的销毁计划：" answer
[[ "$answer" == "DESTROY" ]] || { echo "已取消"; exit 2; }
terraform -chdir="$env_dir" apply destroy.tfplan

