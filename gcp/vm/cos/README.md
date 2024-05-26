# README

* Artifact Registry のリポジトリを作成
  ```shell
  gcloud artifacts repositories create <リポジトリ名> --location=<リージョン> --repository-format=docker
  ```
* イメージをビルド
  ```shell
  docker build --platform linux/amd64 -t <リージョン>-docker.pkg.dev/<プロジェクトID>/<リポジトリ名>/<イメージ名>:<タグ名> .
  ```
  * Apple Silicon の場合 `--platform linux/amd64` が必要
* 認証
  ```shell
  gcloud auth configure-docker <リージョン>-docker.pkg.dev
  ```
* イメージをプッシュ
  ```shell
  docker push <リージョン>-docker.pkg.dev/<プロジェクトID>/<リポジトリ名>/<イメージ名>:<タグ名>
  ```
