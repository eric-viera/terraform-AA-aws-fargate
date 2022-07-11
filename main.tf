provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key

}

module "fargate-cluster" {
  source       = "./modules/cluster"
  project_name = var.project
}