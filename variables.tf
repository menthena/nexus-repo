variable "access_key" {}
variable "secret_key" {}

variable "region" {
  default = "eu-west-2"
}

variable "private_key" {
  default = "~/.ssh/terraform"
}

variable "ansible_user" {
  default = "ubuntu"
}