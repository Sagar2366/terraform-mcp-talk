mock_provider "aws" {
  alias = "fake"

  mock_resource "aws_s3_bucket" {
    defaults = {
      id  = "mock-bucket-id"
      arn = "arn:aws:s3:::mock-bucket"
    }
  }

  mock_resource "aws_s3_bucket_versioning" {
    defaults = {
      id = "mock-bucket-versioning"
    }
  }

  mock_resource "aws_s3_bucket_server_side_encryption_configuration" {
    defaults = {
      id = "mock-bucket-sse"
    }
  }

  mock_resource "aws_s3_bucket_public_access_block" {
    defaults = {
      id = "mock-bucket-pab"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      id  = "mock-kms-key-id"
      arn = "arn:aws:kms:ap-south-1:123456789012:key/mock-key"
    }
  }

  mock_resource "aws_security_group" {
    defaults = {
      id  = "sg-mock12345"
      arn = "arn:aws:ec2:ap-south-1:123456789012:security-group/sg-mock"
    }
  }
}
