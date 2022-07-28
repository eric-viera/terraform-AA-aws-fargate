# VPC
Module to provision a VPC, with a default security group (wide open), public and private subnets, a NAT, and an IGW in AWS

The VPC is a virtual private network where your resources will communicate with each other.
A Security Group is a sort of virtual firewall that blocks traffic to all ports of all resources attached to it, except on the ports that are explicitly allowed. A security group can have many resources attached to it, and a resource can be attached to many security groups.

## Input Variables
| Variable                    | Type         | Description                             |
|:--------------------------- |:------------ |:--------------------------------------- |
| vpc_cidr                    | string       | CIDR block of the VPC                   |
| environment                 | string       | A name to distinguish the VPC           |
| public_subnets_cidr         | list(string) | List of CIDR blocks for Public Subnets  |
| private_subnets_cidr        | list(string) | List of CIDR blocks for Private Subnets |

## Resources Created
- aws_vpc.main
- aws_internet_gateway.main
- aws_subnet.private[]
- aws_subnet.public[]
- aws_route_table.public
- aws_route.public
- aws_route_table_association.public
- aws_nat_gateway.main
- aws_eip.nat
- aws_route_table.private
- aws_route.private
- aws_route_table_association.private
- aws_security_group.default

## Output
| Output              | Value                             | Type         | Description                                |
|:------------------- |:--------------------------------- |:------------ |:------------------------------------------ |
| vpc_id              | aws_vpc.main.id                   | string       | Self-explanatory                           |
| public_subnets_id   | aws_subnet.public[*].id           | list(string) | List of IDs of all public subnets created  |
| private_subnets_id  | aws_subnet.private[*].id          | list(string) | List of IDs of all private subnets created |
| default_sg_id       | aws_security_group.default.id     | string       | ID of the VPC's default security group     |
| security_groups_ids | [ aws_security_group.default.id ] | list(string) | List of IDs of all Security Groups Created |

