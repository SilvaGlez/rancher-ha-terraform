variable "name" {}
variable "database_port"    {}
variable "database_name"    {}
variable "database_username" {}
variable "database_password" {}
variable "database_storage" {}
variable "database_instance_class" {}
variable "vpc_id" {}
#variable "database_security_groups" {
#  type = "list"
#}

output "database_address" {
  value = "${aws_db_instance.rancherdb.address}"
}
