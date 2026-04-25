mock_provider "aws" {}

run "security_checks" {
  command = plan

  assert {
    condition     = aws_instance.web.instance_type == "t3.micro"
    error_message = "EC2 instance type must be t3.micro, got ${aws_instance.web.instance_type}"
  }

  assert {
    condition     = aws_instance.web.root_block_device[0].encrypted == true
    error_message = "Root volume must be encrypted"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.https.from_port == 443
    error_message = "Ingress rule must allow port 443"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.https.to_port == 443
    error_message = "Ingress rule must allow only port 443"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.https.ip_protocol == "tcp"
    error_message = "Ingress rule must use TCP protocol"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.https.cidr_ipv4 == "0.0.0.0/0"
    error_message = "HTTPS must be allowed from 0.0.0.0/0"
  }

  assert {
    condition     = lookup(aws_instance.web.tags, "Name", "") != ""
    error_message = "EC2 instance must have a Name tag"
  }
}
