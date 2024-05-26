# Development

## 仮想環境

```shell
python -m venv venv
source ./venv/bin/activate
```

## パッケージインストール

```shell
pip install -r requirements.txt
```

## gcloud の設定

```shell
gcloud config set core/project <プロジェクトID>
gcloud config set functions/region <リージョン>
```

## pre-commit

* インストール
  ```shell
  brew install pre-commit
  ```
* フックをインストール
  ```shell
  pre-commit install
  ```
* 手動実行
  ```shell
  pre-commit run --all-files
  ```
