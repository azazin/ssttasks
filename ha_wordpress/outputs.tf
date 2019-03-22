output "rds_addresses" {
  value = "${aws_db_instance.vvalk_rds.address}"
}

output "db_name" {
  value = "${aws_db_instance.vvalk_rds.name}"
}

output "db_password" {
  value = "${aws_db_instance.vvalk_rds.password}"
}

output "db_username" {
  value = "${aws_db_instance.vvalk_rds.username}"
}

output "fqdn_alb" {
  value = "${aws_route53_record.cname_route53_alb.name}"
}


output "fqdn_bastion" {
  value = "${aws_route53_record.cname_route53_bastion.name}"
}
