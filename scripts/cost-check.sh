#!/usr/bin/env bash
set -euo pipefail

environment="${1:-dev}"
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plan_json="$root_dir/environments/$environment/tfplan.json"

if ! command -v infracost >/dev/null 2>&1; then
  echo "Infracost 未安装。安装说明：https://www.infracost.io/docs/" >&2
  exit 127
fi
if [[ ! -f "$plan_json" ]]; then
  echo "缺少 tfplan.json。该文件可能含敏感元数据，不得提交 Git。" >&2
  exit 2
fi

infracost breakdown --path "$plan_json"

