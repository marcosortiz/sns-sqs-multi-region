#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/config.sh"

echo "Deleting the stack on $PRIMARY_REGION ..."
sam delete --stack-name $STACK_NAME --region $PRIMARY_REGION --no-prompts
echo "Removing config/${PRIMARY_ENV}.json ..."
rm config/${PRIMARY_ENV}.json

echo "Deleting the stack on ${SECONDARY_REGION} ..."
sam delete --stack-name $STACK_NAME --region $SECONDARY_REGION --no-prompts
echo "Removing config/${SECONDARY_ENV}.json ..."
rm config/${SECONDARY_ENV}.json

# Clean up temporary files
echo "Removing config/config.json ..."
rm -rf config/config.json