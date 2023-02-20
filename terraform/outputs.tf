output "public_ip_addr" {
  value = aws_eip.telelport.public_ip
}

output "private_ip_addr" {
  value = aws_instance.teleport.private_ip
}
