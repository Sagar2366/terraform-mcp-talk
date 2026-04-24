# ------------------------------------------------------------------
# main.tftest.hcl — Security contract for AI-generated Terraform
#
# These tests validate CONFIGURATION, not live infra. They run with
# mock providers — zero AWS credentials needed, zero cost, fast CI.
# ------------------------------------------------------------------

mock_provider "aws" {}

# ------------------------------------------------------------------
# Test 1: S3 state bucket must have encryption
# ------------------------------------------------------------------
run "s3_bucket_encryption_enabled" {
  command = plan

  assert {
    condition     = aws_s3_bucket_server_side_encryption_configuration.state.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "S3 state bucket must use KMS encryption, got: ${aws_s3_bucket_server_side_encryption_configuration.state.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm}"
  }
}

# ------------------------------------------------------------------
# Test 2: S3 state bucket must block ALL public access
# ------------------------------------------------------------------
run "s3_bucket_public_access_blocked" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.state.block_public_acls == true
    error_message = "S3 bucket must block public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.state.block_public_policy == true
    error_message = "S3 bucket must block public policies"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.state.ignore_public_acls == true
    error_message = "S3 bucket must ignore public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.state.restrict_public_buckets == true
    error_message = "S3 bucket must restrict public buckets"
  }
}

# ------------------------------------------------------------------
# Test 3: S3 state bucket must have versioning enabled
# ------------------------------------------------------------------
run "s3_bucket_versioning_enabled" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.state.versioning_configuration[0].status == "Enabled"
    error_message = "S3 state bucket must have versioning enabled"
  }
}

# ------------------------------------------------------------------
# Test 4: EKS must use private endpoint only
# ------------------------------------------------------------------
run "eks_private_endpoint" {
  command = plan

  assert {
    condition     = module.eks.cluster_endpoint_private_access == true
    error_message = "EKS cluster must have private endpoint access enabled"
  }

  assert {
    condition     = module.eks.cluster_endpoint_public_access == false
    error_message = "EKS cluster must NOT have public endpoint access"
  }
}

# ------------------------------------------------------------------
# Test 5: VPC must have flow logs enabled
# ------------------------------------------------------------------
run "vpc_flow_logs_enabled" {
  command = plan

  assert {
    condition     = module.vpc.enable_flow_log == true
    error_message = "VPC must have flow logs enabled"
  }
}

# ------------------------------------------------------------------
# Test 6: Security group must NOT allow 0.0.0.0/0 on non-443 ports
# ------------------------------------------------------------------
run "security_group_no_open_ingress" {
  command = plan

  assert {
    condition = alltrue([
      for rule in aws_security_group.app.ingress :
      !(contains(coalesce(rule.cidr_blocks, []), "0.0.0.0/0") && rule.from_port != 443)
    ])
    error_message = "Security group must not allow 0.0.0.0/0 ingress on any port except 443"
  }
}

# ------------------------------------------------------------------
# Test 7: KMS key must have rotation enabled
# ------------------------------------------------------------------
run "kms_key_rotation" {
  command = plan

  assert {
    condition     = aws_kms_key.eks.enable_key_rotation == true
    error_message = "KMS key must have automatic key rotation enabled"
  }
}

# ------------------------------------------------------------------
# Test 8: All resources must have required tags (via default_tags)
# ------------------------------------------------------------------
run "default_tags_present" {
  command = plan

  assert {
    condition     = provider.aws.default_tags[0].tags["ManagedBy"] == "terraform"
    error_message = "All resources must have ManagedBy = terraform tag"
  }

  assert {
    condition     = provider.aws.default_tags[0].tags["Environment"] != null
    error_message = "All resources must have an Environment tag"
  }

  assert {
    condition     = provider.aws.default_tags[0].tags["Team"] != null
    error_message = "All resources must have a Team tag"
  }
}
