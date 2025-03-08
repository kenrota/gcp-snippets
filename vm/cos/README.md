# README

* Artifact Registry のリポジトリを作成
  ```bash
  gcloud artifacts repositories create <リポジトリ名> --location=<リージョン> --repository-format=docker
  ```
* イメージをビルド
  ```bash
  docker build --platform linux/amd64 -t <リージョン>-docker.pkg.dev/<プロジェクトID>/<リポジトリ名>/<イメージ名>:<タグ名> .
  ```
  * Apple Silicon の場合 `--platform linux/amd64` が必要
* 認証
  ```bash
  gcloud auth configure-docker <リージョン>-docker.pkg.dev
  ```
* イメージをプッシュ
  ```bash
  docker push <リージョン>-docker.pkg.dev/<プロジェクトID>/<リポジトリ名>/<イメージ名>:<タグ名>
  ```
