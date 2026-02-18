terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

# Namespace para ingress controller
resource "kubernetes_namespace" "ingress" {
  metadata {
    name = var.namespace_ingress
    labels = {
      name = var.namespace_ingress
    }
  }
}

# Namespace para cert-manager
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = var.namespace_cert_manager
    labels = {
      name = var.namespace_cert_manager
    }
  }
}

# Namespace para external-dns
resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = var.namespace_external_dns
    labels = {
      name = var.namespace_external_dns
    }
  }
}
