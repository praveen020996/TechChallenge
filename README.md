# TechChallenge

## Overview

This repo contains terraform scripts and kubernetes manifests to deploy a simple Go app on AWS EKS cluster.

## High level Architecture

![High level architecture](https://user-images.githubusercontent.com/42564839/93075226-20e1ea00-f6a3-11ea-8c2a-b6da63d12df7.png)

The terraform creates the following resources:

- VPC
- 2 Public Subnets and 4 Private Subnets across 2 Availability zones
- 1 internet gateway, 2 NAT gateways and 3 route tables
- EKS cluster with 2 t2.micro worker nodes in the first 2 private subnets
- RDS in the last 2 private subnets
- ECR
- SecretsManager secret to store DB credentials
- 1 EC2 instance in a public subnet that builds the app, pushes the image to ECR, runs the kubectl command to create deployment and service. All the commands are fed through EC2 User data

How to run:

- Install terraform - version 0.13.0 from this link: https://releases.hashicorp.com/terraform/0.13.0/
- Add terraform to PATH
- Clone this repo and go to 'terraform-setup' directory
```
git clone https://github.com/praveen020996/TechChallenge.git
cd TechChallenge/terraform-setup
```
- Run terraform commands
```
terraform init
terraform apply
```
- The script asks for following inputs

1. aws_access_key_id - AWS Access Key
2. aws_secret_access_key - AWS Secret Access Key
3. aws_region - The region in which you want to deploy the resources. ex: us-east-1
4. db_user_name - RDS DB User Name
5. db_password - RDS DB password

  **Note:** The access key and secret key must have permissions to work with services listed in high level architecture.
 
- It takes around 15-20 minutes for all the resources to get created and EC2 user data to run. 
- After all the resources are created, go to Load Balancers section in AWS console and wait for an ELB to be created. 
- The ELB is created as a service to expose pods in EKS cluster. This might take 5 more minutes.
- After the load balancer is created, wait for the state of the instances to be 'InService'.
- When the status becomes 'InService', copy the ELB DNS and paste it in the browser.

![elbinservice](https://user-images.githubusercontent.com/42564839/93084693-1a0ea380-f6b2-11ea-9eaf-46522b9c5b09.png)

## How to delete the resources

- Since ELB is not managed by terraform, it needs to be deleted manually.
- After ELB is deleted, run the following command in TechChallenge/terraform-setup folder.

```
terraform destroy
```
