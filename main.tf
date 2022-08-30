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
  additional_execution_role_policies = [data.aws_iam_policy_document.ecs-secret-policy_doc.json]
  additional_role_policies           = []
  private_subnets                    = module.vpc.private_subnets_id
  public_subnets                     = module.vpc.public_subnets_id
  listener_port                      = 443
  listener_protocol                  = "HTTPS" #this is upper-case
  vpc_id                             = module.vpc.vpc_id
}

data "aws_iam_policy_document" "ecs-secret-policy_doc" {
  statement {
    actions = [
      "kms:Decrypt",
      "secretsmanager:GetSecretValue"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:secretsmanager:us-east-1:487799950875:secret:dockerhub-creds-LkfMU6",
      "arn:aws:kms:us-east-1:487799950875:key/8a953644-0298-4c6c-8e7f-ca06a1965718"
    ]
  }
}

module "nginx-service" {
  source                      = "./modules/task"
  ecs_task_execution_role_arn = module.ecs-cluster.task_execution_role_arn
  ecs_task_role_arn           = module.ecs-cluster.task_role_arn
  project_name                = var.project
  service_name                = "nginx"
  domain                      = module.ecs-cluster.domain_name
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
  zone_id                     = module.ecs-cluster.zone_id
  container_definitions_json = jsonencode([{
    name      = "nginx-container"
    image     = "487799950875.dkr.ecr.us-east-1.amazonaws.com/fargate-test-app:latest"
    essential = true
    portMappings = [{
      protocol      = "tcp" #this is lower-case
      containerPort = 8080
      hostPort      = 0
    }]
    logConfiguration = { #it is strongly advised to include this block
      logDriver = "awslogs",
      options = {
        awslogs-group         = "${var.project}-nginx", #aws logs group name is always "<projectname>-<servicename>"
        awslogs-region        = var.aws_region,
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

module "mario-service" {
  source                      = "./modules/task"
  ecs_task_execution_role_arn = module.ecs-cluster.task_execution_role_arn
  ecs_task_role_arn           = module.ecs-cluster.task_role_arn
  project_name                = var.project
  service_name                = "supermario"
  domain                      = module.ecs-cluster.domain_name
  container_image             = "pengbai/docker-supermario:latest"
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
  zone_id                     = module.ecs-cluster.zone_id
  container_definitions_json = jsonencode([{
    name      = "supermario-container"
    image     = "pengbai/docker-supermario:latest"
    essential = true
    portMappings = [{
      protocol      = "tcp" #this is lower-case
      containerPort = 8080
      hostPort      = 0
    }]
    logConfiguration = { #it is strongly advised to include this block
      logDriver = "awslogs",
      options = {
        awslogs-group         = "${var.project}-supermario", #aws logs group name is always "<projectname>-<servicename>"
        awslogs-region        = var.aws_region,
        awslogs-stream-prefix = "ecs"
      }
    }
    repositoryCredentials = {
      credentialsParameter = data.aws_secretsmanager_secret.dockerhub-creds.arn
    }
  }])
}

data "aws_secretsmanager_secret" "dockerhub-creds" {
  name = "dockerhub-creds"
}
