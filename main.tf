//
// Template: tf_addressbook
//

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

// Security Group Resource for Module
resource "aws_security_group" "sg_web_ab" {
    name = "${var.security_group_name}-${var.mytag}"
    description = "Security Group ${var.security_group_name}"
    vpc_id = "${var.vpc_id}"

    // allows traffic from the SG itself for tcp
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        self = true
    }

    // allows traffic from the SG itself for udp
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "udp"
        self = true
    }

    // allow traffic for TCP 22
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // allow traffic for TCP 80
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["${var.source_cidr_block}"]
    }

    // allow traffic for TCP 1099 (JMX)
    ingress {
        from_port = 1099
        to_port = 1099
        protocol = "tcp"
        cidr_blocks = ["${var.source_cidr_block}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

// Security Group Resource for ELB
resource "aws_security_group" "sg_web_elb" {
    name = "${var.security_group_name}-${var.mytag}-elb"
    description = "Security Group ${var.security_group_name}"
    vpc_id = "${var.vpc_id}"

    // allow public traffic for TCP 80
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
resource "aws_elb" "addressbook_web_elb" {
  name = "${var.elb_name}-${var.mytag}"
  subnets = ["${var.subnet_az1}","${var.subnet_az2}"]
  internal = "${var.elb_is_internal}"
  security_groups = ["${aws_security_group.sg_web_elb.id}"]

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "${var.health_check_target}"
    interval = 30
  }

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  cross_zone_load_balancing = true
}

resource "aws_launch_configuration" "addressbook_web_launch_config" {
    name = "${var.lc_name}-${var.mytag}"
    image_id = "${var.ami_id}"
    instance_type = "${var.instance_type}"
    key_name = "${var.key_name}"
    security_groups = ["${aws_security_group.sg_web_ab.id}"]
    user_data = "${file(var.user_data)}"
    associate_public_ip_address = true
}

resource "aws_autoscaling_group" "addressbook_web_autoscaling_group" {
  //We want this to explicitly depend on the launch config above
  depends_on = ["aws_launch_configuration.addressbook_web_launch_config"]
  name = "${var.asg_name}-${var.mytag}"

  // The chosen availability zones *must* match the AZs the VPC subnets are
  //   tied to.
  availability_zones = ["${var.az1}","${var.az2}"]
  vpc_zone_identifier = ["${var.subnet_az1}","${var.subnet_az2}"]

  // Uses the ID from the launch config created above
  launch_configuration = "${aws_launch_configuration.addressbook_web_launch_config.id}"

  max_size = "${var.asg_number_of_instances}"
  min_size = "${var.asg_minimum_number_of_instances}"
  desired_capacity = "${var.asg_number_of_instances}"
  health_check_grace_period = "${var.health_check_grace_period}"
  health_check_type = "${var.health_check_type}"
  load_balancers = ["${aws_elb.addressbook_web_elb.name}"]
  tag {
    key = "service"
    value = "${var.service}"
    propagate_at_launch = true
  }
  tag {
    key = "role"
    value = "app"
    propagate_at_launch = true
  }
  tag {
    key = "environment"
    value = "${var.mytag}"
    propagate_at_launch = true
  }
}
