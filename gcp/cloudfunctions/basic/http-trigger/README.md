# README

## 呼び出し

* `gcloud`
  * public
    ```
    FUNCTION_NAME=$(terraform output -raw function_name_public); \
     gcloud functions call $FUNCTION_NAME --data '{"example_data":"foo"}'
    ```
  * private
    ```
    FUNCTION_NAME=$(terraform output -raw function_name_private); \
     gcloud functions call $FUNCTION_NAME --data '{"example_data":"foo"}'
    ```

* `curl`
  * public
    ```
    FUNCTION_URL=$(terraform output -raw function_url_public); \
    curl -X POST \
      -H "Content-Type: application/json" \
      $FUNCTION_URL \
      -d '{"example_data":"foo"}'
    ```
  * private
    ```
    ID_TOKEN=$(gcloud auth print-identity-token); \
    FUNCTION_URL=$(terraform output -raw function_url_private); \
      curl -X POST \
      -H "Authorization: Bearer $ID_TOKEN" \
      -H "Content-Type: application/json" \
      $FUNCTION_URL \
      -d '{"example_data":"foo"}'
    ```
