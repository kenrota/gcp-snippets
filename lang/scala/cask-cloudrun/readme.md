# README

* jarファイルを作成
```
./mill app.assembly
```

* jarファイルを指定して起動
```
java -jar ./out/app/assembly.dest/out.jar
```

## dockerコンテナで起動

* コンテナイメージをビルド
```
 docker build -t simple-server:v1 .
```

* 起動
```
docker run simple-server:v1
```

## Cloud Run サービスにデプロイ

```
./deploy.sh <project_id> <region> <service_account> <repository_name>
```
