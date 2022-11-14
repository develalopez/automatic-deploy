#!/bin/bash

mkdir config

echo "Creating new key pair..."

aws ec2 create-key-pair --key-name AutoDeployKP --query 'KeyMaterial' --output text > AutoDeployKP.pem
chmod 400 AutoDeployKP.pem

echo "Retrieving VPC id..."

vpcid=$(aws ec2 describe-vpcs | jq -r '.Vpcs[0].VpcId')
echo $vpcid > config/vpc.txt

echo "Retrieving VPC subnet id..."

subnetid=$(aws ec2 describe-subnets | jq -r '.Subnets[0].SubnetId')
echo $subnetid > config/subnet.txt

echo "Creating security group..."

sgid=$(aws ec2 create-security-group --group-name auto-deply-sg --description "Auto deploy SG" --vpc-id $vpcid | jq -r '.GroupId')
echo $sgid > config/sg.txt

echo "Adding inboud rule: authorize port 22 for SSH"

aws ec2 authorize-security-group-ingress --group-id $sgid --protocol tcp --port 22 --cidr 0.0.0.0/0

echo "Adding inboud rule: authorize port 80 for HTTP"

aws ec2 authorize-security-group-ingress --group-id $sgid --protocol tcp --port 80 --cidr 0.0.0.0/0