variable "instance_type" {
  description = "EC2 instance type (t3.medium recommended for K8s)"
  default     = "t3.medium"
}

variable "spot_price" {
  description = "Max price you are willing to pay for Spot Instances"
  default     = "0.03"
}

variable "worker_count" {
  description = "Number of worker nodes to provision"
  default     = 2
}