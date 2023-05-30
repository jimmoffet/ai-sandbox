#!/bin/bash

# this is super rough, cobbled together from SO posts, it will need a lot of tweaking

# Deploy the CloudFormation stack with AWS SAM
aws sam deploy --template-file /path/to/your/template.yaml --stack-name <your-stack-name> --s3-bucket <your-bucket-name> --capabilities CAPABILITY_IAM

# Wait for the stack to be created
aws cloudformation wait stack-create-complete --stack-name <your-stack-name>



# Get the private DNS hostname from the stack output
PRIVATE_DNS_HOSTNAME=$(aws cloudformation describe-stacks --stack-name <your-stack-name> --query 'Stacks[0].Outputs[?OutputKey==`PrivateDnsHostname`].OutputValue' --output text)

# your-ssm-parameter should be "MyKeyPair" <-- the keyname from the cloudformation config?

# Get the SSH Key from AWS SSM Parameter Store
SSH_KEY=$(aws ssm get-parameter --name <your-ssm-parameter> --with-decryption --query 'Parameter.Value' --output text)

# Write the SSH Key to a file
echo "$SSH_KEY" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

# Add the SSH host to known hosts
echo "$PRIVATE_DNS_HOSTNAME ssh-rsa $SSH_KEY" >> ~/.ssh/known_hosts