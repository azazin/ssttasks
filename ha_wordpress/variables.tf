variable "aws_region" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "vpc_cidr" {}

variable "pub_subnets_cidr" {
  type = "list"
}

variable "priv_subnets_cidr" {
  type = "list"
}

variable "priv_nat_subnets_cidr" {
  type = "list"
}

variable "pub_nat_subnet_cidr" {}

variable "azs" {
  type = "list"
}

variable "count" {}
variable "rds_instance_identifier" {}

#variable "database_name" {}
#variable "database_user" {}
#variable "database_password" {}
variable "key_name" {}

variable "public_key_path" {}
variable "instance_type" {}
variable "instance_for_efs_count" {}
variable "ami_name" {}

variable "password" {
  description = "Password for the master DB user. Leave empty to generate."
  default     = ""
}

variable "username" {
  description = "Username for the master DB user. Leave empty to generate."
  default     = ""
}

variable "database" {
  description = "The name of the database to create when the DB instance is created."
  default     = ""
}

variable "backup_retention_period" {}
variable "backup_window" {}
variable "domain_name" {}
variable "bastion_domain_name" {}
variable "zone_id" {}

variable "my_ip" {
  type = "list"
}
