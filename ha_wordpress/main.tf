#As I have configured aws-cli I don't use credentials here
provider "aws" {
  region     = "${var.aws_region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

#=====================================create aws_vpc
resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    Name = "vvalk-vpc"
  }
}

#===================================== create aws_internet_gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "vvalk-igw"
  }
}

#===================================== create aws_route_table PUBLIC and add route to aws_internet_gateway
resource "aws_route_table" "pub_rt" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags {
    Name = "vvalk-pub-rt"
  }
}

#===================================== create aws_route_table PUBLIC for nat and add route to aws_internet_gateway
resource "aws_route_table" "priv_rt_nat" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.nat.id}"
  }

  tags {
    Name = "vvalk-priv-rt-nat"
  }
}

#===================================== create aws_route_table PRIVATE no internet
resource "aws_route_table" "priv_rt" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "vvalk-priv-rt"
  }
}

#===================================== create aws_subnets PUBLIC
resource "aws_subnet" "vvalk-pub" {
  count = "${var.count}"

  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${element(var.pub_subnets_cidr,count.index)}"
  availability_zone       = "${element(var.azs,count.index)}"
  map_public_ip_on_launch = "true"

  tags {
    Name = "vvalk-SN-${count.index+1}-pub"
  }
}

#===================================== create aws_subnets PRIVATE no internet
resource "aws_subnet" "vvalk-priv" {
  count             = "${var.count}"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${element(var.priv_subnets_cidr,count.index)}"
  availability_zone = "${element(var.azs,count.index)}"

  tags {
    Name = "vvalk-SN-${count.index+1}-priv"
  }
}

#===================================== create aws_subnets PUBLIC for nat
resource "aws_subnet" "vvalk-pub-nat" {
  vpc_id = "${aws_vpc.main.id}"

  #cidr_block = "${element(var.pub_nat_subnet_cidr,count.index)}"
  cidr_block        = "${var.pub_nat_subnet_cidr}"
  availability_zone = "${element(var.azs,count.index)}"

  tags {
    Name = "vvalk-pub-for-nat"
  }
}

#===================================== create aws_subnets PRIVATE with NAT
resource "aws_subnet" "vvalk-priv-nat" {
  count             = "${var.count}"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${element(var.priv_nat_subnets_cidr,count.index)}"
  availability_zone = "${element(var.azs,count.index)}"

  tags {
    Name = "vvalk-SN-${count.index+1}-priv-with-nat"
  }
}

# ===================================== public subnets route table association public route_table
resource "aws_route_table_association" "a_pub" {
  #  count = "${length(var.pub_subnets_cidr)}"
  count          = "${var.count}"
  subnet_id      = "${element(aws_subnet.vvalk-pub.*.id,count.index)}"
  route_table_id = "${aws_route_table.pub_rt.id}"
}

# ===================================== public for nat subnet route table association public route_table
resource "aws_route_table_association" "a_pub-nat" {
  subnet_id      = "${aws_subnet.vvalk-pub-nat.id}"
  route_table_id = "${aws_route_table.pub_rt.id}"
}

# ===================================== private subnets route table association private route_table no internet
resource "aws_route_table_association" "a_priv" {
  #  count = "${length(var.priv_subnets_cidr)}"
  count          = "${var.count}"
  subnet_id      = "${element(aws_subnet.vvalk-priv.*.id,count.index)}"
  route_table_id = "${aws_route_table.priv_rt.id}"
}

# ===================================== private with nat subnets route table association private route_tablewith nat
resource "aws_route_table_association" "a_priv_nat" {
  count          = "${var.count}"
  subnet_id      = "${element(aws_subnet.vvalk-priv-nat.*.id,count.index)}"
  route_table_id = "${aws_route_table.priv_rt_nat.id}"
}

# ===================================== Allocate elastic_ip
resource "aws_eip" "nat" {
  vpc = "true"

  tags {
    Name = "vvalk-EIP"
  }
}

# ===================================== Create aws_nat_gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.vvalk-pub-nat.id}"

  tags = {
    Name = "vvalk-nat-gw"
  }
}

# ===================================== access to alb from inet
resource "aws_security_group" "alb" {
  name        = "allow_access_to_alb_from_inet"
  description = "Allow 22;80,443 inbound connections to alb"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${var.my_ip}"

    #cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound http traffic to alb from my IP"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.my_ip}"
    description = "Allow inbound ssh traffic to alb from my IP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "${var.my_ip}"
    description = "Allow inbound ssl traffic to alb from my IP"
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = "${var.my_ip}"
    description = "Allow icmp echo  to  from my  IP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "vvalk-alb"
  }
}


###
# ===================================== access to alb from inet
resource "aws_security_group" "bast" {
  name        = "access_to_bast_from_inet"
  description = "Allow inbound connections to bast"
  vpc_id      = "${aws_vpc.main.id}"


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.my_ip}"
    description = "Allow inbound ssh traffic to bast from my IP"
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = "${var.my_ip}"
    description = "Allow icmp echo  to  from my  IP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "vvalk-bast"
  }
}
###
# =====================================  Access to app from ALB SG
resource "aws_security_group" "app" {
  name        = "allow http and ssh access_to_app_from_ALB"
  description = "Allow http and ssh  inbound connections to app"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.alb.id}"]
    description     = "Allow inbound http access  to app from ALB"
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.alb.id}", "${aws_security_group.bast.id}"]
    description     = "Allow inbound http and ssh  access  to app from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "vvalk-alb-to-app"
  }
}

# =====================================  Access to rds from app SG
resource "aws_security_group" "rds" {
  name        = "allow_3306_access_to_rds_from_app"
  description = "Allow DB inbound connections to rds"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.app.id}", "${aws_security_group.bast.id}"]
    description     = "Allow inbound mysql access  to rds from app"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "vvalk-app-to-rds"
  }
}

# =====================================  Access to rds from alb SG
resource "aws_security_group" "rds1" {
  name        = "allow_3306_access_to_rds_from_efs-server"
  description = "Allow DB inbound connections to rds from efs-server"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.alb.id}"]
    description     = "Allow inbound mysql access  to rds from efs-server"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "vvalk-efs_srv-to-rds1"
  }
}

# =====================================  Access to efs from app SG
resource "aws_security_group" "efs" {
  name        = "allow_NFS_access_to_EFS_from_app"
  description = "Allow nfs inbound connections from app"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = ["${aws_security_group.app.id}", "${aws_security_group.bast.id}"]
    description     = "Allow inbound NFS access  to efs from app"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "vvalk-app-to-efs"
  }
}

resource "aws_security_group" "efs1" {
  name        = "allow_NFS_access_to_EFS_from_efs-server"
  description = "Allow nfs inbound connections from efs-server"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = ["${aws_security_group.alb.id}"]
    description     = "Allow inbound NFS access  to efs from efs-server"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "vvalk-efs-srv-to-efs1"
  }
}

# =====================================  create network subnet group
resource "aws_db_subnet_group" "sbg" {
  name = "vvalk_sbg"

  #subnet_ids = ["${aws_subnet.frontend.id}", "${aws_subnet.backend.id}"]
  description = "vvalk DB subnet group"
  subnet_ids  = ["${aws_subnet.vvalk-priv.*.id}"]
}

# =====================================  create new aws_db_parameter_group
resource "aws_db_parameter_group" "rds_pg" {
  name        = "${var.rds_instance_identifier}-param-group"
  description = "parameter group for mariadb10.3.8"
  family      = "mariadb10.3"

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }
}

# =====================================  create aws_db_instance
resource "aws_db_instance" "vvalk_rds" {
  identifier          = "${var.rds_instance_identifier}"
  allocated_storage   = 5
  engine              = "mariadb"
  engine_version      = "10.3.8"
  instance_class      = "db.t2.micro"
  publicly_accessible = "false"
  multi_az            = "true"

  #  name                      = "${var.database_name}"
  #  username                  = "${var.database_user}"
  #  password                  = "${var.database_password}"
  name = "${var.database == "" ? local.database : var.database}"

  username                  = "${var.username == "" ? local.username : var.username}"
  password                  = "${var.password == "" ? local.password : var.password}"
  db_subnet_group_name      = "${aws_db_subnet_group.sbg.id}"
  vpc_security_group_ids    = ["${aws_security_group.rds.id}", "${aws_security_group.rds1.id}"]
  parameter_group_name      = "${aws_db_parameter_group.rds_pg.id}"
  skip_final_snapshot       = "true"
  final_snapshot_identifier = "Ignore"
  backup_window             = "${var.backup_window}"
  backup_retention_period   = "${var.backup_retention_period}"
}

# =====================================  create aws_efs_file_system
resource "aws_efs_file_system" "vvalk_efs" {
  creation_token   = "efs-example"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false"

  tags = {
    Name = "vvalk_efs"
  }
}

# =====================================  create aws_efs_mount_target
resource "aws_efs_mount_target" "efs_mt" {
  count           = "${var.count}"
  file_system_id  = "${aws_efs_file_system.vvalk_efs.id}"
  subnet_id       = "${element(aws_subnet.vvalk-priv.*.id,count.index)}"
  security_groups = ["${aws_security_group.efs.id}", "${aws_security_group.efs1.id}"]
}

#========================================================ec2_section for deployment files to efs
data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["${var.ami_name}"]
  }
}

#======================================================== describe key pair
resource "aws_key_pair" "vvalk_auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

#======================================================== describe template file for wp-config
data "template_file" "user-efs-server" {
  template = "${file("${path.module}/efs-srv_userdata.tpl")}"

  vars {
    file_system_id = "${aws_efs_file_system.vvalk_efs.id}"

    db_address  = "${aws_db_instance.vvalk_rds.address}"
    db_username = "${aws_db_instance.vvalk_rds.username}"
    db_password = "${aws_db_instance.vvalk_rds.password}"
    db_name     = "${aws_db_instance.vvalk_rds.name}"
  }
}

#========================================================start instance for deploy wordpress to ec2
resource "aws_instance" "efs_server" {
  count                                = "${var.instance_for_efs_count}"
  instance_type                        = "${var.instance_type}"
  ami                                  = "${data.aws_ami.server_ami.id}"
  instance_initiated_shutdown_behavior = "terminate"

  tags {
    Name = "vvalk-efs"
  }

  key_name               = "${aws_key_pair.vvalk_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.alb.id}"]
  subnet_id              = "${element(aws_subnet.vvalk-pub.*.id,count.index)}"
  user_data              = "${data.template_file.user-efs-server.*.rendered[count.index]}"
}


#========================================================bastion host
resource "aws_instance" "bastion_host" {
  count                                = 1
  instance_type                        = "${var.instance_type}"
  ami                                  = "${data.aws_ami.server_ami.id}"

  tags {
    Name = "vvalk-bastion"
  }

  key_name               = "${aws_key_pair.vvalk_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.bast.id}"]
  subnet_id              = "${element(aws_subnet.vvalk-pub.*.id,count.index)}"
  user_data              = "${data.template_file.user-bast-data.*.rendered[count.index]}"
  depends_on             = ["aws_instance.efs_server"]
  

}


#=======================================delay to fill efs with wordpress files
resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = "sleep 100"
  }

  triggers = {
    "before" = "${aws_instance.efs_server.id}"
  }
}


#================= obtain a certificate
resource "aws_acm_certificate" "vvalk-cert" {
  domain_name       = "${var.domain_name}"
  validation_method = "DNS"
}

#+++++++++++=====================validate with dns
resource "aws_route53_record" "cert_validation_dns_record" {
  name    = "${aws_acm_certificate.vvalk-cert.domain_validation_options.0.resource_record_name}"
  type    = "CNAME"
  zone_id = "${var.zone_id}"
  records = ["${aws_acm_certificate.vvalk-cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 300
}

resource "aws_route53_record" "cname_route53_alb" {
  zone_id = "${var.zone_id}"
  name    = "${var.domain_name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_lb.vvalk-alb.dns_name}"]
}

resource "aws_route53_record" "cname_route53_bastion" {
  zone_id = "${var.zone_id}"
  name    = "${var.bastion_domain_name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_instance.bastion_host.public_dns}"]
}


resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = "${aws_acm_certificate.vvalk-cert.arn}"
  validation_record_fqdns = ["${aws_acm_certificate.vvalk-cert.domain_validation_options.0.resource_record_name}"]
}

#======================================================== create  aws_alb_target_group
resource "aws_lb_target_group" "alb-tg" {
  name     = "vvalk-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"

  health_check {
    healthy_threshold   = 3
    interval            = 10
    timeout             = 5
    unhealthy_threshold = 2
    matcher              = "200-302"

  }

  stickiness {
    type = "lb_cookie"
  }
}

#======================================================== create  aws_alb

resource "aws_lb" "vvalk-alb" {
  name                       = "vvalk-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = ["${aws_security_group.alb.id}"]
  subnets                    = ["${aws_subnet.vvalk-pub.*.id}"]
  enable_deletion_protection = false

  tags = {
    Name = "vvalk-alb"
  }
}

#======================================================== create  listener port 80
resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = "${aws_lb.vvalk-alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.alb-tg.arn}"
    type             = "forward"
  }
}

#======================================================== create  listener port 443
resource "aws_alb_listener" "listener_https" {
  load_balancer_arn = "${aws_lb.vvalk-alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = "${aws_acm_certificate.vvalk-cert.arn}"

  default_action {
    target_group_arn = "${aws_lb_target_group.alb-tg.arn}"
    type             = "forward"
  }
}

#======================================================== describe template file for for app instances
data "template_file" "user-lc-data" {
  template = "${file("${path.module}/lc-userdata.tpl")}"

  vars {
    file_system_id = "${aws_efs_file_system.vvalk_efs.id}"
  }
}

#======================================================== describe template file for for bastion
data "template_file" "user-bast-data" {
  template = "${file("${path.module}/bast-userdata.tpl")}"

  vars {
    file_system_id = "${aws_efs_file_system.vvalk_efs.id}"
  }
}


#======================================================== create launch_configuration
resource "aws_launch_configuration" "vvalk-lc" {
  name                        = "vvalk-lc"
  image_id                    = "${data.aws_ami.server_ami.id}"
  instance_type               = "${var.instance_type}"
  security_groups             = ["${aws_security_group.app.id}"]
  key_name                    = "${var.key_name}"
  user_data                   = "${data.template_file.user-lc-data.*.rendered[count.index]}"
  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }
}

#======================================================== create autoscaling_group

resource "aws_autoscaling_group" "vvalk_asg" {
  name                      = "vvalk_asg"
  max_size                  = 4
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.vvalk-lc.name}"
  #vpc_zone_identifier       = ["${element(aws_subnet.vvalk-priv.*.id,count.index)}"]

  #availability_zones        = "${split(",", lookup(var.azs))}"
  vpc_zone_identifier       = ["${aws_subnet.vvalk-priv.*.id}"]
  depends_on                = ["null_resource.delay"]

  #resource "aws_instance" "efs_server" {
}

#======================================================== create autoscaling_attachment

resource "aws_autoscaling_attachment" "svc_asg" {
  alb_target_group_arn   = "${aws_lb_target_group.alb-tg.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.vvalk_asg.id}"
}
