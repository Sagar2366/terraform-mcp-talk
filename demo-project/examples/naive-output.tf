# This is the "naive" Terraform that an unguided LLM typically generates.
# Used as a fallback for Act 1 if live generation doesn't cooperate.
# DO NOT use this in production — it exists to show what goes wrong.

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

# No private subnets
# No flow logs
# No DNS settings

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-cluster"
  cluster_version = "1.28"                              # outdated version
  vpc_id          = aws_vpc.main.id
  subnet_ids      = [aws_subnet.public1.id, aws_subnet.public2.id]  # public subnets!

  # Public endpoint — accessible from internet
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  # No encryption config
}

resource "aws_s3_bucket" "state" {
  bucket = "my-terraform-state"
  # No versioning
  # No encryption
  # No public access block
}

resource "aws_security_group" "app" {
  name   = "app-sg"
  vpc_id = aws_vpc.main.id

  # Wide open — classic AI mistake
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# No tags anywhere
# No variables — everything hardcoded
# No outputs
