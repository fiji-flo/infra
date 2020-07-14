
locals {

  ingress_nginx_repository = "https://kubernetes-charts.storage.googleapis.com"
  ingress_class            = var.environment == "" ? "nginx" : "nginx-${var.environment}"
  ingress_name             = var.name == "" ? "nginx-ingress" : var.name

  ingress_nginx_settings_defaults = {
    "controller.ingressClass"                                                                                             = local.ingress_class
    "controller.service.targetPorts.http"                                                                                 = "http"
    "controller.service.targetPorts.https"                                                                                = "http"
    "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"                              = "nlb"
    "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled" = true
    "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-connection-draining-enabled"       = true
    "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-connection-idle-timeout"           = "60"
    "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-backend-protocol"                  = "http"
    "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-ports"                         = "443"
    "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"                          = var.certificate_arn
    "controller.autoscaling.enabled"                                                                                      = "true"
    "controller.autoscaling.minReplicas"                                                                                  = "2"
    "controller.autoscaling.maxReplicas"                                                                                  = "5"
    "controller.autoscaling.targetCPUUtilizationPercentage"                                                               = "80"
    "controller.autoscaling.targetMemoryUtilizationPercentage"                                                            = "80"
  }
  ingress_nginx_settings = merge(local.ingress_nginx_settings_defaults, var.ingress_nginx_settings)
}

resource "helm_release" "ingress_nginx" {
  count      = var.enabled ? 1 : 0
  name       = local.ingress_name
  repository = local.ingress_nginx_repository
  chart      = "nginx-ingress"
  namespace  = "kube-system"

  dynamic "set" {
    iterator = item
    for_each = local.ingress_nginx_settings

    content {
      name  = item.key
      value = item.value
    }
  }
}
