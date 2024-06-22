# README

## 呼び出し

* `gcloud`

```bash
gcloud functions call <関数名> --data '{"name":"foo"}'
```

* `curl`

```bash
curl -X POST -H "Content-Type: application/json" <URL> -d '{"name":"foo"}'
```
