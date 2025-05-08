# AWS Launch Template
locals {
  associate_public_ip_address = var.associate_public_ip_address == "" ? null : tobool(var.associate_public_ip_address)
  enable_monitoring           = var.enable_monitoring == "" ? null : tobool(var.enable_monitoring)
  ebs_vol_encrypted           = var.ebs_vol_encrypted == "" ? null : tobool(var.ebs_vol_encrypted)
}

## Creates security group
resource "aws_security_group" "sg_asg" {
  description = "${var.stack_item_fullname} security group"
  name_prefix = length(var.lt_sg_name_prefix_override) > 0 ? format("%s-", var.lt_sg_name_prefix_override) : format("%s-asg-", var.stack_item_label)
  vpc_id      = var.vpc_id

  tags = {
    application = var.stack_item_fullname
    managed_by  = "terraform"
    Name        = length(var.lt_sg_name_prefix_override) > 0 ? var.lt_sg_name_prefix_override : format("%s-asg", var.stack_item_label)
  }

  lifecycle {
    create_before_destroy = true
  }
}

## Creates launch template
resource "aws_launch_template" "lt" {
  count = length(var.ebs_vol_device_name) > 0 ? 0 : 1

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      delete_on_termination = var.root_vol_del_on_term
      encrypted             = var.root_vol_encrypted
      iops                  = var.root_vol_type == "io1" ? var.root_vol_iops : "0"
      volume_size           = length(var.root_vol_size) > 0 ? var.root_vol_size : "8"
      volume_type           = var.root_vol_type
    }
  }

  ebs_optimized = var.ebs_optimized

  iam_instance_profile {
    name = var.instance_profile
  }

  image_id = var.ami

  dynamic "instance_market_options" {
    for_each = length(var.instance_market_options) > 0 ? [var.instance_market_options] : []
    content {
      market_type = instance_market_options.value.market_type

      dynamic "spot_options" {
        for_each = try([instance_market_options.value.spot_options], [])
        content {
          block_duration_minutes         = try(spot_options.value.block_duration_minutes, null)
          instance_interruption_behavior = try(spot_options.value.instance_interruption_behavior, null)
          max_price                      = try(spot_options.value.max_price, null)
          spot_instance_type             = try(spot_options.value.spot_instance_type, null)
          valid_until                    = try(spot_options.value.valid_until, null)
        }
      }
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  instance_type = var.instance_type
  key_name      = var.key_name

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      instance_market_options,
      placement
    ]
  }

  monitoring {
    enabled = local.enable_monitoring
  }

  name_prefix = "${var.stack_item_label}-"

  network_interfaces {
    associate_public_ip_address = local.associate_public_ip_address
    security_groups = distinct(
      concat([aws_security_group.sg_asg.id], compact(var.security_groups)),
    )
  }

  dynamic "placement" {
    for_each = length(var.placement) > 0 ? [var.placement] : []
    content {
      affinity                = try(placement.value.affinity, null)
      availability_zone       = try(placement.value.availability_zone, null)
      group_name              = try(placement.value.group_name, null)
      host_id                 = try(placement.value.host_id, null)
      host_resource_group_arn = try(placement.value.host_resource_group_arn, null)
      spread_domain           = try(placement.value.spread_domain, null)
      tenancy                 = try(placement.value.tenancy, null)
      partition_number        = try(placement.value.partition_number, null)
    }
  }

  user_data = var.user_data
}

resource "aws_launch_template" "lt_ebs" {
  count = length(var.ebs_vol_device_name) > 0 ? 1 : 0

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      delete_on_termination = var.root_vol_del_on_term
      encrypted             = var.root_vol_encrypted
      iops                  = var.root_vol_type == "io1" ? var.root_vol_iops : "0"
      volume_size           = length(var.root_vol_size) > 0 ? var.root_vol_size : "8"
      volume_type           = var.root_vol_type
    }
  }

  block_device_mappings {
    device_name = var.ebs_vol_device_name

    ebs {
      delete_on_termination = var.ebs_vol_del_on_term
      encrypted             = length(var.ebs_vol_snapshot_id) > 0 ? null : local.ebs_vol_encrypted
      iops                  = var.ebs_vol_type == "io1" ? var.ebs_vol_iops : "0"
      snapshot_id           = var.ebs_vol_snapshot_id
      volume_size           = length(var.ebs_vol_snapshot_id) > 0 ? "0" : var.ebs_vol_size
      volume_type           = var.ebs_vol_type
    }
  }

  ebs_optimized = var.ebs_optimized

  iam_instance_profile {
    name = var.instance_profile
  }

  image_id = var.ami

  dynamic "instance_market_options" {
    for_each = length(var.instance_market_options) > 0 ? [var.instance_market_options] : []
    content {
      market_type = instance_market_options.value.market_type

      dynamic "spot_options" {
        for_each = try([instance_market_options.value.spot_options], [])
        content {
          block_duration_minutes         = try(spot_options.value.block_duration_minutes, null)
          instance_interruption_behavior = try(spot_options.value.instance_interruption_behavior, null)
          max_price                      = try(spot_options.value.max_price, null)
          spot_instance_type             = try(spot_options.value.spot_instance_type, null)
          valid_until                    = try(spot_options.value.valid_until, null)
        }
      }
    }
  }

  instance_type = var.instance_type
  key_name      = var.key_name

  lifecycle {
    create_before_destroy = true
  }

  monitoring {
    enabled = local.enable_monitoring
  }

  name_prefix = "${var.stack_item_label}-"

  network_interfaces {
    associate_public_ip_address = local.associate_public_ip_address
    security_groups = distinct(
      concat([aws_security_group.sg_asg.id], compact(var.security_groups)),
    )
  }

  dynamic "placement" {
    for_each = length(var.placement) > 0 ? [var.placement] : []
    content {
      affinity                = try(placement.value.affinity, null)
      availability_zone       = try(placement.value.availability_zone, null)
      group_name              = try(placement.value.group_name, null)
      host_id                 = try(placement.value.host_id, null)
      host_resource_group_arn = try(placement.value.host_resource_group_arn, null)
      spread_domain           = try(placement.value.spread_domain, null)
      tenancy                 = try(placement.value.tenancy, null)
      partition_number        = try(placement.value.partition_number, null)
    }
  }

  user_data = var.user_data
}
