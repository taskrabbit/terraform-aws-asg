  - "`which aws` ec2 create-tags --region ${region} --resources `curl -s http://169.254.169.254/latest/meta-data/instance-id` --tags Key=${key},Value=${value}"

#cloud-config
runcmd:
  # Fetch IMDSv2 token
  - |
    TOKEN=$(curl -H "X-aws-ec2-metadata-token-ttl-seconds: 60" -X PUT "http://169.254.169.254/latest/api/token")
    echo "IMDSv2 token fetched: $TOKEN"

  # Use the token to make a metadata request
  - |
    INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s "http://169.254.169.254/latest/meta-data/instance-id")
    echo "Instance ID: $INSTANCE_ID"
    `which aws` ec2 create-tags --region ${region} --resources $INSTANCE_ID --tags Key=${key},Value=${value}
output : { all : '| tee -a /var/log/cloud-init-output.log' }
