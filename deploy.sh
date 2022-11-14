#!/bin/bash

mkdir config/instances

sgid=$(cat config/sg.txt)
subnetid=$(cat config/subnet.txt)

echo "Creating instances..."

inst1id=$(aws ec2 run-instances --image-id ami-09d3b3274b6c5d4aa --count 1 --instance-type t2.micro --key-name AutoDeployKP --security-group-ids $sgid --subnet-id $subnetid | jq -r '.Instances[0].InstanceId')
inst2id=$(aws ec2 run-instances --image-id ami-09d3b3274b6c5d4aa --count 1 --instance-type t2.micro --key-name AutoDeployKP --security-group-ids $sgid --subnet-id $subnetid | jq -r '.Instances[0].InstanceId')
inst3id=$(aws ec2 run-instances --image-id ami-09d3b3274b6c5d4aa --count 1 --instance-type t2.micro --key-name AutoDeployKP --security-group-ids $sgid --subnet-id $subnetid | jq -r '.Instances[0].InstanceId')

echo $inst1id > config/instances/inst1id.txt
echo $inst2id > config/instances/inst2id.txt
echo $inst3id > config/instances/inst3id.txt

echo "Waiting for instances to launch..."

sleep 40

echo "Retrieving instances public DNS addresses..."

inst1dns=$(aws ec2 describe-instances --filters "Name=instance-id,Values=$inst1id" | jq -r '.Reservations[0].Instances[0].PublicDnsName')
inst2dns=$(aws ec2 describe-instances --filters "Name=instance-id,Values=$inst2id" | jq -r '.Reservations[0].Instances[0].PublicDnsName')
inst3dns=$(aws ec2 describe-instances --filters "Name=instance-id,Values=$inst3id" | jq -r '.Reservations[0].Instances[0].PublicDnsName')

echo $inst1dns > config/instances/inst1dns.txt
echo $inst2dns > config/instances/inst2dns.txt
echo $inst3dns > config/instances/inst3dns.txt
dnslist=($inst1dns $inst2dns $inst3dns)

echo "Adding DNS addresses to list on known hosts for SSH..."

for dns in ${dnslist[@]}; do
    ssh-keygen -F $dns 2>/dev/null 1>/dev/null
    if [ $? -eq 0 ]; then
        echo "$dns is already known"
        continue
    fi
    ssh-keyscan -t rsa -T 10 $dns >> ~/.ssh/known_hosts
done

echo "Installing git and Docker on all instances..."

for dns in ${dnslist[@]}; do
    ssh -i AutoDeployKP.pem ec2-user@$dns 'sudo yum install git docker -y; sudo service docker start'
done

echo "Installing Java 8 JDK on all instances..."

for dns in ${dnslist[@]}; do
    ssh -i AutoDeployKP.pem ec2-user@$dns 'sudo yum install java-1.8.0-openjdk-devel -y'
done

echo "Installing maven on all instances..."

for dns in ${dnslist[@]}; do
    ssh -i AutoDeployKP.pem ec2-user@$dns 'curl https://dlcdn.apache.org/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.zip -o apache-maven-3.8.6-bin.zip && unzip apache-maven-3.8.6-bin.zip'
done

echo "Installing Docker Compose on all instances..."

for dns in ${dnslist[@]}; do
    ssh -i AutoDeployKP.pem ec2-user@$dns 'sudo curl -SL https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-linux-x86_64 -o /usr/bin/docker-compose; sudo chmod +x /usr/bin/docker-compose'
done

echo "Cloning app repo on all instances..."

for dns in ${dnslist[@]}; do
    ssh -i AutoDeployKP.pem ec2-user@$dns 'git clone https://github.com/develalopez/intro-workshop-aygo.git'
done

echo "Maven clean install on all instances..."

for dns in ${dnslist[@]}; do
    ssh -i AutoDeployKP.pem ec2-user@$dns 'export PATH=/home/ec2-user/apache-maven-3.8.6/bin:$PATH && cd ~/intro-workshop-aygo/roundrobin/; mvn clean install'
    ssh -i AutoDeployKP.pem ec2-user@$dns 'export PATH=/home/ec2-user/apache-maven-3.8.6/bin:$PATH && cd ~/intro-workshop-aygo/logservice/; mvn clean install'
done

echo "Deploying app on all instances..."

for dns in ${dnslist[@]}; do
    ssh -i AutoDeployKP.pem ec2-user@$dns 'cd ~/intro-workshop-aygo; sudo docker-compose up -d'
done

echo "App successfully deployed on:"

for dns in ${dnslist[@]}; do
    echo "http://$dns"
done