output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.apache_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.apache_server.public_dns
}

output "application_url" {
  description = "Full URL to access the Apache web server"
  value       = "http://${aws_instance.apache_server.public_dns}"
}