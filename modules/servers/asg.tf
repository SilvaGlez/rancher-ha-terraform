resource "aws_autoscaling_group" "rancher_ha" {
  name   = "${var.name}-asg"
  min_size = "${var.scale_min_size}"
  max_size = "${var.scale_max_size}"
  desired_capacity = "${var.scale_desired_size}"
  health_check_grace_period = 900
  #health_check_type = "elb"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.rancher_ha.name}"
  load_balancers = ["${var.elb_name}"]
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
                        "${var.elb_sec_grp_id}",
                   "${aws_security_group.rancher_ha_allow_internal.id}"]
    instance_type = "${var.instance_type}"
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

# User-data template
data "template_file" "userdata" {

    template = "${file("${path.module}/files/userdata.template")}"

    vars {
        # Database
        database_address  = "${var.rds_database_address}"
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
