# RDS
resource "aws_security_group" "rancher_ha_allow_db" {
  name = "${var.name}_allow_db"
  description = "Allow Connection from internal"
  vpc_id = "${var.vpc_id}"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = "${var.database_port}"
    to_port = "${var.database_port}"
    protocol = "tcp"
    #security_groups = "${var.database_security_groups}"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
resource "aws_db_instance" "rancherdb" {
  allocated_storage    = "${var.database_storage}"
  engine               = "mysql"
  instance_class       = "${var.database_instance_class}"
  name                 = "${var.database_name}"
  username             = "${var.database_username}"
  password             = "${var.database_password}"
  vpc_security_group_ids = ["${aws_security_group.rancher_ha_allow_db.id}"]
  }
