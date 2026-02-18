# Políticas Gatekeeper (OPA)

# ConstraintTemplate: Bloquear containers privilegiados
resource "kubernetes_manifest" "gatekeeper_template_privileged" {
  count = var.engine == "gatekeeper" && var.policies.block_privileged ? 1 : 0

  manifest = {
    apiVersion = "templates.gatekeeper.sh/v1"
    kind       = "ConstraintTemplate"
    metadata = {
      name = "k8spspprivilegedcontainer"
      annotations = {
        description = "Controls the ability of any container to enable privileged mode."
      }
    }
    spec = {
      crd = {
        spec = {
          names = {
            kind = "K8sPSPPrivilegedContainer"
          }
        }
      }
      targets = [{
        target = "admission.k8s.gatekeeper.sh"
        rego = <<-EOT
          package k8spspprivilegedcontainer

          violation[{"msg": msg}] {
            c := input_containers[_]
            c.securityContext.privileged
            msg := sprintf("Privileged container is not allowed: %%v", [c.name])
          }

          input_containers[c] {
            c := input.review.object.spec.containers[_]
          }

          input_containers[c] {
            c := input.review.object.spec.initContainers[_]
          }
        EOT
      }]
    }
  }

  depends_on = [time_sleep.wait_for_policy_engine]
}

resource "kubernetes_manifest" "gatekeeper_constraint_privileged" {
  count = var.engine == "gatekeeper" && var.policies.block_privileged ? 1 : 0

  manifest = {
    apiVersion = "constraints.gatekeeper.sh/v1beta1"
    kind       = "K8sPSPPrivilegedContainer"
    metadata = {
      name = "psp-privileged-container"
    }
    spec = {
      enforcementAction = var.enforcement_mode == "enforce" ? "deny" : "dryrun"
      match = {
        kinds = [{
          apiGroups = [""]
          kinds     = ["Pod"]
        }]
      }
    }
  }

  depends_on = [kubernetes_manifest.gatekeeper_template_privileged]
}

# ConstraintTemplate: Exigir runAsNonRoot
resource "kubernetes_manifest" "gatekeeper_template_non_root" {
  count = var.engine == "gatekeeper" && var.policies.require_non_root ? 1 : 0

  manifest = {
    apiVersion = "templates.gatekeeper.sh/v1"
    kind       = "ConstraintTemplate"
    metadata = {
      name = "k8spspallowedusers"
      annotations = {
        description = "Controls the user and group IDs of the container and some volumes."
      }
    }
    spec = {
      crd = {
        spec = {
          names = {
            kind = "K8sPSPAllowedUsers"
          }
        }
      }
      targets = [{
        target = "admission.k8s.gatekeeper.sh"
        rego = <<-EOT
          package k8spspallowedusers

          violation[{"msg": msg}] {
            not input.review.object.spec.securityContext.runAsNonRoot
            msg := "Containers must run as non-root user. Set runAsNonRoot to true."
          }

          violation[{"msg": msg}] {
            c := input_containers[_]
            not c.securityContext.runAsNonRoot
            msg := sprintf("Container %%v must run as non-root user.", [c.name])
          }

          input_containers[c] {
            c := input.review.object.spec.containers[_]
          }

          input_containers[c] {
            c := input.review.object.spec.initContainers[_]
          }
        EOT
      }]
    }
  }

  depends_on = [time_sleep.wait_for_policy_engine]
}

resource "kubernetes_manifest" "gatekeeper_constraint_non_root" {
  count = var.engine == "gatekeeper" && var.policies.require_non_root ? 1 : 0

  manifest = {
    apiVersion = "constraints.gatekeeper.sh/v1beta1"
    kind       = "K8sPSPAllowedUsers"
    metadata = {
      name = "psp-allowed-users"
    }
    spec = {
      enforcementAction = var.enforcement_mode == "enforce" ? "deny" : "dryrun"
      match = {
        kinds = [{
          apiGroups = [""]
          kinds     = ["Pod"]
        }]
      }
    }
  }

  depends_on = [kubernetes_manifest.gatekeeper_template_non_root]
}

# ConstraintTemplate: Exigir resource requests e limits
resource "kubernetes_manifest" "gatekeeper_template_resources" {
  count = var.engine == "gatekeeper" && var.policies.require_resources ? 1 : 0

  manifest = {
    apiVersion = "templates.gatekeeper.sh/v1"
    kind       = "ConstraintTemplate"
    metadata = {
      name = "k8srequiredresources"
      annotations = {
        description = "Requires containers to have resource requests and limits defined."
      }
    }
    spec = {
      crd = {
        spec = {
          names = {
            kind = "K8sRequiredResources"
          }
        }
      }
      targets = [{
        target = "admission.k8s.gatekeeper.sh"
        rego = <<-EOT
          package k8srequiredresources

          violation[{"msg": msg}] {
            c := input_containers[_]
            not c.resources.requests.cpu
            msg := sprintf("Container %%v must have CPU request defined", [c.name])
          }

          violation[{"msg": msg}] {
            c := input_containers[_]
            not c.resources.requests.memory
            msg := sprintf("Container %%v must have memory request defined", [c.name])
          }

          violation[{"msg": msg}] {
            c := input_containers[_]
            not c.resources.limits.cpu
            msg := sprintf("Container %%v must have CPU limit defined", [c.name])
          }

          violation[{"msg": msg}] {
            c := input_containers[_]
            not c.resources.limits.memory
            msg := sprintf("Container %%v must have memory limit defined", [c.name])
          }

          input_containers[c] {
            c := input.review.object.spec.containers[_]
          }

          input_containers[c] {
            c := input.review.object.spec.initContainers[_]
          }
        EOT
      }]
    }
  }

  depends_on = [time_sleep.wait_for_policy_engine]
}

resource "kubernetes_manifest" "gatekeeper_constraint_resources" {
  count = var.engine == "gatekeeper" && var.policies.require_resources ? 1 : 0

  manifest = {
    apiVersion = "constraints.gatekeeper.sh/v1beta1"
    kind       = "K8sRequiredResources"
    metadata = {
      name = "required-resources"
    }
    spec = {
      enforcementAction = var.enforcement_mode == "enforce" ? "deny" : "dryrun"
      match = {
        kinds = [{
          apiGroups = [""]
          kinds     = ["Pod"]
        }]
      }
    }
  }

  depends_on = [kubernetes_manifest.gatekeeper_template_resources]
}

# ConstraintTemplate: Bloquear image tag latest
resource "kubernetes_manifest" "gatekeeper_template_latest_tag" {
  count = var.engine == "gatekeeper" && var.policies.block_latest_tag ? 1 : 0

  manifest = {
    apiVersion = "templates.gatekeeper.sh/v1"
    kind       = "ConstraintTemplate"
    metadata = {
      name = "k8sdisallowlatesttag"
      annotations = {
        description = "Requires container images to have an explicit tag different from 'latest'."
      }
    }
    spec = {
      crd = {
        spec = {
          names = {
            kind = "K8sDisallowLatestTag"
          }
        }
      }
      targets = [{
        target = "admission.k8s.gatekeeper.sh"
        rego = <<-EOT
          package k8sdisallowlatesttag

          violation[{"msg": msg}] {
            c := input_containers[_]
            endswith(c.image, ":latest")
            msg := sprintf("Container %%v uses ':latest' tag which is not allowed", [c.name])
          }

          violation[{"msg": msg}] {
            c := input_containers[_]
            not contains(c.image, ":")
            msg := sprintf("Container %%v has no tag specified (defaults to :latest)", [c.name])
          }

          input_containers[c] {
            c := input.review.object.spec.containers[_]
          }

          input_containers[c] {
            c := input.review.object.spec.initContainers[_]
          }
        EOT
      }]
    }
  }

  depends_on = [time_sleep.wait_for_policy_engine]
}

resource "kubernetes_manifest" "gatekeeper_constraint_latest_tag" {
  count = var.engine == "gatekeeper" && var.policies.block_latest_tag ? 1 : 0

  manifest = {
    apiVersion = "constraints.gatekeeper.sh/v1beta1"
    kind       = "K8sDisallowLatestTag"
    metadata = {
      name = "disallow-latest-tag"
    }
    spec = {
      enforcementAction = var.enforcement_mode == "enforce" ? "deny" : "dryrun"
      match = {
        kinds = [{
          apiGroups = [""]
          kinds     = ["Pod"]
        }]
      }
    }
  }

  depends_on = [kubernetes_manifest.gatekeeper_template_latest_tag]
}

# ConstraintTemplate: Restringir capabilities
resource "kubernetes_manifest" "gatekeeper_template_capabilities" {
  count = var.engine == "gatekeeper" && var.policies.restrict_capabilities ? 1 : 0

  manifest = {
    apiVersion = "templates.gatekeeper.sh/v1"
    kind       = "ConstraintTemplate"
    metadata = {
      name = "k8spspcapabilities"
      annotations = {
        description = "Controls Linux capabilities on containers."
      }
    }
    spec = {
      crd = {
        spec = {
          names = {
            kind = "K8sPSPCapabilities"
          }
        }
      }
      targets = [{
        target = "admission.k8s.gatekeeper.sh"
        rego = <<-EOT
          package k8spspcapabilities

          violation[{"msg": msg}] {
            c := input_containers[_]
            not has_drop_all(c)
            msg := sprintf("Container %%v must drop ALL capabilities", [c.name])
          }

          violation[{"msg": msg}] {
            c := input_containers[_]
            has_disallowed_capabilities(c)
            msg := sprintf("Container %%v can only add NET_BIND_SERVICE capability", [c.name])
          }

          has_drop_all(container) {
            container.securityContext.capabilities.drop[_] == "ALL"
          }

          has_disallowed_capabilities(container) {
            added := container.securityContext.capabilities.add[_]
            added != "NET_BIND_SERVICE"
          }

          input_containers[c] {
            c := input.review.object.spec.containers[_]
          }

          input_containers[c] {
            c := input.review.object.spec.initContainers[_]
          }
        EOT
      }]
    }
  }

  depends_on = [time_sleep.wait_for_policy_engine]
}

resource "kubernetes_manifest" "gatekeeper_constraint_capabilities" {
  count = var.engine == "gatekeeper" && var.policies.restrict_capabilities ? 1 : 0

  manifest = {
    apiVersion = "constraints.gatekeeper.sh/v1beta1"
    kind       = "K8sPSPCapabilities"
    metadata = {
      name = "psp-capabilities"
    }
    spec = {
      enforcementAction = var.enforcement_mode == "enforce" ? "deny" : "dryrun"
      match = {
        kinds = [{
          apiGroups = [""]
          kinds     = ["Pod"]
        }]
      }
    }
  }

  depends_on = [kubernetes_manifest.gatekeeper_template_capabilities]
}
