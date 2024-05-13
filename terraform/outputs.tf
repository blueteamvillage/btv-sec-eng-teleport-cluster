output "public_ip_addr" {
  value = aws_eip.telelport.public_ip
}

output "private_ip_addr" {
  value = aws_instance.teleport.private_ip
}

output "teleport_instance_profile_role_name" {
  value = aws_iam_role.teleport.id
}

output "teleport_sg_id" {
  value = aws_security_group.teleport_cluster.id
}
