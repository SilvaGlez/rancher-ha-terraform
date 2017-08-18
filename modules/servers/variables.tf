variable "name" {}
variable "ami_id" {}
variable "vpc_id" {}
variable "instance_type" {}
variable "key_name" {}
variable "database_port"    {}
variable "database_name"    {}
variable "database_username" {}
variable "database_password" {}
variable "scale_min_size" {}
variable "scale_max_size" {}
variable "scale_desired_size" {}
variable "rancher_version" {}
variable "docker_version" {}
variable "rhel_selinux" {}
variable "rhel_docker_native" {}
variable "azs" {
  type = "list"
}
variable "elb_sec_grp_id" {}
variable "rds_database_address" {}
variable "elb_name" {}

output "rancher_ha_allow_elb_id" {
  value = "${aws_security_group.rancher_ha_allow_elb.id}"
}
