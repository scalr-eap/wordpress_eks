terraform {
  backend "remote" {
    hostname = "my.scalr.com"
    organization = "org-sfgari365m7sck0"
    workspaces {
      name = "eks-wordpress"
    }
  }
}

provider "aws" {
    region     = var.region
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

resource "random_string" "random" {
  length = 6
  special = false
  upper = false
  number = false
}

provider "kubernetes" {
  host                   = "${data.aws_eks_cluster.this.endpoint}"
  cluster_ca_certificate = "${base64decode(data.aws_eks_cluster.this.certificate_authority.0.data)}"
  token                  = "${data.aws_eks_cluster_auth.this.token}"
  load_config_file       = false
}

resource "kubernetes_secret" "mysql" {
  metadata {
    name = "mysql-pass-${random_string.random.result}"
  }

  data = {
    password = var.mysql_password
  }
}

resource "kubernetes_pod" "wordpress" {
  metadata {
    name = "${var.service_name}-pod-${random_string.random.result}"
    labels = {
      App = "${var.service_name}-pod-${random_string.random.result}"
    }
  }
  spec {
    container {
      image = "tutum/wordpress"
      name  = "${var.service_name}-ct-${random_string.random.result}"
      port {
        container_port = 80
      }
      env {
        name  = "WORDPRESS_DB_HOST"
        value = aws_db_instance.default.endpoint
      }
      env {
        name  = "WORDPRESS_DB_PASSWORD"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.mysql.metadata[0].name
            key  = "password"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "wordpress_svc" {
  metadata {
    name = "${var.service_name}-svc-${random_string.random.result}"
  }
  spec {
    selector = {
      App = "${kubernetes_pod.wordpress.metadata.0.labels.App}"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

output "lb_ip" {
  value = "${kubernetes_service.wordpress_svc.load_balancer_ingress.0.ip}"
}

output "lb_hostname" {
  value = "${kubernetes_service.wordpress_svc.load_balancer_ingress.0.hostname}"
}
