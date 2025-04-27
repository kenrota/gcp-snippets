# README

* 接続前にIAPトンネルを開始
  ```
  gcloud compute start-iap-tunnel <VMインスタンス名> 8086 --local-host-port=127.0.0.1:8086
  ```

* cbtrcを設定
  ```
  cat <<EOF > ~/.cbtrc
  project = fake-project
  instance = fake-instance
  creds = fake-cred
  EOF
  ```

* テーブルを作成
  ```
  export BIGTABLE_EMULATOR_HOST=localhost:8086
  cbt createtable my-table
  ```
