#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/config.sh"


echo "Deploying the stack on ${PRIMARY_REGION} ..."
sam deploy --stack-name $STACK_NAME --region $PRIMARY_REGION --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --resolve-s3
aws cloudformation describe-stacks --stack-name $STACK_NAME --region $PRIMARY_REGION --query 'Stacks[0].Outputs' --output json > config/$PRIMARY_ENV.json

echo "Deploying the stack on ${SECONDARY_REGION} ..."
sam deploy --stack-name $STACK_NAME --region $SECONDARY_REGION --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --resolve-s3
aws cloudformation describe-stacks --stack-name $STACK_NAME --region $SECONDARY_REGION --query 'Stacks[0].Outputs' --output json > config/$SECONDARY_ENV.json

# Combine the outputs into a single JSON file
echo "Saving the outputs into  config/config.json..."
jq -n \
    --arg primary "$PRIMARY_ENV" \
    --arg secondary "$SECONDARY_ENV" \
    --slurpfile primary_data config/$PRIMARY_ENV.json \
    --slurpfile secondary_data config/$SECONDARY_ENV.json \
    '{
        primary: ($primary_data[0] | map({(.OutputKey): .OutputValue}) | add),
        secondary: ($secondary_data[0] | map({(.OutputKey): .OutputValue}) | add)
    }' > config/config.json

# Clean up temporary files
rm -rf config/$PRIMARY_ENV.json
rm -rf config/$SECONDARY_ENV.json
