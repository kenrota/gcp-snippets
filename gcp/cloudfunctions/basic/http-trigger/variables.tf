variable "project_id" {
  type = string
}

variable "prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "service_account" {
  type = string
}

variable "allowed_invoker_emails" {
  type = list(string)
}
