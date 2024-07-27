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
  # 必須ロール
  # - ログ書き込み (VMがCloud Logging にログを書き込むために必要)
}

variable "ssh_port" {
  type = number
}
