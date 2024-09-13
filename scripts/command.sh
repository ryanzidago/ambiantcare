curl "https://u18flxwwk84qxdtd.eu-west-1.aws.endpoints.huggingface.cloud" \
-X POST \
--data-binary "@$1" \
-H "Accept: application/json" \
-H "Authorization: Bearer $HUGGING_FACE_API_KEY" \
-H "Content-Type: audio/x-mpeg-3" \