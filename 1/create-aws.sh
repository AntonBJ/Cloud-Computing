#!/bin/bash
USER_NAME="user"
KEY_NAME="id_rsa"
GROUP_NAME="sec_group"
GROUP_DESCRIPTION="text"
# Generate public and private key pair
ssh-keygen -b 2048 -t rsa -f $KEY_NAME -q -N "" -C $USER_NAME
# Upload public key to AWS
KEY_ID=$(aws ec2 import-key-pair \
    --key-name $KEY_NAME \
    --public-key-material fileb://$KEY_NAME.pub \
    --query 'KeyPairId' \
    --output text)
# If no default VPC exists, create one
aws ec2 create-default-vpc
# Create new security group for the default vpc
GROUP_ID=$(aws ec2 create-security-group \
    --group-name $GROUP_NAME \
    --description $GROUP_DESCRIPTION \
    --query 'GroupId' \
    --output text)
#Get current public IP adress
IP=$(curl https://checkip.amazonaws.com)
# Add ICMP to security group rules
aws ec2 authorize-security-group-ingress \
    --group-id $GROUP_ID \
    --protocol icmp \
    --port 1 \
    --cidr $IP/32
# Add SSH to security group rules
aws ec2 authorize-security-group-ingress \
    --group-id $GROUP_ID \
    --protocol tcp \
    --port 22 \
    --cidr $IP/32
# Retrieve AMI for the newest Ubuntu Server 18.04 image
AMI=$(aws ssm get-parameters \
    --names /aws/service/canonical/ubuntu/server/18.04/stable/current/amd64/hvm/ebs-gp2/ami-id \
    --query 'Parameters[0].[Value]' \
    --output text)
# Create a new instance and set volume size to 30 GB
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI \
    --count 1 \
    --instance-type t2.micro \
    --key-name $KEY_NAME \
    --security-group-ids $GROUP_ID \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":30,\"DeleteOnTermination\":false}}]" \
    --query 'Instances[0].[InstanceId]' \
    --output text)
# The following commands are only usable for our particular AWS instance
# Upload bench.sh to AWS instance via SCP
# scp -i $KEY_NAME bench.sh ubuntu@ec2-18-185-137-18.eu-central-1.compute.amazonaws.com:bench.sh
# Connect to the created AWS instance via SSH
# ssh -i $KEY_NAME ubuntu@ec2-18-185-137-18.eu-central-1.compute.amazonaws.com
# Execute the bench.sh every 30 minutes via cron
# echo "0,30 * * * * ./bench.sh >> aws_results.csv" | crontab -
