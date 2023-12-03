ENV ?= staging
REMOTE_BUCKET_NAME ?= terraform-mackerel-sample-$(ENV)

export MACKEREL_APIKEY=$(shell aws ssm get-parameter --name /mackerel/test-$(ENV)-org/apikey --with-decryption --query Parameter.Value --output text)

init:
	terraform fmt -recursive
	terraform init -reconfigure -backend-config="bucket=$(REMOTE_BUCKET_NAME)"

plan: init
	terraform plan -lock=false -var-file=$(ENV).tfvars

apply: init
	terraform apply -var-file=$(ENV).tfvars

destroy: init
	terraform destroy -var-file=$(ENV).tfvars
