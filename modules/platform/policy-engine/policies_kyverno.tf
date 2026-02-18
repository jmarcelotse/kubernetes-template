# Políticas Kyverno

# Política: Bloquear containers privilegiados
resource "kubernetes_manifest" "kyverno_disallow_privileged" {
  count = var.engine == "kyverno" && var.policies.block_privileged ? 1 : 0

  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "disallow-privileged-containers"
      annotations = {
        "policies.kyverno.io/title"       = "Disallow Privileged Containers"
        "policies.kyverno.io/category"    = "Pod Security Standards (Baseline)"
        "policies.kyverno.io/severity"    = "high"
        "policies.kyverno.io/description" = "Privileged mode disables most security mechanisms and must not be allowed."
      }
    }
    spec = {
      validationFailureAction = var.enforcement_mode == "enforce" ? "Enforce" : "Audit"
      background              = true
      rules = [{
        name = "privileged-containers"
        match = {
          any = [{
            resources = {
              kinds = ["Pod"]
            }
          }]
        }
        validate = {
          message = "Privileged mode is not allowed. Set securityContext.privileged to false."
          pattern = {
            spec = {
              containers = [{
                "=(securityContext)" = {
                  "=(privileged)" = false
                }
              }]
            }
          }
        }
      }]
    }
  }

  depends_on = [time_sleep.wait_for_policy_engine]
}

# Política: Exigir runAsNonRoot
resource "kubernetes_manifest" "kyverno_require_non_root" {
  count = var.engine == "kyverno" && var.policies.require_non_root ? 1 : 0

  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "require-run-as-non-root"
      annotations = {
        "policies.kyverno.io/title"       = "Require runAsNonRoot"
        "policies.kyverno.io/category"    = "Pod Security Standards (Restricted)"
        "policies.kyverno.io/severity"    = "medium"
        "policies.kyverno.io/description" = "Containers must run as non-root user."
      }
    }
    spec = {
      validationFailureAction = var.enforcement_mode == "enforce" ? "Enforce" : "Audit"
      background              = true
      rules = [{
        name = "run-as-non-root"
        match = {
          any = [{
            resources = {
              kinds = ["Pod"]
            }
          }]
        }
        validate = {
          message = "Running as root is not allowed. Set runAsNonRoot to true."
          pattern = {
            spec = {
              "=(securityContext)" = {
                "=(runAsNonRoot)" = true
              }
              containers = [{
                "=(securityContext)" = {
                  "=(runAsNonRoot)" = true
                }
              }]
            }
          }
        }
      }]
    }
  }

  depends_on = [time_sleep.wait_for_policy_engine]
}

# Política: Exigir resource requests e limits
resource "kubernetes_manifest" "kyverno_require_resources" {
  count = var.engine == "kyverno" && var.policies.require_resources ? 1 : 0

  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "require-resources"
      annotations = {
        "policies.kyverno.io/title"       = "Require Resource Requests and Limits"
        "policies.kyverno.io/category"    = "Best Practices"
        "policies.kyverno.io/severity"    = "medium"
        "policies.kyverno.io/description" = "All containers must have CPU and memory requests and limits defined."
      }
    }
    spec = {
      validationFailureAction = var.enforcement_mode == "enforce" ? "Enforce" : "Audit"
      background              = true
      rules = [{
        name = "require-resources"
        match = {
          any = [{
            resources = {
              kinds = ["Pod"]
            }
          }]
        }
        validate = {
          message = "CPU and memory resource requests and limits are required."
          pattern = {
            spec = {
              containers = [{
                resources = {
                  requests = {
                    memory = "?*"
                    cpu    = "?*"
                  }
                  limits = {
                    memory = "?*"
                    cpu    = "?*"
                  }
                }
              }]
            }
          }
        }
      }]
    }
  }

  depends_on = [time_sleep.wait_for_policy_engine]
}

# Política: Bloquear image tag latest
resource "kubernetes_manifest" "kyverno_block_latest_tag" {
  count = var.engine == "kyverno" && var.policies.block_latest_tag ? 1 : 0

  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "disallow-latest-tag"
      annotations = {
        "policies.kyverno.io/title"       = "Disallow Latest Tag"
        "policies.kyverno.io/category"    = "Best Practices"
        "policies.kyverno.io/severity"    = "medium"
        "policies.kyverno.io/description" = "The ':latest' tag is mutable and can lead to unexpected errors. Use immutable tags instead."
      }
    }
    spec = {
      validationFailureAction = var.enforcement_mode == "enforce" ? "Enforce" : "Audit"
      background              = true
      rules = [{
        name = "require-image-tag"
        match = {
          any = [{
            resources = {
              kinds = ["Pod"]
            }
          }]
        }
        validate = {
          message = "An image tag is required and it must not be 'latest'."
          pattern = {
            spec = {
              containers = [{
                image = "!*:latest"
              }]
            }
          }
        }
      }]
    }
  }

  depends_on = [time_sleep.wait_for_policy_engine]
}

# Política: Restringir capabilities
resource "kubernetes_manifest" "kyverno_restrict_capabilities" {
  count = var.engine == "kyverno" && var.policies.restrict_capabilities ? 1 : 0

  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "restrict-capabilities"
      annotations = {
        "policies.kyverno.io/title"       = "Restrict Capabilities"
        "policies.kyverno.io/category"    = "Pod Security Standards (Restricted)"
        "policies.kyverno.io/severity"    = "medium"
        "policies.kyverno.io/description" = "Containers must drop all capabilities and only add back NET_BIND_SERVICE if needed."
      }
    }
    spec = {
      validationFailureAction = var.enforcement_mode == "enforce" ? "Enforce" : "Audit"
      background              = true
      rules = [{
        name = "restrict-capabilities"
        match = {
          any = [{
            resources = {
              kinds = ["Pod"]
            }
          }]
        }
        validate = {
          message = "Containers must drop ALL capabilities and may only add NET_BIND_SERVICE."
          pattern = {
            spec = {
              containers = [{
                securityContext = {
                  capabilities = {
                    drop = ["ALL"]
                    "=(add)" = ["NET_BIND_SERVICE"]
                  }
                }
              }]
            }
          }
        }
      }]
    }
  }

  depends_on = [time_sleep.wait_for_policy_engine]
}
