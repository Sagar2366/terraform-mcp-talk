mock_provider "aws" {}

run "security_checks" {
  command = plan

  assert {
    condition     = aws_instance.web.instance_type == "t3.micro"
    error_message = "EC2 instance type must be t3.micro, got ${aws_instance.web.instance_type}"
  }

  assert {
    condition     = length(aws_instance.web.root_block_device) > 0
    error_message = "Root block device must be explicitly configured (with encryption)"
  }

  assert {
    condition     = aws_instance.web.tags != null
    error_message = "EC2 instance must have tags"
  }
}
