terraform {
   backend "product_app_backend" {
    bucket = "product_app_bucket"
    key    = "product_app.tfstate"
    region = "ap-south-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.2.0"
}

# used to create and manage AWS resources
provider "aws" {
  profile = "default"
  region = "ap-south-1"
}

# creates a VPC with a subnet and a security group
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name            = "my_vpc"
  cidr            = "172.31.0.0/16"
  azs             = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  private_subnets = ["172.31.32.0/20", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "ecs-app-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  container_definitions    = data.template_file.ecs_app.rendered
}

resource "aws_ecs_service" "product_app" {
  name            = "product-app"
  cluster         = aws_ecs_cluster.foo.id
  task_definition = aws_ecs_task_definition.mongo.arn
  desired_count   = 1
  iam_role        = aws_iam_role.foo.arn
  launch_type     = "EC2"

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.foo.arn
    container_name   = "mongo"
    container_port   = 8080
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  }
}

resource "aws_ecs_cluster" "product" {
  name = "product_app_cluster"

  tags = {
    Name   = "product_app_cluster"
  }
}

resource "aws_ecr_repository" "this" {
  name = "product_app"
}

output "ecr_repository_url" {
  value = aws_ecr_repository.this.repository_url
}

# locals {
#   cluster_name = "product-app-cluster"
# }

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 17.0"

#   cluster_name = "product-app-cluster"
#   subnets      = module.vpc.public_subnets

#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#   }

#   vpc_id = module.vpc.vpc_id

#   # To add more nodes to the cluster, update the desired capacity.
#   node_groups = {
#     default = {
#       instance_type = "t2.micro"
#       additional_tags = {
#         Terraform   = "true"
#         Environment = "dev"
#       }
#       desired_capacity = 2
#     }
#   }
# }