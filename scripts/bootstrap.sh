#!/bin/bash
set -x

cat <<BOOTSTRAP >> terraform.tfvars
name = "$TF_NAME"
aws_access_key = "$AWS_ACCESS_KEY_ID"
aws_secret_key = "$AWS_SECRET_ACCESS_KEY"
ami_id = "$TF_AMI_ID"
instance_type = "$TF_INSTANCE_TYPE"
database_instance_class = "$TF_DATABASE_INSTANCE_CLASS"
key_name = "$TF_KEY_NAME"
rancher_ssl_cert = "certs/crt.pem"
rancher_ssl_key = "certs/key.pem"
rancher_ssl_chain = "certs/chain.pem"
database_port = "$TF_DATABASE_PORT"
database_name = "$TF_DATABASE_NAME"
database_username = "$TF_DATABASE_USERNAME"
database_password ="$TF_DATABASE_PASSWORD"
database_storage = "$TF_DATABASE_STORAGE"
scale_min_size = "$TF_SCALE_MIN_SIZE"
scale_max_size = "$TF_SCALE_MAX_SIZE"
scale_desired_size = "$TF_SCALE_DESIRED_SIZE"
fqdn = "$TF_FQDN"
zone_id = "$TF_ZONE_ID"
region = "$AWS_DEFAULT_REGION"
vpc_id = "$TF_VPC_ID"
azs = [$(for i in `echo $TF_AZS| tr ',' ' ' ` ; do echo \"$i\" ; done | paste -sd",")]
rancher_version = "$TF_RANCHER_VERSION"
docker_version = "$TF_DOCKER_VERSION"
rhel_selinux = "$TF_RHEL_SELINUX"
rhel_docker_native = "$TF_RHEL_DOCKER_NATIVE"
BOOTSTRAP

# Creating the AWS Bucket
aws s3 mb s3://${AWS_S3_BUCKET}

# Configuring Terraform Backing Store with AWS S3
ls -la
cat terraform.tfvars
terraform get
terraform init -backend=true \
               -backend-config="bucket=${AWS_S3_BUCKET}" \
               -backend-config="key=${TF_NAME}/terraform.tfstate" \
               -backend-config="region=${AWS_DEFAULT_REGION}"

if [ "${TERRAFORM_PLAN}" == "true" ]; then
  terraform destroy -force
elif [ "${TERRAFORM_APPLY}" == "true" ]; then
  terraform apply
elif [ "${TERRAFORM_DESTROY}" == "true" ]; then
  terraform destroy -force
fi
