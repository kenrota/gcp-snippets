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
  description = "Service account email for Cloud Functions"
}

variable "trigger_sa_email" {
  type        = string
  description = "Service account email for Pub/Sub trigger"
}
