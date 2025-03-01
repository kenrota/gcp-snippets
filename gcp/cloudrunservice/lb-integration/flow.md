```mermaid
flowchart TD
    A[グローバルIPアドレス] --> B[グローバル転送ルール]
    B --> C[ターゲットHTTPプロキシ]
    C --> D[URLマップ]
    D --> E[バックエンドサービス]
    E --> F[サーバーレスNEG]
    F --> G[Cloud Runサービス]
```
