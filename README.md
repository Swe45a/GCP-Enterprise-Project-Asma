# GCP Enterprise Infrastructure - Capstone Project

## 1. Project Overview
This project demonstrates the deployment of a production-ready enterprise infrastructure on Google Cloud Platform (GCP). The design follows best practices in security, scalability, and high availability using Infrastructure as Code (Terraform).

## 2. Architecture Design
The solution is based on a secure multi-tier architecture:
- Custom VPC network
- Public and private subnets
- Private virtual machines (no public IPs)
- Cloud NAT for outbound connectivity
- HTTP Load Balancer for traffic distribution
- (Planned) Cloud SQL database layer

## 3. Networking
- **VPC Name:** prod-vpc-main (Custom mode)
- **Public Subnet:** prod-subnet-public (10.0.1.0/24)
- **Private Subnet:** prod-subnet-private (10.0.2.0/24)
- **Region:** us-central1
- **Cloud Router:** nat-router
- **Cloud NAT:** cloud-nat (Auto IP allocation)

## 4. Compute Layer
Two virtual machines are deployed in the private subnet:
- **prod-web-1** (us-central1-a) – 10.0.2.2
- **prod-web-2** (us-central1-b) – 10.0.2.3

Both instances run Nginx and serve as web servers behind the load balancer.

## 5. Load Balancing
An HTTP Load Balancer is configured to:
- Distribute incoming traffic across both web servers
- Improve availability and fault tolerance

## 6. Security Configuration
- No external IPs for virtual machines
- Access through IAP (Identity-Aware Proxy) only
- Firewall rules based on least privilege principle
- Controlled inbound traffic:
  - HTTP (80)
  - HTTPS (443)
  - SSH via IAP only

## 7. Firewall Rules
**allow-http** → Port 80 | Source: 0.0.0.0/0

**allow-https** → Port 443 | Source: 0.0.0.0/0

**allow-internal** → All ports | Source: 10.0.0.0/8

**allow-iap-ssh** → Port 22 | Source: 35.235.240.0/20

## 8. Monitoring & Logging
Cloud Monitoring was planned for:
- CPU utilization alerts
- Basic resource monitoring

> **Note:** Not fully enabled due to Sandbox limitations.

## 9. Sandbox Limitations
The following services could not be created due to permission restrictions:
- Cloud SQL (MySQL 8.0)
- Service Accounts
- Secret Manager
- Cloud Monitoring

> All configurations are included in Terraform files as proof of implementation knowledge.

## 10. Infrastructure as Code (Terraform)
The entire infrastructure is defined using Terraform:
- **main.tf** → Core resources
- **variables.tf** → Input variables
- **outputs.tf** → Outputs

## 11. Deployment Steps
```bash
terraform init
terraform plan
terraform apply
```

## 12. Conclusion
This project demonstrates the ability to design and deploy a secure and scalable cloud infrastructure on GCP. It highlights practical knowledge of networking, compute, security, and Infrastructure as Code, even within restricted sandbox environments.
