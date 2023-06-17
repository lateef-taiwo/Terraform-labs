terraform {
  required_version = ">= 0.15"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.46"
    }
  }
}

provider "aws" {
  region  = "us-west-2"
  profile = "default"
}

# defining out networking module
module "networking" {
  source    = "./modules/networking"
} 

# creating an ec2 instance 
resource "aws_instance" "web_server" {
  ami           = "ami-0cf6f5c8a62fa5da6"
  instance_type = "t2.micro"
  vpc_security_group_ids = [module.networking.sec_group.id]
  subnet_id              = module.networking.subnet.id

  tags = {
    Name = "my-ec2-instance"
  }
}


# Code Review

#     First, we set the terraform and provider configs; this should be familiar at least.
#     Next, we create the module block for the networking module. We set the source as a directory within the root project. You’ll be creating this directory soon.
#     Finally, we create an EC2 instance with the aws_instance block. Note the vpc_security_group_ids and subnet_id settings attribute values; these are references to the networking module that you will create next.
