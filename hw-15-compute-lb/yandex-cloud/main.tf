terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.115.0"
    }
  }
}

provider "yandex" {
  cloud_id           = var.cloud_id
  folder_id          = var.folder_id
  storage_access_key = var.storage_access_key
  storage_secret_key = var.storage_secret_key
}

locals {
  bucket_name = "oleg-sharov-hw15-bucket-2026"
}

# 1. Бакет и картинка
resource "yandex_storage_bucket" "hw15_bucket" {
  bucket = local.bucket_name
  acl    = "public-read"
}

resource "yandex_storage_object" "hw15_image" {
  bucket = yandex_storage_bucket.hw15_bucket.bucket
  key    = "image.jpg"
  source = "image.jpg"
  acl    = "public-read"
}

output "image_public_url" {
  value       = "https://storage.yandexcloud.net/${yandex_storage_bucket.hw15_bucket.bucket}/image.jpg"
  description = "Публичная ссылка на загруженную картинку"
}

# 2. Сеть и подсеть
resource "yandex_vpc_network" "hw15_network" {
  name = "hw15-network"
}

resource "yandex_vpc_subnet" "hw15_subnet" {
  name           = "hw15-public-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.hw15_network.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

# 3. Поиск существующего сервисного аккаунта
data "yandex_iam_service_account" "existing_sa" {
  name = "terraform-sa"
}

# 4. Группа инстансов (Instance Group) — БЕЗ блока load_balancer
resource "yandex_compute_instance_group" "hw15_ig" {
  name               = "hw15-lamp-group"
  folder_id          = var.folder_id
  service_account_id = data.yandex_iam_service_account.existing_sa.id

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  instance_template {
    platform_id = "standard-v1"
    
    resources {
      cores  = 2
      memory = 2
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = "fd827b91d99psvq5fjit"
        size     = 5
      }
    }

    network_interface {
      network_id = yandex_vpc_network.hw15_network.id
      subnet_ids = [yandex_vpc_subnet.hw15_subnet.id]
      nat        = true
    }

    metadata = {
      user-data = <<-EOF
#cloud-config
package_update: true
packages:
  - apache2
runcmd:
  - systemctl enable apache2
  - systemctl start apache2
  - echo '<html><body><h1>LAMP Server is running!</h1><img src="https://storage.yandexcloud.net/${yandex_storage_bucket.hw15_bucket.bucket}/image.jpg" alt="Test Image" width="500"></body></html>' > /var/www/html/index.html
EOF
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }
}

# 5. Целевая группа — динамически получает IP всех ВМ из Instance Group
resource "yandex_lb_target_group" "hw15_target_group" {
  name      = "hw15-target-group"
  folder_id = var.folder_id

  dynamic "target" {
    for_each = yandex_compute_instance_group.hw15_ig.instances
    content {
      subnet_id  = yandex_vpc_subnet.hw15_subnet.id
      address = target.value.network_interface[0].ip_address
    }
  }
}

# 6. Сетевой балансировщик
resource "yandex_lb_network_load_balancer" "hw15_nlb" {
  name = "hw15-network-load-balancer"

  listener {
    name        = "hw15-listener"
    port        = 80
    target_port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.hw15_target_group.id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
      interval            = 30
      timeout             = 10
      healthy_threshold   = 2
      unhealthy_threshold = 3
    }
  }
}

# Вывод публичных IP-адресов ВМ
output "instance_group_public_ips" {
  value = [for instance in yandex_compute_instance_group.hw15_ig.instances : instance.network_interface[0].nat_ip_address]
}

# Вывод публичного IP балансировщика
output "nlb_public_ip" {
  value = [for l in yandex_lb_network_load_balancer.hw15_nlb.listener : [for e in l.external_address_spec : e.address][0]][0]
}