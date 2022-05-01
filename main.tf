provider "kubernetes" {
  config_path = var.kube_config_path
}

provider "helm" {
  kubernetes {
    config_path = var.kube_config_path
  }
}
resource "kubernetes_namespace" "tfs" {
  metadata {
    name = "tfs"
  }
}

resource "kubernetes_namespace" "consul" {
  metadata {
    name = "consul"
  }
}
resource "helm_release" "consul" {
  name       = "consul"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"
  version    = "0.39.0"
  namespace  = "consul"

  set {
    name  = "server.replicas"
    value = 1
  }
  set {
    name  = "connectInject.enabled"
    value = true
  }
  set {
    name  = "connectInject.default"
    value = true
  }
  set {
    name  = "controller.enabled"
    value = true
  }
  set {
    name  = "prometheus.enabled"
    value = true
  }
  set {
    name  = "ui.enabled"
    value = true
  }
}
resource "helm_release" "backend" {
  depends_on = [
    helm_release.consul
  ]

  name       = "backend"
  chart      = "./test_app/chart"
  namespace  = "tfs"

  set {
    name  = "upstreamExists"
    value = true
  }
  set {
    name  = "upstreamValue"
    value = "backend2:8081"
  }
}

resource "helm_release" "backend2" {
  depends_on = [
    helm_release.consul
  ]

  name       = "backend2"
  chart      = "./test_app/chart"
  namespace  = "tfs"

  set {
    name  = "nameOverride"
    value = "backend2"
  }

  set {
    name  = "service.externalPort"
    value = 8081
  }
}

resource "helm_release" "denyAllACL" {
  depends_on = [
    helm_release.consul
  ]

  name       = "deny-all"
  chart      = "./consul_acl/chart"
  namespace  = "tfs"

  set {
    name  = "nameOverride"
    value = "deny-all"
  }
  set {
    name  = "destinationName"
    value = "*"
  }
  set {
    name  = "sourceName"
    value = "*"
  }
  set {
    name  = "action"
    value = "deny"
  }
}

resource "helm_release" "backendToBackend2" {
  depends_on = [
    helm_release.consul
  ]

  name       = "backend-to-backend2"
  chart      = "./consul_acl/chart"
  namespace  = "tfs"

  set {
    name  = "nameOverride"
    value = "backend-to-backend2"
  }
  set {
    name  = "destinationName"
    value = "backend2"
  }
  set {
    name  = "sourceName"
    value = "backend"
  }
  set {
    name  = "action"
    value = "allow"
  }
}

# resource "kubernetes_deployment" "webapp" {
#   depends_on = [
#     helm_release.consul
#   ]
#   metadata {
#     name      = "webapp"
#     namespace = "tfs"
#     labels = {
#       app = "webapp"
#     }
#   }
#   spec {
#     replicas = var.webapp_replicas
#     selector {
#       match_labels = {
#         app = "webapp"
#       }
#     }
#     template {
#       metadata {
#         annotations = {
#           "consul.hashicorp.com/connect-inject" = "true"
#         }
#         labels = {
#           app = "webapp"
#         }
#       }
#       spec {
#         container {
#           image             = "golang-docker-example"
#           name              = "webapp"
#           image_pull_policy = "Never" # this is set so that kuberenetes wont try to download the image but use the localy built one
#           liveness_probe {
#             http_get {
#               path = "/"
#               port = var.webapp_port
#             }
#             initial_delay_seconds = 15
#             period_seconds        = 15
#           }
#           port {
#             container_port = var.webapp_port
#             name           = "http"
#           }

#           readiness_probe {
#             http_get {
#               path = "/"
#               port = var.webapp_port
#             }
#             initial_delay_seconds = 3
#             period_seconds        = 3
#           }
#         }
#       }
#     }
#   }
# }
# resource "kubernetes_service" "webapp" {
#   metadata {
#     name      = "webapp"
#     namespace = "tfs"
#     labels = {
#       app = "webapp_ingress"
#     }
#   }
#   spec {
#     selector = {
#       app = "webapp"
#     }
#     port {
#       port        = var.webapp_port
#       target_port = var.webapp_port
#       protocol    = "TCP"
#     }
#     type = "ClusterIP"
#   }
# }
# resource "kubernetes_deployment" "gateway" {
#   depends_on = [
#     helm_release.consul
#   ]
#   metadata {
#     name      = "gateway"
#     namespace = "tfs"
#     labels = {
#       app = "gateway"
#     }
#   }
#   spec {
#     replicas = var.gateway_replicas
#     selector {
#       match_labels = {
#         app = "gateway"
#       }
#     }
#     template {
#       metadata {
#         annotations = {
#           "consul.hashicorp.com/connect-inject"            = "true"
#           "consul.hashicorp.com/connect-service-upstreams" = "webapp:8080"
#         }
#         labels = {
#           app = "gateway"
#         }
#       }
#       spec {
#         container {
#           image             = "gateway"
#           name              = "gateway"
#           image_pull_policy = "Never" # this is set so that kuberenetes wont try to download the image but use the localy built one

#           port {
#             container_port = var.gateway_port
#             name           = "http"
#           }
#           liveness_probe {
#             http_get {
#               path = "/health"
#               port = var.gateway_port
#             }
#             initial_delay_seconds = 15
#             period_seconds        = 15
#           }

#           readiness_probe {
#             http_get {
#               path = "/health"
#               port = var.gateway_port
#             }
#             initial_delay_seconds = 3
#             period_seconds        = 3
#           }
#         }
#       }
#     }
#   }
# }
# resource "kubernetes_service" "gateway" {
#   metadata {
#     name      = "gateway"
#     namespace = "tfs"
#     labels = {
#       app = "gateway_ingress"
#     }
#   }
#   spec {
#     selector = {
#       app = "gateway"
#     }
#     port {
#       port        = var.gateway_port
#       target_port = var.gateway_port
#       protocol    = "TCP"
#     }
#     type = "NodePort"
#   }
# }
# resource "kubernetes_ingress_v1" "main_ingress" {
#   metadata {
#     name      = "main-ingress"
#     namespace = "tfs"
#     annotations = {
#       "kubernetes.io/ingress.class" = "nginx"
#     }
#   }

#   spec {
#     rule {
#       http {
#         path {
#           path      = "/"
#           path_type = "Prefix"
#           backend {
#             service {
#               name = kubernetes_service.gateway.metadata.0.name
#               port {
#                 number = var.gateway_port
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }

