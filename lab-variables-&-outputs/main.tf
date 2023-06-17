terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.42"
    }
  }
  required_version = ">= 0.15.3"
}

provider "aws" {
  profile = "skillmix-lab"
  region  = var.region
}

data "aws_vpc" "lab_vpc" {
  filter {
    name = "tag:Name"
    values = ["Skillmix Lab"]
  }
}

data "aws_subnet" "lab_subnet" {
  filter {
    name = "tag:Name"
    values = ["Skillmix Lab Public Subnet (AZ1)"]
  }
}

resource "aws_security_group" "web_instance_sg" {
  name        = "web-server-security-group"
  description = "Allowing requests to the web servers"
  vpc_id = data.aws_vpc.lab_vpc.id

  tags = {
    Name = "web-server-security-group"
  }
}

resource "aws_launch_template" "web_launch_template" {
  name          = "web-launch-template"
  image_id      = "ami-098e42ae54c764c35"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_instance_sg.id]
}

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = [data.aws_subnet.lab_subnet.id]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_template {
    id      = aws_launch_template.web_launch_template.id
    version = "$Latest"
  }
}

# resource "aws_security_group" "allow_tls" {
#   name        = "allow_tls"
#   description = "Allow TLS inbound traffic"
#   vpc_id = data.aws_vpc.lab_vpc.id

#   ingress {
#     description      = "TLS from VPC"
#     from_port        = 443
#     to_port          = 443
#     protocol         = "tcp"
#     cidr_blocks      = [aws_vpc.lab_vpc.cidr_block]
#     ipv6_cidr_blocks = [aws_vpc.lab_vpc.ipv6_cidr_block]
#   }

#   egress {
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   tags = {
#     Name = "allow_tls"
#   }
# }
