#!/usr/bin/env bash

terraform_run() {

    if command -v tfenv &> /dev/null && \
        command -v terraform &> /dev/null && \
        command -v terraform-compliance &> /dev/null && \
        command -v tfsec &> /dev/null && \
        command -v checkov &> /dev/null; then
        echo "All packages are installed"
    else
        echo "Packages needed to run are not installed, exiting" && return 1
    fi


    # Environment Variables
    terraform_workspace="prd"
    checkov_skipped_tests=""
    terraform_compliance_policy_path="git:https://github.com/libre-devops/azure-naming-convention.git//?ref=main"
# These values should be inherited from the environment or override tf
#    ARM_CLIENT_ID=""
#    ARM_CLIENT_SECRET=""
#    ARM_SUBSCRIPTION_ID=""
#    ARM_TENANT_ID=""
#    ARM_USE_AZUREAD=true
#    ARM_BACKEND_STORAGE_ACCOUNT=""  # Populate this with the required secret
#    ARM_BACKEND_BLOB_CONTAINER_NAME=""  # Populate this with the required secret
#    ARM_BACKEND_STATE_KEY="vss-migration-0-pre-req.terraform.tfstate"

    # Setup Tfenv and Install terraform
    setup_tfenv() {
        if [ -z "${terraform_version}" ]; then
            echo "terraform_version is empty or not set., setting to latest" && export terraform_version="latest"

        else
            echo "terraform_version is set, installing terraform version ${terraform_version}"
        fi

        tfenv install ${terraform_version} && tfenv use ${terraform_version}
    }

    # Terraform Init, Validate & Plan
    terraform_plan() {
        terraform init && \
            terraform workspace new ${terraform_workspace} || terraform workspace select $terraform_workspace
        terraform validate && \
            terraform fmt -recursive && \
            terraform plan -out tfplan
    }

    # Terraform-Compliance Check
    terraform_compliance_check() {
        terraform-compliance -p tfplan -f ${terraform_compliance_policy_path}
    }

    # TFSec Check
    tfsec_check() {
        tfsec . --force-all-dirs
    }

    # CheckOv Check
    checkov_check() {
        terraform show -json tfplan | tee tfplan.json >/dev/null
        checkov -f tfplan.json --skip-check "${checkov_skipped_test}"
    }

    # Cleanup tfplan
    cleanup_tfplan() {
        rm -rf tfplan*
    }

    # Call the functions in sequence
    setup_tfenv && \
    terraform_plan && \
    terraform_compliance_check && \
    tfsec_check && \
    checkov_check
    cleanup_tfplan
}
