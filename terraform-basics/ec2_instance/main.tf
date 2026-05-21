
# key pair- ssh-keygen

resource "aws_key_pair" "ec2_key" {
  key_name = "terra-key-ec2"
  # public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC0VzRy2FJYRU8NOIZoc9PhK0Xxg7U0EIsJBWhZPT0U9MvDVZVLHgLO2uVQF8W8OzbLqu179SX9vSLm+HCAmWj+UeR51XmMJVjyv7w4mAMn+RDZj8uH/qKcYmWIYAvEDh1r8yywfipOZZXUcOj02dfUvkBiIyapu1SpP0oyRQENjQfAaSmV+Wi9ZTa/t+8zDOLjY8xcaON9UbLKwHl+MFJXzzwuYBhlDPIL5KDnBabx5OnXQJV1zuCcvBzK9OozUo9HOYqEh8wci2vDMEEcArkwH0I99Lgi8+ihta8GY6pdwmRnv+OAtb5LubEXt+z9wbPtHEhS1WfAtcV23JFbwNO6+WO69MiF/qEmq3TsEWIxMX9EBNaFw23dWD+B+8FtMZJN0uv9GpYLh4OZ49rnH4051oLyVMQPg8s6R6epdDuouQ1+L6RDaTVP0OBnxcMCflWnHUGnT4s3mWoh54b+kAT262Zahy/76D3fQtAy3hzACqr4FnCc6h/lNCBQTPC6CiU= deepak.kumar30@DEL1-LHP-N82757"
  public_key = file("terra-key-ec2.pub")
}

#vpc and sg

resource "aws_default_vpc" "default" {
    tags = {
    Name = "Default VPC"
  }

}

resource "aws_security_group" "my_ec2_sg" {
  name   = "my_ec2_terra_sg"
  vpc_id = aws_default_vpc.default.id # <- interpolation

  #inbound rule
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH open"

  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP open"

  }
  #outbound rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "open to all ports- outbound"

  }
}

# ec2 instance

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "my_ec2_instance" {

  # for_each = tomap({
  #   terra-ec2-1 = "t2.micro"
  #   terra-ec2-2 = "t3.medium"
  # }) #meta-argument
  #
  count = 4

  depends_on = [aws_security_group.my_ec2_sg, aws_key_pair.ec2_key ]

  key_name        = aws_key_pair.ec2_key.key_name
  security_groups = [aws_security_group.my_ec2_sg.name]
  instance_type   = var.ec2_instance_type
  #instance_type = each.value
  ami             = data.aws_ami.ubuntu.id
  user_data = file("install_nginx_ec2.sh")
  #ami = "ami-09329ehekwqnwwjjwk" 

  root_block_device {
    volume_size = var.env == "prod" ? 15 : var.ec2_default_storage_capacity
    volume_type = "gp3"
  }

  tags = {
    #Name = each.key
    Name = "terra-ec2-instance"
  }

}