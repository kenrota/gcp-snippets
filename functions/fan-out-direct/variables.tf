variable "project_id" {
  type = string
}

variable "prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "num_workers" {
  type        = number
  description = "Number of workers"
  validation {
    condition     = var.num_workers > 0
    error_message = "Number of workers must be greater than 0"
  }
}
