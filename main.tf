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

module "fargate-cluster" {
  source                             = "./modules/cluster"
  project_name                       = var.project
  additional_execution_role_policies = [data.aws_iam_policy_document.ecs-secret-policy_doc.json]
  additional_role_policies           = []
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

module "mario-service" {
  source                      = "./modules/task"
  ecs_task_execution_role_arn = module.fargate-cluster.task_execution_role_arn
  ecs_task_role_arn           = module.fargate-cluster.task_role_arn
  project_name                = var.project
  container_image             = "pengbai/docker-supermario:latest"
  container_port              = 8080
  cluster                     = module.fargate-cluster.cluster_id
  private_subnets             = module.vpc.private_subnets_id
  public_subnets              = module.vpc.public_subnets_id
  vpc_id                      = module.vpc.vpc_id
  container_definitions_json = jsonencode([{
    name      = "${var.project}-container"
    image     = "pengbai/docker-supermario:latest"
    essential = true
    portMappings = [{
      protocol      = "tcp"
      containerPort = 8080
      hostPort      = 8080
    }]
    repositoryCredentials = {
      credentialsParameter = data.aws_secretsmanager_secret.dockerhub-creds.arn
    }
  }])
}

data "aws_secretsmanager_secret" "dockerhub-creds" {
  name = "dockerhub-creds"
}

module "autoscaling" {
  source       = "./modules/autoscaling"
  cluster_name = module.fargate-cluster.cluster_name
  service_name = module.mario-service.service_name
}