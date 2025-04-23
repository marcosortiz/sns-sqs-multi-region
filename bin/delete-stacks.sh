#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/config.sh"

echo "Deleting the stack on $PRIMARY_REGION ..."
sam delete --stack-name $STACK_NAME --region $PRIMARY_REGION --no-prompts
sam delete --stack-name $STACK_NAME-dr-subscriptions --region $PRIMARY_REGION --no-prompts
sam delete --stack-name $STACK_NAME-dashboard --region $PRIMARY_REGION --no-prompts

echo "Deleting the stack on ${SECONDARY_REGION} ..."
sam delete --stack-name $STACK_NAME --region $SECONDARY_REGION --no-prompts
sam delete --stack-name $STACK_NAME-dr-subscriptions --region $SECONDARY_REGION --no-prompts

# Clean up temporary files
echo "Removing config/config.json ..."
rm -rf config/config.json