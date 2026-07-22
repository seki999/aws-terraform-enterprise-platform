.DEFAULT_GOAL := help
ENV ?= dev
TF_DIR := environments/$(ENV)

.PHONY: help fmt init validate lint security test plan apply destroy docs smoke-test

help:
	@echo "AWS Terraform Enterprise Platform"
	@echo "  make fmt                       Format Terraform"
	@echo "  make init                      Init all roots without backend"
	@echo "  make validate                  Validate all roots"
	@echo "  make lint                      Run TFLint, ShellCheck, Markdownlint"
	@echo "  make security                  Run Checkov and Trivy"
	@echo "  make test                      Run Terraform and Python tests"
	@echo "  make plan ENV=dev              Create a saved plan (AWS credentials required)"
	@echo "  make apply ENV=dev CONFIRM=apply-dev"
	@echo "  make destroy ENV=dev CONFIRM=destroy-dev"
	@echo "  make docs                      Lint Markdown"
	@echo "  make smoke-test ENV=dev        Test deployed endpoints"

fmt:
	terraform fmt -recursive

init:
	terraform -chdir=bootstrap/backend init -backend=false
	terraform -chdir=environments/dev init -backend=false
	terraform -chdir=environments/staging init -backend=false
	terraform -chdir=environments/prod init -backend=false

validate: init
	terraform -chdir=bootstrap/backend validate
	terraform -chdir=environments/dev validate
	terraform -chdir=environments/staging validate
	terraform -chdir=environments/prod validate

lint:
	tflint --recursive
	shellcheck scripts/*.sh
	markdownlint "**/*.md"

security:
	checkov -d .
	trivy fs --exit-code 1 --severity HIGH,CRITICAL .

test:
	terraform test
	python -m pytest application tests/integration

plan:
	bash scripts/plan.sh $(ENV)

apply:
	bash scripts/apply.sh $(ENV) $(CONFIRM)

destroy:
	bash scripts/destroy.sh $(ENV) $(CONFIRM)

docs:
	markdownlint "**/*.md"

smoke-test:
	bash scripts/smoke-test.sh $(ENV)

