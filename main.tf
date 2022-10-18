provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      "project" = var.project,
    }
  }
}

module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = "10.0.0.0/16"
  environment          = var.project
  private_subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets_cidr  = ["10.0.3.0/24", "10.0.4.0/24"]
}

module "ecs-cluster" {
  source                             = "./modules/cluster"
  project_name                       = var.project
  environment                        = var.environment
  additional_execution_role_policies = []
  additional_role_policies           = []
  private_subnets                    = module.vpc.private_subnets_id
  public_subnets                     = module.vpc.public_subnets_id
  listener_port                      = 443
  listener_protocol                  = "HTTPS" #this is upper-case
  domain                             = var.domain_name
  vpc_id                             = module.vpc.vpc_id
}

module "nginx-service" {
  source                      = "./modules/task"
  ecs_task_execution_role_arn = module.ecs-cluster.task_execution_role_arn
  ecs_task_role_arn           = module.ecs-cluster.task_role_arn
  project_name                = var.project
  service_name                = "nginx"
  domain                      = var.domain_name
  container_image             = "487799950875.dkr.ecr.us-east-1.amazonaws.com/fargate-test-app:latest"
  container_port              = 8080
  cluster                     = module.ecs-cluster.cluster_id
  cluster_name                = module.ecs-cluster.cluster_name
  private_subnets             = module.vpc.private_subnets_id
  public_subnets              = module.vpc.public_subnets_id
  vpc_id                      = module.vpc.vpc_id
  listener_arn                = module.ecs-cluster.listener_arn
  lb_dns_name                 = module.ecs-cluster.lb_dns_name
  target_group_protocol       = "HTTP" #this is upper-case
  launch_type                 = "EC2"
  cpu                         = 256
  memory                      = 512
  alarm_action_arns           = [ module.ecs-cluster.sns_topic_arn ]
  ok_action_arns              = [ module.ecs-cluster.sns_topic_arn ]
}
