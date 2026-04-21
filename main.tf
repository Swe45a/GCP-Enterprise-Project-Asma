cat > main.tf << 'EOF'
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC
resource "google_compute_network" "prod_vpc" {
  name                    = "prod-vpc-main"
  auto_create_subnetworks = false
}

# Public Subnet
resource "google_compute_subnetwork" "public_subnet" {
  name          = "prod-subnet-public"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.prod_vpc.id
}

# Private Subnet
resource "google_compute_subnetwork" "private_subnet" {
  name                     = "prod-subnet-private"
  ip_cidr_range            = "10.0.2.0/24"
  region                   = var.region
  network                  = google_compute_network.prod_vpc.id
  private_ip_google_access = true
}

# Cloud Router
resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  region  = var.region
  network = google_compute_network.prod_vpc.id
}

# Cloud NAT
resource "google_compute_router_nat" "cloud_nat" {
  name                               = "cloud-nat"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall Rules
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.prod_vpc.name
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = google_compute_network.prod_vpc.name
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.prod_vpc.name
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["10.0.0.0/8"]
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.prod_vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["web-server"]
}

# VM 1
resource "google_compute_instance" "prod_web_1" {
  name         = "prod-web-1"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"
  tags         = ["web-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "<h1>prod-web-1</h1>" > /var/www/html/index.html
    systemctl start nginx
  SCRIPT
}

# VM 2
resource "google_compute_instance" "prod_web_2" {
  name         = "prod-web-2"
  machine_type = "n1-standard-1"
  zone         = "us-central1-b"
  tags         = ["web-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "<h1>prod-web-2</h1>" > /var/www/html/index.html
    systemctl start nginx
  SCRIPT
}

# Cloud SQL
resource "google_sql_database_instance" "prod_db" {
  name             = "prod-db"
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.prod_vpc.id
    }
  }
}

# Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password"
  replication {
    automatic = true
  }
}

# Monitoring Alert
resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name = "High CPU Alert"
  combiner     = "OR"
  conditions {
    display_name = "CPU > 80%"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
    }
  }
}
