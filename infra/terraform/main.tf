terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "shiptrack-tfstate-175342148773"
    key            = "shiptrack/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "shiptrack-tf-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-north-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.99.0.0/16"
}

variable "environment" {
  description = "Environment name - dev, qa or prod"
  type        = string
}

resource "aws_vpc" "practice" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "shiptrack-${var.environment}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.practice.id
}

output "vpc_cidr" {
  value = aws_vpc.practice.cidr_block
}
