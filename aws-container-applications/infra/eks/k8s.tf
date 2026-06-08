# Kubernetes workloads. These typed resources connect to the cluster only at
# apply time (not during plan/validate), so they avoid the "cluster must exist"
# problem that kubernetes_manifest has.

locals {
  backend_image  = "${aws_ecr_repository.backend.repository_url}:${var.image_tag}"
  frontend_image = "${aws_ecr_repository.frontend.repository_url}:${var.image_tag}"
  labels_backend = { app = "backend" }
  labels_front   = { app = "frontend" }
}

resource "kubernetes_secret" "db" {
  metadata {
    name = "db-credentials"
  }
  data = {
    SPRING_DATASOURCE_URL      = "jdbc:postgresql://${aws_db_instance.postgres.address}:5432/${var.db_name}"
    SPRING_DATASOURCE_USERNAME = var.db_username
    SPRING_DATASOURCE_PASSWORD = var.db_password
  }
  type = "Opaque"
}

resource "kubernetes_deployment" "backend" {
  metadata {
    name   = "backend"
    labels = local.labels_backend
  }
  spec {
    replicas = 2
    selector {
      match_labels = local.labels_backend
    }
    template {
      metadata {
        labels = local.labels_backend
      }
      spec {
        container {
          name  = "backend"
          image = local.backend_image

          port {
            container_port = 8080
          }

          env {
            name  = "SPRING_PROFILES_ACTIVE"
            value = "prod"
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.db.metadata[0].name
            }
          }

          liveness_probe {
            http_get {
              path = "/actuator/health/liveness"
              port = 8080
            }
            initial_delay_seconds = 40
            period_seconds        = 15
          }
          readiness_probe {
            http_get {
              path = "/actuator/health/readiness"
              port = 8080
            }
            initial_delay_seconds = 20
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "backend" {
  metadata {
    name = "backend"
  }
  spec {
    selector = local.labels_backend
    port {
      port        = 8080
      target_port = 8080
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "frontend" {
  metadata {
    name   = "frontend"
    labels = local.labels_front
  }
  spec {
    replicas = 2
    selector {
      match_labels = local.labels_front
    }
    template {
      metadata {
        labels = local.labels_front
      }
      spec {
        container {
          name  = "frontend"
          image = local.frontend_image

          port {
            container_port = 80
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "frontend" {
  metadata {
    name = "frontend"
  }
  spec {
    selector = local.labels_front
    port {
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"
  }
}

# ALB Ingress: /api and /actuator -> backend, everything else -> frontend.
resource "kubernetes_ingress_v1" "app" {
  metadata {
    name = "usermgmt"
    annotations = {
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/listen-ports"     = jsonencode([{ HTTP = 80 }])
      "alb.ingress.kubernetes.io/healthcheck-path" = "/"
    }
  }
  spec {
    ingress_class_name = "alb"

    rule {
      http {
        path {
          path      = "/api"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.backend.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
        path {
          path      = "/actuator"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.backend.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.frontend.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.lb_controller]
}
