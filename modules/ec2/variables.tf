variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "allowed_ssh_cidr" {
  type = string
}

variable "key_pair_name" {
  type    = string
  default = ""
}

variable "instance_profile_name" {
  type = string
}

variable "alb_security_group_id" {
  type = string
}
