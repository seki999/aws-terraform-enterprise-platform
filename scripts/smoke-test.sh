#!/usr/bin/env bash
set -euo pipefail

environment="${1:-dev}"
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_dir="$root_dir/environments/$environment"

alb_dns="$(terraform -chdir="$env_dir" output -raw alb_dns_name 2>/dev/null || true)"
api_url="$(terraform -chdir="$env_dir" output -raw api_gateway_endpoint 2>/dev/null || true)"

if [[ -n "$alb_dns" && "$alb_dns" != "null" ]]; then
  curl --fail --silent --show-error --max-time 10 "http://$alb_dns/health"
fi
if [[ -n "$api_url" && "$api_url" != "null" ]]; then
  curl --fail --silent --show-error --max-time 10 -X POST \
    -H "content-type: application/json" \
    -d '{"object_key":"smoke/input.txt","operation":"inspect"}' \
    "$api_url/jobs"
fi

