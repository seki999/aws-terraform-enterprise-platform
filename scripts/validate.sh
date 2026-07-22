#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
roots=("bootstrap/backend" "environments/dev" "environments/staging" "environments/prod")

terraform -chdir="$root_dir" fmt -check -recursive
for relative in "${roots[@]}"; do
  terraform -chdir="$root_dir/$relative" init -backend=false -input=false
  terraform -chdir="$root_dir/$relative" validate
done
terraform -chdir="$root_dir" test

