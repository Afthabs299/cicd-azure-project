# End-to-End CI/CD Pipeline — Azure DevOps + Terraform + AKS

A production-ready CI/CD pipeline that automatically builds, containerises, and deploys a Flask application to Azure Kubernetes Service (AKS) using Azure DevOps, Terraform, and Docker.

---

## Architecture

```
Developer → GitHub → Azure DevOps Pipeline
                          │
                    ┌─────▼─────┐
                    │   Build   │  Docker build + push to ACR
                    └─────┬─────┘
                          │
                    ┌─────▼─────┐
                    │  Deploy   │  kubectl apply → AKS
                    └─────┬─────┘
                          │
                    ┌─────▼─────┐
                    │    AKS    │  2 replicas, LoadBalancer
                    └───────────┘
```

**Infrastructure (Terraform):** Resource Group → VNet + Subnet + NSG → ACR → AKS Cluster → Role Assignment (AcrPull)

---

## Project Structure

```
cicd-azure-project/
├── app/
│   ├── app.py              # Flask application
│   ├── requirements.txt    # Python dependencies
│   └── Dockerfile          # Container definition
├── terraform/
│   ├── main.tf             # Azure resources (AKS, ACR, VNet)
│   ├── variables.tf        # Input variables
│   ├── outputs.tf          # Exported values
│   └── terraform.tfvars.example
├── k8s/
│   ├── deployment.yaml     # AKS Deployment (2 replicas)
│   └── service.yaml        # LoadBalancer Service
├── .azure-pipelines/
│   └── azure-pipelines.yml # Multi-stage CI/CD pipeline
├── scripts/
│   ├── deploy.sh           # Manual deploy script
│   └── provision.sh        # Terraform wrapper script
└── README.md
```

---

## Prerequisites

| Tool | Version |
|------|---------|
| Azure CLI | ≥ 2.50 |
| Terraform | ≥ 1.6 |
| Docker | ≥ 24 |
| kubectl | ≥ 1.28 |
| Azure subscription | — |

---

## Quick Start

### 1. Clone the repo
```bash
git clone https://github.com/<your-username>/cicd-azure-project.git
cd cicd-azure-project
```

### 2. Provision infrastructure with Terraform
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your values

bash scripts/provision.sh apply
```

Note the outputs — you'll need `acr_login_server` for the pipeline variable.

### 3. Configure Azure DevOps
1. Create a new project in [dev.azure.com](https://dev.azure.com)
2. Add a **Service Connection** (`AzureServiceConnection`) pointing to your subscription
3. Set the `ACR_LOGIN_SERVER` pipeline variable to the value from Terraform output
4. Import the pipeline from `.azure-pipelines/azure-pipelines.yml`

### 4. Push code → pipeline triggers automatically
Any push to `main` triggers: **Build → Push to ACR → Deploy to AKS**

---

## Manual Deployment
```bash
export ACR_LOGIN_SERVER="cicddemoacr.azurecr.io"
bash scripts/deploy.sh v1.0.0
```

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Returns version and environment info |
| GET | `/health` | Health check (used by Kubernetes probes) |

---

## Key Concepts Demonstrated

- **Infrastructure as Code** — All Azure resources managed by Terraform
- **Multi-stage pipelines** — Build and Deploy are separate, gated stages
- **Container registry** — ACR stores versioned Docker images
- **Self-healing deployments** — Liveness and readiness probes in AKS
- **Least privilege** — AKS uses managed identity with only `AcrPull` role
- **State management** — Terraform state stored remotely in Azure Blob Storage

---

## Author
Shaik Mohammed Afthab — [LinkedIn](https://linkedin.com) — afthabs299@gmail.com
