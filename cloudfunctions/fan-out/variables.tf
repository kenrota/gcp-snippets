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
