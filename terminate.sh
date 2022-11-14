echo "Deleting instances..."

aws ec2 terminate-instances --instance-ids $(cat config/instances/inst1id.txt) $(cat config/instances/inst2id.txt) $(cat config/instances/inst3id.txt)
rm -rf config/instances