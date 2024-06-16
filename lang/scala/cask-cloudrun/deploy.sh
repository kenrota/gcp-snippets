#!/usr/bin/env sh

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <project_id> <region> <service_account> <repository_name>"
    exit 1
fi

PROJECT_ID=$1
REGION=$2
SERVICE_ACCOUNT=$3
REPOSITORY_NAME=$4
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_NAME}/simple-server:v1"

./mill app.assembly && \
docker build --platform linux/amd64 -t $IMAGE . && \
docker push $IMAGE && \
gcloud run deploy simple-server --image $IMAGE --platform managed --region $REGION --allow-unauthenticated --service-account $SERVICE_ACCOUNT
