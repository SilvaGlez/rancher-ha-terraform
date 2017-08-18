variable "name" {}
variable "ami_id" {}
variable "instance_type" {}
variable "key_name" {}
variable "rancher_ssl_cert" {}
variable "rancher_ssl_key"  {}
variable "rancher_ssl_chain"  {}
variable "database_port"    {}
variable "database_name"    {}
variable "database_username" {}
variable "database_password" {}
variable "database_storage" {}
variable "scale_min_size" {}
variable "scale_max_size" {}
variable "scale_desired_size" {}
variable "region" {}
variable "vpc_id" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "zone_id" {}
variable "fqdn" {}
variable "database_instance_class" {}
variable "rancher_version" {}
variable "docker_version" {}
variable "rhel_selinux" {}
variable "rhel_docker_native" { }
variable "azs" {
  type = "list"
}

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
    security_groups = ["${aws_security_group.rancher_ha_allow_elb.id}",
                        "${aws_security_group.rancher_ha_web_elb.id}",
                   "${aws_security_group.rancher_ha_allow_internal.id}"]
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
# Certificate
resource "aws_iam_server_certificate" "rancher_ha"
 {
  name             = "${var.name}-cert"
  certificate_body = "${var.rancher_ssl_cert}"
  private_key      = "${var.rancher_ssl_key}"
  certificate_chain = "${var.rancher_ssl_chain}"
  lifecycle {
    create_before_destroy = true
  }
}

# ELB
resource "aws_security_group" "rancher_ha_web_elb" {
  name = "${var.name}_web_elb"
  description = "Allow ports rancher "
  vpc_id = "${var.vpc_id}"
   egress {
     from_port = 0
     to_port = 0
     protocol = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
}

#Into servers
resource "aws_security_group" "rancher_ha_allow_elb" {
  name = "${var.name}_allow_elb"
  description = "Allow Connection from elb"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      security_groups = ["${aws_security_group.rancher_ha_web_elb.id}"]
  }
}

#Direct into Rancher HA instances
resource "aws_security_group" "rancher_ha_allow_internal" {
  name = "${var.name}_allow_internal"
  description = "Allow Connection from internal"
  vpc_id = "${var.vpc_id}"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 9345
    to_port = 9345
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ingress_all_rancher_ha" {
    security_group_id = "${aws_security_group.rancher_ha_allow_internal.id}"
    type = "ingress"
    from_port = 0
    to_port = "0"
    protocol = "-1"
    source_security_group_id = "${aws_security_group.rancher_ha_allow_internal.id}"
}

resource "aws_security_group_rule" "egress_all_rancher_ha" {
    security_group_id = "${aws_security_group.rancher_ha_allow_internal.id}"
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    source_security_group_id = "${aws_security_group.rancher_ha_allow_internal.id}"
}
# User-data template
data "template_file" "userdata" {

    template = "${file("${path.module}/files/userdata.template")}"

    vars {
        # Database
        database_address  = "${aws_db_instance.rancherdb.address}"
        database_port     = "${var.database_port}"
        database_name     = "${var.database_name}"
        database_username = "${var.database_username}"
        database_password = "${var.database_password}"
        rancher_version = "${var.rancher_version}"
        docker_version = "${var.docker_version}"
        rhel_selinux = "${var.rhel_selinux}"
        rhel_docker_native = "${var.rhel_docker_native}"
    }
}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.region}"
}

# Create a new load balancer
resource "aws_elb" "rancher_ha" {
  name = "${var.name}-elb"
  internal = false
  security_groups = ["${aws_security_group.rancher_ha_web_elb.id}"]
  availability_zones = "${var.azs}"
  listener {
    instance_port      = 8080
    instance_protocol  = "TCP"
    lb_port            = 443
    lb_protocol        = "SSL"
    ssl_certificate_id = "${aws_iam_server_certificate.rancher_ha.arn}"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:8080"
    interval            = 30
  }
}

resource "aws_proxy_protocol_policy" "websockets" {
  load_balancer  = "${aws_elb.rancher_ha.name}"
  instance_ports = ["8080"]
}

resource "aws_autoscaling_group" "rancher_ha" {
  name   = "${var.name}-asg"
  min_size = "${var.scale_min_size}"
  max_size = "${var.scale_max_size}"
  desired_capacity = "${var.scale_desired_size}"
  health_check_grace_period = 900
  #health_check_type = "elb"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.rancher_ha.name}"
  load_balancers = ["${aws_elb.rancher_ha.name}"]
  availability_zones = "${var.azs}"
  tag {
    key = "Name"
    value = "${var.name}"
    propagate_at_launch = true
  }
  lifecycle {
      create_before_destroy = true
  }

}

# rancher resource
resource "aws_launch_configuration" "rancher_ha" {
    name_prefix = "Launch-Config-rancher-server-ha"
    image_id = "${var.ami_id}"
    security_groups = [ "${aws_security_group.rancher_ha_allow_elb.id}",
                        "${aws_security_group.rancher_ha_web_elb.id}",
                   "${aws_security_group.rancher_ha_allow_internal.id}"]
    instance_type = "${var.instance_type}"
    key_name      = "${var.key_name}"
    user_data     = "${data.template_file.userdata.rendered}"
    associate_public_ip_address = false
    ebs_optimized = false
    root_block_device = [
      {
        volume_type = "gp2"
        volume_size = "30"
      }
    ]
    ebs_block_device = [
      {
        device_name = "/dev/xvdb"
        volume_type = "gp2"
        volume_size = "30"
      }
    ]
    lifecycle {
      create_before_destroy = true
    }
}

output "elb_dns"      { value = "${aws_elb.rancher_ha.dns_name}" }

#### Remove below here if you don't want Route 53 to handle the DNS zone####

# works
resource "aws_route53_record" "www" {
   zone_id = "${var.zone_id}"
   name = "${var.fqdn}"
   type = "CNAME"
   ttl = "300"
   records = ["${aws_elb.rancher_ha.dns_name}"]
}
