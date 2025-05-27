#!/bin/bash

# Variables
STACK_NAME="MyVPCStack"
TEMPLATE_FILE="../templates/vpc.yaml"
REGION="us-east-1"

# Create or update the CloudFormation stack
aws cloudformation deploy \
    --template-file $TEMPLATE_FILE \
    --stack-name $STACK_NAME \
    --region $REGION \
    --capabilities CAPABILITY_IAM \
    --no-fail-on-empty-changeset

echo "Deployment of the CloudFormation stack '$STACK_NAME' completed."