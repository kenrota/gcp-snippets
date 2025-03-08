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
  # 必須ロール
  # - Cloud Run 起動元 (triggerが関数を起動するために必要)
}
