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
  # 必須ロール
  # - Pub/Sub パブリッシャー (func1がPub/Subメッセージを送信するために必要)
  # - Storage オブジェクト ユーザー (func2がストレージにファイルを書き込むために必要)
}

variable "trigger_sa_email" {
  type        = string
  description = "Service Account for Pub/Sub trigger"
  # 必須ロール
  # - Cloud Run 起動元 (triggerがfunc2を起動するために必要)
}
