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
