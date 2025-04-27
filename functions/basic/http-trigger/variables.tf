variable "project_id" {
  type = string
}

variable "prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "allowed_invoker_emails" {
  type = list(string)
}

variable "enable_public_function" {
  type    = bool
  default = false
}
