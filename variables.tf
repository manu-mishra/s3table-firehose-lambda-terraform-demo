variable "stack_name" {
  description = "Stack name for resource naming"
  type        = string
  default     = "firehosetos3demo"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "enable_encryption" {
  description = "Enable KMS encryption"
  type        = bool
  default     = true
}
