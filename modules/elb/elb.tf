# Certificate
resource "aws_iam_server_certificate" "rancher_ha"
 {
  name             = "${var.name}-cert"
  certificate_body = "${file("${var.rancher_ssl_cert}")}"
  private_key      = "${file("${var.rancher_ssl_key}")}"
  certificate_chain = "${file("${var.rancher_ssl_chain}")}"
  lifecycle {
    create_before_destroy = true
  }
}

# ELB Security Group
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

# ELB
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

resource "aws_route53_record" "www" {
   zone_id = "${var.zone_id}"
   name = "${var.fqdn}"
   type = "CNAME"
   ttl = "300"
   records = ["${aws_elb.rancher_ha.dns_name}"]
}
