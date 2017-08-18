variable "name" {}
variable "rancher_ssl_cert" {}
variable "rancher_ssl_key"  {}
variable "rancher_ssl_chain"  {}
variable "vpc_id" {}
variable "azs" {
  type = "list"
}
variable "zone_id" {}
variable "fqdn" {}

output "elb_name" {
  value = "${aws_elb.rancher_ha.name}"
}
output "elb_sec_grp_id" {
  value = "${aws_security_group.rancher_ha_web_elb.id}"
}
