# AWS region
region = "us-east-1"

# Identifiers / tags
stack_item_fullname = "example-asg-prod"
stack_item_label    = "example-asg"

# VPC & networking
vpc_id  = "vpc-0a1b2c3d4e5f6g7h8"
subnets = "subnet-11111111,subnet-22222222,subnet-33333333"

# Launch template (LT) parameters
ami                         = "ami-0c55b159cbfafe1f0"
associate_public_ip_address = true
enable_monitoring           = true
instance_type               = "t3.micro"
key_name                    = "my-ssh-key"
security_groups             = "sg-0123456789abcdef0"
spot_price                  = "0.015" # optional; leave empty if on-demand

# ASG parameters
default_cooldown          = 300
desired_capacity          = 2
enabled_metrics           = "GroupDesiredCapacity,GroupInServiceInstances"
force_delete              = false
hc_grace_period           = 300
max_size                  = 4
min_size                  = 1
protect_from_scale_in     = false
suspended_processes       = ""
termination_policies      = "Default"
wait_for_capacity_timeout = "10m"
