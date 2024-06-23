# README

Cloud Functions 関数のコンテナを buildpacks でビルドし、COSにデプロイする。
接続確認はローカルからIAP経由で行う。

## コンテナイメージをビルド

* Artifact Registry のリポジトリを作成
  ```
  gcloud artifacts repositories create <リポジトリ名> --location=<リージョン> --repository-format=docker
  ```
* イメージをビルド
  ```
  pack build <リージョン>-docker.pkg.dev/<プロジェクトID>/<リポジトリ名>/<イメージ名>:<タグ名> \
  --builder gcr.io/buildpacks/builder \
  --env GOOGLE_FUNCTION_SIGNATURE_TYPE=http \
  --env GOOGLE_FUNCTION_TARGET=hello \
  --env GOOGLE_PYTHON_VERSION="3.11.x"
  ```
  * 参考ドキュメント
    [Quickstart: Build a Deployable Container](https://github.com/GoogleCloudPlatform/functions-framework-python?tab=readme-ov-file#quickstart-build-a-deployable-container)

* 認証
  ```
  gcloud auth configure-docker <リージョン>-docker.pkg.dev
  ```
* イメージをプッシュ
  ```
  docker push <リージョン>-docker.pkg.dev/<プロジェクトID>/<リポジトリ名>/<イメージ名>:<タグ名>
  ```

## デプロイ

* `terraform.tfvars` の `container_image` にイメージ名を指定する
* デプロイ
  ```
  terraform apply
  ```
* イメージを更新した場合はインスタンスを入れ替える
  ```
  terraform apply -replace="google_compute_instance.default"
  ```

## ローカルから接続

* IAPトンネルを開始
  ```
  gcloud compute start-iap-tunnel <VMインスタンス名> 8080 --local-host-port=127.0.0.1:8080
  ```
* 接続
  ```
  curl localhost:8080
  ```
