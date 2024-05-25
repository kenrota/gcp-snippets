# README

## 呼び出し

* `gcloud`

```shell
gcloud functions call <関数名> --data '{"name":"foo"}'
```

* `curl`

```shell
curl -X POST -H "Content-Type: application/json" <URL> -d '{"name":"foo"}'
```
