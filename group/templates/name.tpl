#cloud-config
runcmd:
  - TOKEN=$(curl -H "X-aws-ec2-metadata-token-ttl-seconds: 300" -X PUT "http://169.254.169.254/latest/api/token")
  - INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s "http://169.254.169.254/latest/meta-data/instance-id")
  - "`which aws` ec2 create-tags --region=${region} --resources $INSTANCE_ID --tags Key=Name,Value=${name_prefix}-`echo $INSTANCE_ID` | tr -d 'i-'`"
output : { all : '| tee -a /var/log/cloud-init-output.log' }
