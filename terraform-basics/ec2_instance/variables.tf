
variable "ec2_instance_type"{
  default = "t3.micro"
  type = string
}

variable "ec2_default_storage_capacity" {
  default = 8
  type = number
}

variable "env" {
  default = "prod"
  type = string
}