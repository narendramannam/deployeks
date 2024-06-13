variable "region" {
  type        = string
  description = "AWS region code like, eu-west-1"
}

variable "application_name" {
  type        = string
  description = ""
}

variable "application_env" {
  type        = string
  description = ""
}

variable "application_billing_code" {
  type        = string
  description = ""
}

variable "eks_version" {
  type        = string
  description = ""
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "dns_zone_name" {
  type        = string
  description = "Rouet53 hosted zone name"
}

variable "github_org" {
  type        = string
  description = "GitHub organization name"
}

variable "github_project" {
  type        = string
  description = "GitHub project/repo name under a given org"
}
