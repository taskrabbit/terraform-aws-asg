#cloud-config
runcmd:
  - TOKEN=$(curl -H "X-aws-ec2-metadata-token-ttl-seconds: 300" -X PUT "http://169.254.169.254/latest/api/token")
  - "`which aws` ec2 create-tags --region=${region} --resources `curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id` --tags Key=Name,Value=${name_prefix}-`curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id | tr -d 'i-'`"
output : { all : '| tee -a /var/log/cloud-init-output.log' }
