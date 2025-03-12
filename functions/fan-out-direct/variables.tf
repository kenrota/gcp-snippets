variable "project_id" {
  type = string
}

variable "prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "functions_sa_email" {
  type        = string
  description = "Service Account for Cloud Functions"
}

variable "trigger_sa_email" {
  type        = string
  description = "Service Account for Pub/Sub trigger"
}

variable "num_workers" {
  type        = number
  description = "Number of workers"
  validation {
    condition     = var.num_workers > 0
    error_message = "Number of workers must be greater than 0"
  }
}
