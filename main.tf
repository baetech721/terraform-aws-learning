terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket = "baetech-terraform-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

# Existing VPC
data "aws_vpc" "existing" {
  id = "vpc-01d1278ba4736770f"
}

# Existing subnet used by your working EC2
data "aws_subnet" "existing" {
  id = "subnet-0e28360e06b70a14c"
}

# Existing launch-wizard-3 security group
data "aws_security_group" "launch_wizard_3" {
  name   = "launch-wizard-3"
  vpc_id = data.aws_vpc.existing.id
}

# Existing Ubuntu 24.04 LTS AMD64/x86_64 AMI
data "aws_ami" "ubuntu_2404" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    ]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# ONLY AWS resource Terraform creates
resource "aws_instance" "ubuntu" {
  ami           = data.aws_ami.ubuntu_2404.id
  instance_type = "t3.micro"

  subnet_id = data.aws_subnet.existing.id

  vpc_security_group_ids = [
    data.aws_security_group.launch_wizard_3.id
  ]

  # Give the instance a public IPv4 address.
  associate_public_ip_address = true

  # Use standard CPU credits.
  tags = {
    Name = "terraform-learning-instance"
  }
}
