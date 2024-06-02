# Development

## 仮想環境

```bash
python -m venv venv
source ./venv/bin/activate
```

## パッケージインストール

```bash
pip install -r requirements.txt
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
