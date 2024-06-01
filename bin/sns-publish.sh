curren_time=$(date "+%s")

aws sns publish \
    --region us-east-1 \
    --topic-arn "arn:aws:sns:us-east-1:564151284033:sns-sqs-MySnsTopic-A0nWRQRVhkOv"  \
    --subject testSubject \
    --message "$curren_time"