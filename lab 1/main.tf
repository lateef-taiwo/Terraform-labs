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
  profile = "default"
  region  = "us-west-2"
}

resource "aws_instance" "web_server" {
  ami           = "ami-0cf6f5c8a62fa5da6"
  instance_type = "t2.micro"
  # vpc_security_group_ids = [""]
  # subnet_id              = ""
  tags = {
    Name = "web-instance"
  }
}

