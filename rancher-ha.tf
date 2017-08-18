provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.region}"
}

module "rds" {
  source = "./modules/rds"

  name                    = "${var.name}"
  vpc_id                  = "${var.vpc_id}"
  database_port           = "${var.database_port}"
  database_storage        = "${var.database_storage}"
  database_instance_class = "${var.database_instance_class}"
  database_name           = "${var.database_name}"
  database_username       = "${var.database_username}"
  database_password       = "${var.database_password}"
  # database_security_groups = "${list("${aws_security_group.rancher_ha_allow_elb.id}","${module.elb.elb_sec_grp_id}","${aws_security_group.rancher_ha_allow_internal.id}")}"
}

module "elb" {
  source = "./modules/elb"

  name              = "${var.name}"
  rancher_ssl_cert  = "${var.rancher_ssl_cert}"
  rancher_ssl_key   = "${var.rancher_ssl_key}"
  rancher_ssl_chain = "${var.rancher_ssl_chain}"
  azs               = "${var.azs}"
  vpc_id            = "${var.vpc_id}"
  zone_id           = "${var.zone_id}"
  fqdn              = "${var.fqdn}"
}

module "servers" {
  source = "./modules/servers"

  name                 = "${var.name}"
  vpc_id               = "${var.vpc_id}"
  ami_id               = "${var.ami_id}"
  instance_type        = "${var.instance_type}"
  database_port        = "${var.database_port}"
  database_name        = "${var.database_name}"
  database_username    = "${var.database_username}"
  database_password    = "${var.database_password}"
  scale_min_size       = "${var.scale_min_size}"
  scale_max_size       = "${var.scale_max_size}"
  scale_desired_size   = "${var.scale_desired_size}"
  rancher_version      = "${var.rancher_version}"
  docker_version       = "${var.docker_version}"
  rhel_selinux         = "${var.rhel_selinux}"
  rhel_docker_native   = "${var.rhel_docker_native}"
  azs                  = "${var.azs}"
  elb_sec_grp_id       = "${module.elb.elb_sec_grp_id}"
  rds_database_address = "${module.rds.database_address}"
  elb_name             = "${module.elb.elb_name}"
}
