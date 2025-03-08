# README

* 接続前にIAPトンネルを開始
```
gcloud compute start-iap-tunnel <VMインスタンス名> 9200 --local-host-port=127.0.0.1:9200
```

* 接続
```
curl -X GET "http://127.0.0.1:9200/_cluster/health?pretty"
```
