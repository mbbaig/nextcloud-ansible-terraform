terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "do_token" {
  type = string
}

variable "do_spaces_access_id" {
  type = string
}

variable "do_spaces_secret_key" {
  type = string
}

variable "ssh_key_id" {
  type = number
}

variable "alert_email" {
  type = string
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
  spaces_access_id = var.do_spaces_access_id
  spaces_secret_key = var.do_spaces_secret_key
}

resource "digitalocean_droplet" "nextcloud_server" {
  image  = "ubuntu-20-04-x64"
  name   = "nextcloud-server-1"
  region = "tor1"
  size   = "s-1vcpu-2gb"
  monitoring = true
  ssh_keys = [var.ssh_key_id]
  tags = ["document", "nextcloud"]
  droplet_agent = true
  graceful_shutdown = true
}

resource "digitalocean_spaces_bucket" "sfisoftware_documents" {
  name = "com.sfisoftware.documents"
  region = "nyc3"
} 

resource "digitalocean_project" "documents" {
  name        = "Documents"
  description = "Project for housing documents."
  purpose     = "Document hosting"
  environment = "Production"
  resources   = [
    digitalocean_droplet.nextcloud_server.urn, 
    digitalocean_spaces_bucket.sfisoftware_documents.urn
  ]
}

resource "digitalocean_monitor_alert" "cpu_alert" {
  alerts {
    email = [var.alert_email]
  }
  window      = "5m"
  type        = "v1/insights/droplet/cpu"
  compare     = "GreaterThan"
  value       = 70
  enabled     = true
  entities    = [digitalocean_droplet.nextcloud_server.id]
  description = "Alert about CPU usage"
}
