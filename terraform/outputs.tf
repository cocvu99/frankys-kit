output "master_public_ip" {
  description = "Public IP of the Master Node"
  value       = aws_spot_instance_request.master.public_ip
}

output "master_ssh_command" {
  description = "Command to SSH into Master Node"
  value       = "ssh -i ~/.ssh/frankys_key ubuntu@${aws_spot_instance_request.master.public_ip}"
}

output "worker_public_ips" {
  description = "Public IPs of Worker Nodes"
  value       = aws_spot_instance_request.workers[*].public_ip
}