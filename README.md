## How we SSH into the ec2 after running cloudformation deploy
#
We should be able to write a bash setup script (setup.sh) that starts with the aws sam command to deploy the cloudformation, then uses a handful of aws cli commands to get the ssh keys and the ec2 private hostname, then append those to the ssh hosts config file that vscode will automatically look at when you type "ssh" into the command pallette.

The goal is for anyone with aws keys to be able to execute a one-liner that clones the repo and runs the setup script. When the script is done, they should have deployed an ec2 instance with a deep learning ami, gpu capability, a running jupyter server, an attached s3 bucket for fetching/storing jupyter notebooks. Ideally, the script would also create a live ssh connection, switch their IDE context to the remote instance and display a notebook running on the instance's jupyter server. I'd like to prototype for vscode as the IDE and extend to others later.

The cloudformation stack should auto-stop after inactivity. We can worry about reusability (rebooting the stopped instance instead of re-deploying a new one) later :)

"Creating SSH Key Pair during Cloudformation Deploy" below describes how to retrieve the new ec2's ssh key and save locally to a .pem file

We'll also need to use the aws cloudformation describe-stacks command to get the private dns hostname (ec2-blablabla.region.compute.amazonaws.com). See here for some examples, we'll need to specify the stackname in the aws sam deploy and use that, we'll also need to figure out the exact name of the key name for the ec2 instance's private dns HostName: https://stackoverflow.com/questions/41628487/getting-outputs-from-aws-cloudformation-describe-stacks

Once we have the key file path and the hostname, we can then `$echo -e "stuff below" >> foo/bar/.ssh/config` to create a host entry string that looks like...
```
Host my-new-ai-sandbox
    HostName ec2-blablabla.region.compute.amazonaws.com
    User ubuntu
    IdentityFile blablabla/test-key-pair.pem
```
...to the foo/bar/.ssh/config (or whatever) file path that vscode expects the ssh config to reside in. 

At that point, the user should be able to open the vscode command pallete, search for ssh, and see "my-new-ai-sandbox" show up. Once they click and the connection completes, they should be able to see the file system in the vscode sidebar and run the notebooks we've put there.

I think that'd be a great start! We can worry about devcontainers and fancy reusability later.
#
## Creating SSH Key Pair during Cloudformation Deploy
To create a key pair using AWS CloudFormation
Specify the AWS::EC2::KeyPair resource in your template.
```
Resources:
  NewKeyPair:
    Type: 'AWS::EC2::KeyPair'
    Properties: 
      KeyName: new-key-pair
```

Use the describe-key-pairs command as follows to get the ID of the key pair.

`aws ec2 describe-key-pairs --filters Name=key-name,Values=new-key-pair --query KeyPairs[*].KeyPairId --output text`

The following is example output.

`key-05abb699beEXAMPLE # <-- example output`

Use the get-parameter command as follows to get the parameter for your key and save the key material in a .pem file.

`aws ssm get-parameter --name /ec2/keypair/key-05abb699beEXAMPLE --with-decryption --query Parameter.Value --output text > new-key-pair.pem`

Required IAM permissions
To enable AWS CloudFormation to manage Parameter Store parameters on your behalf, the IAM role assumed by AWS CloudFormation or your user must have the following permissions:

`ssm:PutParameter` – Grants permission to create a parameter for the private key material.

`ssm:DeleteParameter` – Grants permission to delete the parameter that stored the private key material. This permission is required whether the key pair was imported or created by AWS CloudFormation.

When AWS CloudFormation deletes a key pair that was created or imported by a stack, it performs a permissions check to determine whether you have permission to delete parameters, even though AWS CloudFormation creates a parameter only when it creates a key pair, not when it imports a key pair. AWS CloudFormation tests for the required permission using a fabricated parameter name that does not match any parameter in your account. Therefore, you might see a fabricated parameter name in the AccessDeniedException error message.