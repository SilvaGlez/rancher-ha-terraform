# Rancher HA - Terraform

This Terraform script will setup HA on AWS with SSL terminating on an ALB with an appropriately configured variable file.

## Overview

The script creates the following components:

- ELB

To distribute the load over the HA servers, its recommended to use ELB over ALB, however ELB needs more configuration in order to work with Websockets, which the script already do, the script also set up a Route53 subdomain that points to this ELB.

- HA Autoscaling Group

The autoscaling group will create the Rancher servers, you can configure the script to create certain numbers of Rancher servers. The Rancher servers are using user-data template to set up several dependencies and configure the OS before running the Docker container of rancher server in HA mode.

- RDS

The script will create RDS with configurable variables including: database storage size, database name, database port, database username/password, and instance type.

### OS support

The script supports and tested on:

| Operating System |
|------------------|
|  RancherOS 1.0.3 |
|   Ubuntu 14.04   |
|   Ubuntu 16.04   |
|     RHEL 7.3     |
|     RHEL 7.4     |

## Variables

The Terraform script uses the following variables:

|      Variable Name      |                               Description                               |             Type            |
|:-----------------------:|:-----------------------------------------------------------------------:|:---------------------------:|
|           name          |                                Stack name                               |            string           |
|      aws_access_key     |                              AWS access key                             |            string           |
|      aws_secret_key     |                              AWS Secret Key                             |            string           |
|          ami_id         |                                  OS AMI                                 |            string           |
|      instance_type      |                    the Rancher servers instance type                    |            string           |
| database_instance_class |                          the RDS instance types                         |            string           |
|     rancher_ssl_cert    |    ssl certificate that will be used for SSL termination for the ELB    |            string           |
|     rancher_ssl_key     |        ssl key that will be used for SSL termination for the ELB        |            string           |
|    rancher_ssl_chain    | ssl chain certificate that will be used for SSL termination for the ELB |            string           |
|      database_port      |                               the RDS port                              |            string           |
|      database_name      |             the database name that will be used for Rancher             |            string           |
|    database_username    |           the database username that will be used for Rancher           |            string           |
|    database_password    |           the database password that will be used for Rancher           |            string           |
|     database_storage    |                           the RDS storage size                          |            string           |
|      scale_min_size     | minimum number of instances that will be used for the autoscaling group |             int             |
|      scale_max_size     | maximum number of instances that will be used for the autoscaling group |             int             |
|    scale_desired_size   | desired number of instances that will be used for the autoscaling group |             int             |
|           fqdn          |                 the FQDN that will be create in Route53                 |            string           |
|         zone_id         |                             Route53 zone id                             |            string           |
|          region         |                                AWS region                               |            string           |
|         vpc_id          |                                AWS vpc id                               |            string           |
|           azs           |          a list of all the availability zones that will be used         |             list            |
|     rancher_version     |                 the Rancher version for Rancher servers                 |            string           |
|      docker_version     |        the Docker version that will be installed on the machines        |            string           |
|       rhel_selinux      |                   whether or not to selinux with RHEL                   | string (must be true/false) |
|    rhel_docker_native   |             whether or not to use RHEL's own docker package             | string (must be true/false) |

## Usage

You can use the script in two ways:

### Directly with Terraform

To use the script directly with terraform, create the `terraform.tfvars` file and just run `terraform apply`.

### Using Jenkins

The repository allows the user to use the script with jenkins using a Docker container, it can be an easy method to have an automatic job that creates rancher HA setup, to use it with jenkins Docker should be pre-installed on the jenkins box, then set up a pipeline job with these specific parameters:


|        Variable Name       |    Parameter Type   |
|:--------------------------:|:-------------------:|
|           TF_NAME          |   String Parameter  |
|      AWS_ACCESS_KEY_ID     |   String Parameter  |
|    AWS_SECRET_ACCESS_KEY   |   String Parameter  |
|          TF_AMI_ID         |   String Parameter  |
|      TF_INSTANCE_TYPE      |   String Parameter  |
| TF_DATABASE_INSTANCE_CLASS |   String Parameter  |
|      TF_DATABASE_PORT      |   String Parameter  |
|      TF_DATABASE_NAME      |   String Parameter  |
|    TF_DATABASE_USERNAME    |   String Parameter  |
|    TF_DATABASE_PASSWORD    |   String Parameter  |
|     TF_DATABASE_STORAGE    |   String Parameter  |
|      TF_SCALE_MIN_SIZE     |   String Parameter  |
|      TF_SCALE_MAX_SIZE     |   String Parameter  |
|    TF_SCALE_DESIRED_SIZE   |   String Parameter  |
|           TF_FQDN          |   String Parameter  |
|         TF_ZONE_ID         |   String Parameter  |
|     AWS_DEFAULT_REGION     |   String Parameter  |
|          TF_VPC_ID         |   String Parameter  |
|     TF_RANCHER_VERSION     |   String Parameter  |
|      TF_DOCKER_VERSION     |   String Parameter  |
|       TF_RHEL_SELINUX      |  Boolean Parameter  |
|    TF_RHEL_DOCKER_NATIVE   |  Boolean Parameter  |
|        AWS_S3_BUCKET       |   String Parameter  |
|       TERRAFORM_PLAN       |  Boolean Parameter  |
|       TERRAFORM_APPLY      |  Boolean Parameter  |
|      TERRAFORM_DESTROY     |  Boolean Parameter  |
|      RANCHER_SSL_CERT      | Multiline Parameter |
|       RANCHER_SSL_KEY      | Multiline Parameter |
|      RANCHER_SSL_CHAIN     | Multiline Parameter |

The job works by building a docker image with the terraform scripts in it and terraform installed, the terraform will then be configured with S3 Backend to store the state files, if the S3 bucket doesn't exist the script will create it.

The script will generate the `terraform.tfvars` and will attempt either terraform apply or destroy based on the user choice.
