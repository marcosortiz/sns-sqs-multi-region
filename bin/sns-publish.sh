aws sns publish \
    --region us-east-1 \
    --topic-arn "arn:aws:sns:us-east-1:564151284033:sns-sqs-MySnsTopic-A0nWRQRVhkOv"  \
    --subject testSubject \
    --message testMessage



# aws sns publish \
#     --topic-arn "arn:aws:sns:us-west-2:123456789012:my-topic" \
#     --message file://message.txt