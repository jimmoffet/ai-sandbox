#!/bin/bash

# this is super rough, cobbled together from multiple SO posts, it will need tweaking

# I think this is arbitrary?
STACK_NAME="my-ai-sandbox"

# for cloudformation deploy stuff, not for serving the actual sandbox itself
BUCKET_NAME="my-ai-sandbox-deploy-bucket"

# Deploy the CloudFormation stack with AWS SAM, we'll need to work with John Jediny once we know what IAM perms this deployment will require
aws sam deploy --template-file /path/to/your/template.yaml --stack-name $STACK_NAME --s3-bucket $BUCKET_NAME --capabilities CAPABILITY_IAM

# Wait for the stack to be created. Is this command legit? Apparently: https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-create-complete.html
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME

# Get the private DNS hostname from the stack output
PRIVATE_DNS_HOSTNAME=$(aws cloudformation describe-stacks --stack-name <your-stack-name> --query 'Stacks[0].Outputs[?OutputKey==`PrivateDnsHostname`].OutputValue' --output text)

LOCAL_KEY_PATH="/my/path/to/new-key-pair.pem"

# Get the SSH Key from AWS SSM Parameter Store
# your-key-name should be "MyKeyPair", or whatever is specified after KeyName in the cloudformation config?
SSH_KEY=$(aws ssm get-parameter --name /ec2/keypair/<your-key-name> --with-decryption --query Parameter.Value --output text > $LOCAL_KEY_PATH)

chmod 600 /my/path/to/new-key-pair.pem

# Write the SSH Key to a file
HOST_ENTRY="Host my-new-ai-sandbox\n    HostName $PRIVATE_DNS_HOSTNAME\n    User ubuntu\n    IdentityFile $LOCAL_KEY_PATH"
# should look like the below after vars are substituted in
# Host my-new-ai-sandbox
#     HostName ec2-blablabla.region.compute.amazonaws.com
#     User ubuntu
#     IdentityFile blablabla/test-key-pair.pem


# Add the SSH host to known hosts file for vscode, need to confirm this is the right path, might need to put in more than one place?
echo "$HOST_ENTRY" >> ~/.ssh/known_hosts