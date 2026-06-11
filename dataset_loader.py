"""
dataset_loader.py
Loads TerraDS Terraform HCL files, filters by provider,
and builds the fixed 300-sample test prompt set used across all 9 experiments.
"""

from __future__ import annotations
import os
import re
import random
import json
from pathlib import Path
from config import DATASET_PATH, NUM_SAMPLES, RANDOM_SEED, PROVIDERS, OUTPUT_DIR

PROMPT_CACHE = os.path.join(OUTPUT_DIR, "test_prompts_300.json")


# ─────────────────────────────────────────────────────────────────────────────
# HCL file discovery
# ─────────────────────────────────────────────────────────────────────────────

def find_tf_files(root: str) -> list[Path]:
    return list(Path(root).rglob("*.tf"))


def detect_provider(content: str) -> str | None:
    for provider, meta in PROVIDERS.items():
        if re.search(rf'resource\s+"({meta["prefix"]})', content):
            return provider
    return None


def extract_resources(content: str) -> list[str]:
    return re.findall(r'resource\s+"([a-z_]+)"', content)


# ─────────────────────────────────────────────────────────────────────────────
# Module loading
# ─────────────────────────────────────────────────────────────────────────────

def load_modules(max_per_provider: int = 400) -> dict[str, list[dict]]:
    """
    Load Terraform modules from TerraDS grouped by provider.
    Returns { provider: [ {content, resources, path}, ... ] }
    """
    tf_files = find_tf_files(DATASET_PATH)
    modules: dict[str, list[dict]] = {p: [] for p in PROVIDERS}

    for tf_path in tf_files:
        try:
            content = tf_path.read_text(errors="ignore")
        except Exception:
            continue
        if not content.strip():
            continue
        provider = detect_provider(content)
        if provider and len(modules[provider]) < max_per_provider:
            modules[provider].append({
                "content":   content,
                "resources": extract_resources(content),
                "path":      str(tf_path),
            })

    for p, mods in modules.items():
        print(f"  Loaded {len(mods):>4} modules for {PROVIDERS[p]['label']}")
    return modules


# ─────────────────────────────────────────────────────────────────────────────
# Prompt templates  (expanded to support 300 samples)
# ─────────────────────────────────────────────────────────────────────────────

PROMPT_TEMPLATES = {
    "aws": [
        "Generate Terraform HCL to create an AWS VPC with public and private subnets, an internet gateway, route tables, and security groups.",
        "Generate Terraform HCL for an EC2 instance with an attached security group and placement inside an existing subnet.",
        "Generate Terraform HCL for an S3 bucket with versioning enabled, server-side encryption, and blocked public access.",
        "Generate Terraform HCL for an AWS RDS MySQL instance inside a private subnet with a security group.",
        "Generate Terraform HCL for an AWS Application Load Balancer with target groups and listener rules.",
        "Generate Terraform HCL for an AWS EKS cluster with a managed node group and required IAM roles.",
        "Generate Terraform HCL for an AWS Lambda function with an IAM execution role and CloudWatch log group.",
        "Generate Terraform HCL for an AWS Route 53 hosted zone with A and CNAME records.",
        "Generate Terraform HCL for an AWS IAM role with a least-privilege policy for S3 read access.",
        "Generate Terraform HCL for an AWS CloudFront distribution backed by an S3 bucket with OAI.",
        "Generate Terraform HCL for an AWS ElastiCache Redis cluster inside a private subnet.",
        "Generate Terraform HCL for an AWS SQS queue with a dead-letter queue and access policy.",
        "Generate Terraform HCL for an AWS SNS topic with an email subscription.",
        "Generate Terraform HCL for an AWS ECS Fargate service with a task definition and ALB integration.",
        "Generate Terraform HCL for an AWS Auto Scaling group with a launch template and scaling policies.",
        "Generate Terraform HCL for an AWS NAT Gateway attached to a public subnet.",
        "Generate Terraform HCL for an AWS CodePipeline with S3 artifact store and IAM roles.",
        "Generate Terraform HCL for an AWS Secrets Manager secret with a rotation policy.",
        "Generate Terraform HCL for an AWS KMS key with an alias and key policy.",
        "Generate Terraform HCL for an AWS DynamoDB table with GSI, point-in-time recovery, and encryption.",
    ],
    "azurerm": [
        "Generate Terraform HCL for an Azure resource group, virtual network, subnet, and network security group.",
        "Generate Terraform HCL for an Azure Linux virtual machine with a network interface, public IP, and SSH key.",
        "Generate Terraform HCL for an Azure Storage Account with blob containers and private access only.",
        "Generate Terraform HCL for an Azure App Service plan and Web App with application settings.",
        "Generate Terraform HCL for an Azure SQL Server and SQL Database with firewall rules.",
        "Generate Terraform HCL for an Azure AKS cluster with a default node pool and managed identity.",
        "Generate Terraform HCL for an Azure Key Vault with access policies and secret storage.",
        "Generate Terraform HCL for an Azure Load Balancer with a backend pool and health probe.",
        "Generate Terraform HCL for an Azure Container Registry with admin access disabled.",
        "Generate Terraform HCL for an Azure Virtual Machine Scale Set with autoscaling.",
        "Generate Terraform HCL for an Azure Function App with a storage account and consumption plan.",
        "Generate Terraform HCL for an Azure API Management instance with a product and API.",
        "Generate Terraform HCL for an Azure Service Bus namespace with a queue and topic.",
        "Generate Terraform HCL for an Azure Cosmos DB account with a SQL database and container.",
        "Generate Terraform HCL for an Azure PostgreSQL Flexible Server with a private DNS zone.",
        "Generate Terraform HCL for an Azure CDN profile and endpoint backed by a storage account.",
        "Generate Terraform HCL for an Azure Application Gateway with WAF policy and backend pool.",
        "Generate Terraform HCL for an Azure Bastion Host and associated public IP.",
        "Generate Terraform HCL for an Azure Monitor Log Analytics workspace with diagnostic settings.",
        "Generate Terraform HCL for an Azure Event Hub namespace with an event hub and consumer group.",
    ],
    "google": [
        "Generate Terraform HCL for a GCP VPC network with subnets, firewall rules, and Cloud Router.",
        "Generate Terraform HCL for a GCP Compute Engine instance with a network interface and firewall tag.",
        "Generate Terraform HCL for a GCP Cloud Storage bucket with uniform bucket-level access and no public access.",
        "Generate Terraform HCL for a GCP GKE cluster with a node pool and network policy enabled.",
        "Generate Terraform HCL for a GCP Cloud SQL PostgreSQL instance with private IP and backup configuration.",
        "Generate Terraform HCL for a GCP Cloud Run service with traffic split and IAM binding.",
        "Generate Terraform HCL for a GCP Cloud Functions function with an HTTP trigger and service account.",
        "Generate Terraform HCL for a GCP Load Balancer with a backend service, URL map, and health check.",
        "Generate Terraform HCL for GCP IAM service account bindings with minimal required roles.",
        "Generate Terraform HCL for a GCP Cloud Pub/Sub topic and subscription with IAM permissions.",
        "Generate Terraform HCL for a GCP Memorystore Redis instance inside a private VPC.",
        "Generate Terraform HCL for a GCP BigQuery dataset and table with access controls.",
        "Generate Terraform HCL for a GCP Cloud Armor security policy attached to a backend service.",
        "Generate Terraform HCL for a GCP Dataflow job with a staging bucket and service account.",
        "Generate Terraform HCL for a GCP Secret Manager secret with IAM binding.",
        "Generate Terraform HCL for a GCP VPN gateway with a tunnel and BGP session.",
        "Generate Terraform HCL for a GCP Managed Instance Group with autoscaling and health check.",
        "Generate Terraform HCL for a GCP Cloud DNS managed zone with A and CNAME records.",
        "Generate Terraform HCL for a GCP Artifact Registry repository with IAM binding.",
        "Generate Terraform HCL for a GCP Spanner instance and database with IAM roles.",
    ],
    "multi": [
        "Generate Terraform HCL to create object storage across AWS S3, Azure Storage Account, and GCP Cloud Storage using separate provider blocks.",
        "Generate Terraform HCL for a compute instance on AWS (EC2), Azure (Linux VM), and GCP (Compute Engine) using separate provider blocks.",
        "Generate Terraform HCL for a virtual network on AWS (VPC), Azure (VNet), and GCP (VPC Network) with subnets.",
        "Generate Terraform HCL for a managed Kubernetes cluster on AWS (EKS), Azure (AKS), and GCP (GKE).",
        "Generate Terraform HCL for a managed relational database on AWS (RDS), Azure (SQL Database), and GCP (Cloud SQL).",
        "Generate Terraform HCL for a serverless function on AWS (Lambda), Azure (Function App), and GCP (Cloud Functions).",
        "Generate Terraform HCL for a CDN setup on AWS (CloudFront), Azure (CDN), and GCP (Cloud CDN).",
        "Generate Terraform HCL for a message queue on AWS (SQS), Azure (Service Bus Queue), and GCP (Pub/Sub).",
        "Generate Terraform HCL for DNS zones on AWS (Route 53), Azure (DNS Zone), and GCP (Cloud DNS).",
        "Generate Terraform HCL for secret management on AWS (Secrets Manager), Azure (Key Vault), and GCP (Secret Manager).",
    ],
    "security": [
        "Generate Terraform HCL for an AWS security group allowing only HTTPS (443) inbound, blocking SSH (22), using variables for CIDR values.",
        "Generate Terraform HCL for an S3 bucket that blocks all public access, uses KMS encryption, and stores the KMS key ARN in a variable.",
        "Generate Terraform HCL for an Azure NSG that denies all inbound traffic except port 443, with no hardcoded credentials.",
        "Generate Terraform HCL for a GCP firewall rule restricting SSH to a specific CIDR range, disallowing 0.0.0.0/0.",
        "Generate Terraform HCL for a least-privilege IAM policy for an AWS Lambda function with only required S3 read permissions.",
        "Generate Terraform HCL for an Azure Storage Account with HTTPS-only traffic, no public blob access, and TLS 1.2 minimum.",
        "Generate Terraform HCL for a GCP Cloud Storage bucket with no public access and a lifecycle rule using variables.",
        "Generate Terraform HCL for an AWS RDS instance with encryption enabled, not publicly accessible, and credentials in variables.",
        "Generate Terraform HCL for an Azure Key Vault with soft delete, purge protection enabled, and RBAC authorisation.",
        "Generate Terraform HCL for a GCP GKE cluster with private nodes, master authorised networks, and Workload Identity enabled.",
        "Generate Terraform HCL for an AWS EKS cluster with envelope encryption and private endpoint access only.",
        "Generate Terraform HCL for an Azure SQL Server with Azure AD authentication and no SQL login allowed.",
        "Generate Terraform HCL for a GCP Compute firewall that blocks all ingress except port 443 from a named IP range variable.",
        "Generate Terraform HCL for an AWS CloudTrail with S3 logging, log file validation enabled, and KMS encryption.",
        "Generate Terraform HCL for an AWS WAF WebACL with managed rule groups attached to an ALB.",
    ],
    "dependency": [
        "Generate Terraform HCL for an AWS EC2 instance. Ensure subnet_id and vpc_security_group_ids use Terraform resource references, not hardcoded IDs.",
        "Generate Terraform HCL for an Azure Linux VM. All dependencies (resource group, vnet, subnet, NIC) must be declared and referenced using resource attributes.",
        "Generate Terraform HCL for a GCP Compute instance. Network and subnetwork must reference google_compute_network and google_compute_subnetwork resources.",
        "Generate Terraform HCL for an AWS RDS instance inside a DB subnet group. The subnet group must reference actual aws_subnet resources.",
        "Generate Terraform HCL for an Azure Application Gateway. All dependent resources must be wired through Terraform resource references.",
        "Generate Terraform HCL for an AWS EKS node group. The cluster name and subnet IDs must reference existing aws_eks_cluster and aws_subnet resources.",
        "Generate Terraform HCL for a GCP GKE node pool. It must reference the parent google_container_cluster resource by name.",
        "Generate Terraform HCL for an Azure AKS cluster with a node pool. Resource group and subnet must be referenced from declared resources.",
        "Generate Terraform HCL for an AWS Lambda function with an IAM role. The role ARN must reference the aws_iam_role resource.",
        "Generate Terraform HCL for a GCP Cloud Run service. The service account must reference a declared google_service_account resource.",
        "Generate Terraform HCL for an AWS ALB listener. The ALB ARN and target group ARN must both reference declared Terraform resources.",
        "Generate Terraform HCL for an Azure SQL Database. The server name must reference a declared azurerm_sql_server resource.",
        "Generate Terraform HCL for a GCP Cloud SQL database. The instance must reference a declared google_sql_database_instance resource.",
        "Generate Terraform HCL for an AWS ECS service. The cluster ARN, task definition, and ALB target group must all use resource references.",
        "Generate Terraform HCL for an Azure Private Endpoint. The subnet ID and private connection resource ID must use resource references.",
    ],
}


# ─────────────────────────────────────────────────────────────────────────────
# Build 300-sample test set
# ─────────────────────────────────────────────────────────────────────────────

def build_test_prompts() -> list[dict]:
    """
    Build the fixed 300-sample test set.
    Distribution (matches thesis prompt table scaled to 300):
      AWS        → 75
      Azure      → 75
      GCP        → 75
      Multi      → 25
      Security   → 25
      Dependency → 25
    Total: 300

    Saved to disk so ALL 9 experiments use the exact same set.
    """
    if os.path.exists(PROMPT_CACHE):
        with open(PROMPT_CACHE) as f:
            prompts = json.load(f)
        print(f"Loaded {len(prompts)} cached test prompts from {PROMPT_CACHE}")
        return prompts

    random.seed(RANDOM_SEED)
    prompts = []

    targets = {
        "aws":       75,
        "azurerm":   75,
        "google":    75,
        "multi":     25,
        "security":  25,
        "dependency":25,
    }

    for category, n in targets.items():
        pool = PROMPT_TEMPLATES[category]
        # Repeat pool to reach target count, then shuffle
        repeated = (pool * ((n // len(pool)) + 1))[:n]
        random.shuffle(repeated)
        for i, text in enumerate(repeated):
            prompts.append({
                "id":       f"{category.upper()}_{i+1:03d}",
                "category": category,
                "provider": category if category in ("aws", "azurerm", "google") else "multi",
                "prompt":   text,
            })

    random.shuffle(prompts)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    with open(PROMPT_CACHE, "w") as f:
        json.dump(prompts, f, indent=2)
    print(f"Built and cached {len(prompts)} test prompts → {PROMPT_CACHE}")
    return prompts


if __name__ == "__main__":
    prompts = build_test_prompts()
    print(f"\nTotal prompts: {len(prompts)}")
    for cat in ["aws", "azurerm", "google", "multi", "security", "dependency"]:
        n = sum(1 for p in prompts if p["category"] == cat)
        print(f"  {cat:12s}: {n}")
