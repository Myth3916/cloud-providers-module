variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "storage_access_key" {
  description = "Access key for Object Storage"
  type        = string
  sensitive   = true
}

variable "storage_secret_key" {
  description = "Secret key for Object Storage"
  type        = string
  sensitive   = true
}