terraform {
  required_providers {
    mackerel = {
      source  = "mackerelio-labs/mackerel"
      version = "~> 0.0.1"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    region = "ap-northeast-1"
    key    = "terraform.tfstate"
  }
}

data "aws_caller_identity" "current" {}

resource "mackerel_service" "app" {
  name = "app"
  memo = "test service"
}

#
# monitor
#
resource "mackerel_monitor" "external" {
  name                  = "response_time"
  notification_interval = 10

  external {
    method                 = "GET"
    url                    = "https://example.com"
    service                = mackerel_service.app.name
    response_time_critical = 10000
    response_time_warning  = 5000
    response_time_duration = 3
    headers                = { Cache-Control = "no-cache" }
  }
}

resource "mackerel_monitor" "request_latency" {
  name                  = "role average"
  notification_interval = 60

  # ref: https://mackerel.io/ja/docs/entry/advanced/advanced-graph
  expression {
    expression = <<-EOF
      service(${mackerel_service.app.name}, response_time)
    EOF
    operator   = "<"
    warning    = 10000
    critical   = 13000
  }
}

#
# aws integration
#
resource "mackerel_aws_integration" "test" {
  name        = "test"
  memo        = "This aws integration is managed by Terraform."
  role_arn    = aws_iam_role.mackerel_integration.arn
  external_id = var.external_id  # refer to Mackerel console
  region      = var.region

  included_tags = "service:${mackerel_service.app.name}"

  ec2 {
    enable               = true
    retire_automatically = true
  }

  depends_on = [
    aws_iam_role_policy.mackerel_integration,
    aws_iam_role.mackerel_integration
  ]
}

resource "aws_iam_role" "mackerel_integration" {
  name               = "mackerel-aws-integration"
  assume_role_policy = data.aws_iam_policy_document.mackerel_integration_role.json
}

data "aws_iam_policy_document" "mackerel_integration_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"

      # ref: https://mackerel.io/ja/docs/entry/integrations/aws#setting_aws_iam_role
      identifiers = ["arn:aws:iam::217452466226:root"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id] # refer to Mackerel console
    }
  }
}

resource "aws_iam_role_policy" "mackerel_integration" {
  name   = "mackerel-integration-policy"
  role   = aws_iam_role.mackerel_integration.id
  policy = data.aws_iam_policy_document.mackerel_integration.json
}

# ref: https://mackerel.io/ja/docs/entry/integrations/aws
data "aws_iam_policy_document" "mackerel_integration" {
  statement {
    actions = [
      "apigateway:Get*",
      "application-autoscaling:DescribeScalableTargets",
      "batch:Describe*",
      "batch:ListJobs",
      "budgets:ViewBudget",
      "cloudfront:Get*",
      "cloudfront:List*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
      "codebuild:BatchGetProjects",
      "codebuild:ListProjects",
      "connect:ListInstances",
      "dynamodb:Describe*",
      "dynamodb:List*",
      "ds:DescribeDirectories",
      "ec2:DescribeInstances",
      "ecs:DescribeClusters",
      "ecs:List*",
      "elasticache:Describe*",
      "elasticache:ListTagsForResource",
      "elasticfilesystem:Describe*",
      "elasticloadbalancing:Describe*",
      "es:DescribeElasticsearchDomain",
      "es:List*",
      "firehose:DescribeDeliveryStream",
      "firehose:List*",
      "kinesis:Describe*",
      "kinesis:List*",
      "lambda:GetFunctionConfiguration",
      "lambda:List*",
      "rds:Describe*",
      "rds:ListTagsForResource",
      "redshift:Describe*",
      "route53:List*",
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
      "s3:GetBucketLogging",
      "s3:GetBucketTagging",
      "s3:GetEncryptionConfiguration",
      "s3:GetMetricsConfiguration",
      "ses:DescribeActiveReceiptRuleSet",
      "ses:GetSendQuota",
      "ses:ListIdentities",
      "sqs:GetQueueAttributes",
      "sqs:List*",
      "states:DescribeStateMachine",
      "states:List*",
      "waf-regional:Get*",
      "waf-regional:List*",
      "waf:Get*",
      "waf:List*",
      "wafv2:GetWebACL",
      "wafv2:List*"
    ]
    resources = ["*"]
  }
}
