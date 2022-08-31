# terraform-aws-AA-fargate
modules to provision a fargate cluster, and autoscaled service, also included a module for creating an cloudfront distribution with an S3 origin and an S3 Bucket in AWS

The main module is just an example that calls each module to create an infrastructure containing a VPC, an ECS Cluster, an EC2 Service, and an autoscaler for the service.

For further documentation look into each submodule's readme

You can find the latest release of this module in the terraform registry [here](https://registry.terraform.io/modules/eric-viera/AA-fargate/aws/latest).