# AWS Auto Scaling Configuration

locals {
  instance_market_options = var.spot_price == "" ? { market_type = null, spot_options = { max_price = null } } : { market_type = "spot", spot_options = { max_price = var.spot_price } }
  placement               = var.placement_tenancy == "" ? { tenancy = null } : { tenancy = var.placement_tenancy }
}

## Creates cloudconfig fragments for tagging
data "aws_region" "current" {
}

data "template_file" "name" {
  template = var.instance_based_naming_enabled == "true" ? file("${path.module}/templates/name.tpl") : ""

  vars = {
    name_prefix = length(var.instance_name_prefix) > 0 ? var.instance_name_prefix : var.stack_item_label
    region      = data.aws_region.current.name
  }
}

data "template_file" "tags" {
  count = length(keys(var.instance_tags))

  template = element(keys(var.instance_tags), count.index) != "" ? file("${path.module}/templates/tag.tpl") : ""

  vars = {
    key    = element(keys(var.instance_tags), count.index)
    region = data.aws_region.current.name
    value  = var.instance_tags[element(keys(var.instance_tags), count.index)]
  }
}

data "template_cloudinit_config" "cloud_config" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = var.user_data
  }

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.name.rendered
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

  part {
    content_type = "text/cloud-config"
    content      = "#cloud-config\nruncmd:\n${join("", data.template_file.tags.*.rendered)}"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}

## Creates launch template & security group
module "lt" {
  source = "./lt"

  ### Resource labels
  stack_item_fullname        = var.stack_item_fullname
  stack_item_label           = var.stack_item_label
  lt_sg_name_prefix_override = var.lt_sg_name_prefix_override

  ### VPC parameters
  vpc_id = var.vpc_id

  ### LT parameters
  ami                         = var.ami
  associate_public_ip_address = var.associate_public_ip_address
  ebs_optimized               = var.ebs_optimized
  ebs_vol_del_on_term         = var.ebs_vol_del_on_term
  ebs_vol_device_name         = var.ebs_vol_device_name
  ebs_vol_encrypted           = var.ebs_vol_encrypted
  ebs_vol_iops                = var.ebs_vol_iops
  ebs_vol_size                = var.ebs_vol_size
  ebs_vol_snapshot_id         = var.ebs_vol_snapshot_id
  ebs_vol_type                = var.ebs_vol_type
  enable_monitoring           = var.enable_monitoring
  instance_market_options     = local.instance_market_options
  instance_profile            = var.instance_profile
  instance_type               = var.instance_type
  key_name                    = var.key_name
  placement                   = local.placement
  root_vol_encrypted          = var.root_vol_encrypted
  root_vol_del_on_term        = var.root_vol_del_on_term
  root_vol_iops               = var.root_vol_iops
  root_vol_size               = var.root_vol_size
  root_vol_type               = var.root_vol_type
  security_groups             = var.security_groups
  user_data                   = data.template_cloudinit_config.cloud_config.rendered
}

## Creates auto scaling group
module "asg" {
  source = "./asg"

  ### Resource tags
  stack_item_label         = var.stack_item_label
  stack_item_fullname      = var.stack_item_fullname
  asg_name_override        = var.asg_name_override
  propagate_name_at_launch = var.propagate_name_at_launch

  ### VPC parameters
  subnets = var.subnets

  ### LT parameters
  lt_id = module.lt.lt_id

  ### ASG parameters
  default_cooldown          = var.default_cooldown
  desired_capacity          = var.desired_capacity
  enabled_metrics           = var.enabled_metrics
  force_delete              = var.force_delete
  hc_check_type             = var.hc_check_type
  hc_grace_period           = var.hc_grace_period
  max_size                  = var.max_size
  metrics_granularity       = "1Minute"
  min_size                  = var.min_size
  placement_group           = var.placement_group
  protect_from_scale_in     = var.protect_from_scale_in
  suspended_processes       = var.suspended_processes
  termination_policies      = var.termination_policies
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  additional_asg_tags       = var.additional_asg_tags

  ### ELB parameters
  load_balancers        = var.load_balancers
  min_elb_capacity      = var.min_elb_capacity
  target_group_arns     = var.target_group_arns
  wait_for_elb_capacity = var.wait_for_elb_capacity
}
