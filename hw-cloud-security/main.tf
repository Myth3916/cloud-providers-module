terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.130.0"
    }
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}

# Создаем симметричный KMS-ключ для шифрования
resource "yandex_kms_symmetric_key" "hw_key" {
  name              = "hw-kms-key"
  description       = "Ключ для шифрования бакета в рамках ДЗ"
  default_algorithm = "AES_256"
  rotation_period   = "8760h"  # 1 год
}

# Выводим ID ключа — он понадобится для шифрования бакета
output "kms_key_id" {
  value       = yandex_kms_symmetric_key.hw_key.id
  description = "ID созданного KMS-ключа"
}

# Создаем бакет Object Storage с шифрованием
resource "yandex_storage_bucket" "hw_bucket" {
  # Имя бакета должно быть глобально уникальным во всем Yandex Cloud!
  # Используй свое уникальное сочетание (например, с ником и годом)
  bucket = "oleg-hw-secure-bucket-2026" 
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.hw_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

# Выводим имя бакета для удобства
output "bucket_name" {
  value       = yandex_storage_bucket.hw_bucket.bucket
  description = "Имя созданного зашифрованного бакета"
}