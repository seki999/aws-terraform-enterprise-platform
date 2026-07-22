#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
backend_dir="$root_dir/bootstrap/backend"

terraform -chdir="$backend_dir" init -backend=false -input=false
terraform -chdir="$backend_dir" fmt -check
terraform -chdir="$backend_dir" validate
terraform -chdir="$backend_dir" plan -out=tfplan

echo "Bootstrap Plan 已保存到 bootstrap/backend/tfplan。请人工审查；本脚本不会 Apply。"

