# Development

## パッケージインストール

```
poetry install
```

## requirements.txt のエクスポート

```
poetry export -f requirements.txt -o requirements.txt --without-hashes
```

## gcloud の設定

```bash
gcloud config set core/project <プロジェクトID>
gcloud config set functions/region <リージョン>
```

## pre-commit

* インストール
  ```bash
  brew install pre-commit
  ```
* フックをインストール
  ```bash
  pre-commit install
  ```
* 手動実行
  ```bash
  pre-commit run --all-files
  ```
