output "vpc" {
  value = aws_vpc.my_vpc
}

output "subnet" {
  value = aws_subnet.public_subnet
}

output "sec_group" {
  value = aws_security_group.web_sg
} 

output "public_ip" {
  value = aws_instance.web_server.public_ip
}
# Code Review

#     We defined three values to output from this module.
#     For each value, we reference the resources created in the main.tf file. Note how these references are made; it uses the <resource_type>.<resource_label> notation.
