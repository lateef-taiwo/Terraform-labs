terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.42"
    }
  }
  required_version = ">= 0.15.3"
}

# default provider
provider "aws" {
  profile = "default"
  region = "us-west-2"
}

# this is an additional provider
provider "aws" {
  profile = "default"
  alias = "secondary"
  region = "us-east-2"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# usernames
variable "iam_user_names" {
  description = "List containing IAM users names"
  type        = list(string)
  default     = ["nfs-server", "web-server-1", "web-server-2", "web-server-3", "db-server"]
}

# get the AMI ID for the default provider
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

  #The aws_ami data source fetches the latest Ubuntu AMI of the jammy release.
    #The aws_vpc data source gets the VPC resource. This VPC resource was created on your lab account.
    #The aws_subnet resource retrieves one of the subnets in the VPC.

# create an IAM user resource for each item in the list
resource "aws_iam_user" "boss_accounts" {
  for_each = toset(var.iam_user_names)
  name     = each.key
}

# create a security group
resource "aws_security_group" "web_instance_sg" {
  name        = "sec-group"
  description = "Allowing requests to the web servers"
 

  tags = {
    Name = "web-server-security-group"
  }
}

resource "aws_security_group" "web_sg" {
  name   = "SSH-SG"
  vpc_id = aws_vpc.my_vpc.id
  for_each = toset(var.iam_user_names)

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# create an instance per person
resource "aws_instance" "people_servers" {
  for_each = toset(var.iam_user_names)

  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_instance_sg.id]
  

  # create these after the IAM users are created
  depends_on = [
    aws_iam_user.boss_accounts
  ]

  tags = {
    Name = "${each.key}"
  }
}

resource "aws_key_pair" "tf-key-pair" {
  key_name = "tf-key-pair.pem"
  public_key = tls_private_key.rsa.public_key_openssh
  for_each = toset(var.iam_user_names)

}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "tf-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "tf-key-pair"
}

# create s3 acl and bucket
resource "aws_s3_bucket_acl" "my_bucket_acl" {
  bucket = aws_s3_bucket.my_bucket.id
  acl    = "private"
  provider = aws.secondary
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "website-bucket-396500261"
  provider = aws.secondary
}

# Code Review

#     The aws_instance.people_servers block uses the for_each meta-argument to iterate over the variables list that we create. For each name in the list, it will create an EC2 instance. Here are some other things to note:
#     The instance Name tag will be a combination of text and the user name.
#     The instances will be created after the IAM users as we set in depends_on. Admittedly, this isn’t functionally needed, but it does demonstrate how the feature is used.
#     The S3 ACL and bucket will be created in the secondary AWS provider.
