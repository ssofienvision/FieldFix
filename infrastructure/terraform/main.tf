terraform {
  required_version = ">= 1.5.0"
  required_providers {
    fly = {
      source  = "fly-apps/fly"
      version = "~> 0.0.26"
    }
    redpanda = {
      source  = "redpanda/redpanda"
      version = "~> 0.4"
    }
  }
}

provider "fly" {}

variable "env" {
  type    = string
  default = "staging"
}

locals {
  services = [
    "identity-access",
    "customer-property",
    "assets-warranty",
    "work-management",
    "technicians-dispatch",
    "inventory-parts",
    "billing-payments",
    "communications-audit"
  ]
}

module "services" {
  for_each  = toset(local.services)
  source    = "./modules/fly_service"
  app_name  = "${each.key}-${var.env}"
  image     = "ghcr.io/ssofienvision/${each.key}:latest"
  env_map   = {
    ENV = var.env
  }
  min_machines = var.env == "prod" ? 2 : 1
}

module "topics" {
  source = "./modules/redpanda_topics"
  topics = [
    "job.created",
    "job.status_changed",
    "parts.reserved",
    "parts.allocated",
    "invoice.generated",
    "payment.succeeded"
  ]
}
