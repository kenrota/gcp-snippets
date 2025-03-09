# README

* `cloud-sql-proxy` が起動していることを確認

```
gcloud compute ssh <VMインスタンス名> --ssh-flag="-p <ポート番号>" --command "sudo systemctl status cloud-sql-proxy"
```

* IAPトンネルを開始

```
gcloud compute start-iap-tunnel <VMインスタンス名> <cloud-sql-proxy のポート番号> --local-host-port=127.0.0.1:3306
```

* MySQLに接続

```
mysql -h 127.0.0.1 -P 3306 -u <ユーザ名> -p
```
