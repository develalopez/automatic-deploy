#!/bin/bash

echo "Deleting key pair..."

aws ec2 delete-key-pair --key-name AutoDeployKP

echo "Deleting security group..."

aws ec2 delete-security-group --group-id $(cat config/sg.txt)