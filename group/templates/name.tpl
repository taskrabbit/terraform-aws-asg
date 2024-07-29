#cloud-config
runcmd:
  - "TOKEN=`curl -s -X PUT http://169.254.169.254/latest/api/token -H 'X-aws-ec2-metadata-token-ttl-seconds: 600'` && `which aws` ec2 create-tags --region=${region} --resources `curl -s -H 'X-aws-ec2-metadata-token: $TOKEN' http://169.254.169.254/latest/meta-data/instance-id` --tags Key=Name,Value=${name_prefix}-`curl -s -H 'X-aws-ec2-metadata-token: $TOKEN' http://169.254.169.254/latest/meta-data/instance-id | tr -d 'i-'`"
output : { all : '| tee -a /var/log/cloud-init-output.log' }
