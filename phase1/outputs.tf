output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID du sous-réseau public"
  value       = aws_subnet.public.id
}

output "web_server_id" {
  description = "ID de l'instance serveur web"
  value       = aws_instance.web_server.id
}

output "web_server_public_ip" {
  description = "IP publique du serveur web"
  value       = aws_instance.web_server.public_ip
}

output "web_server_public_dns" {
  description = "DNS public du serveur web"
  value       = aws_instance.web_server.public_dns
}

output "application_url" {
  description = "URL de l'application"
  value       = "http://${aws_instance.web_server.public_ip}"
}

output "ssh_command" {
  description = "Commande SSH pour se connecter au serveur web"
  value       = "ssh -i <your-key.pem> ubuntu@${aws_instance.web_server.public_ip}"
}
