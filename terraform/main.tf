# ============================================================
# main.tf — Azure Infrastructure (AKS + ACR + Networking)
# ============================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Store Terraform state in Azure Blob Storage (recommended)
  backend "azurerm" {
    resource_group_name  = "tf-state-rg"
    storage_account_name = "tfstateaccount"
    container_name       = "tfstate"
    key                  = "cicd-project.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# ── Resource Group ──────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg"
  location = var.location
  tags     = var.tags
}

# ── Virtual Network ─────────────────────────────────────────
resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ── Network Security Group ───────────────────────────────────
resource "azurerm_network_security_group" "aks" {
  name                = "${var.project_name}-nsg"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  security_rule {
    name                       = "allow-https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# ── Azure Container Registry ─────────────────────────────────
resource "azurerm_container_registry" "main" {
  name                = "${replace(var.project_name, "-", "")}acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = false
  tags                = var.tags
}

# ── AKS Cluster ──────────────────────────────────────────────
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project_name}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.project_name}-aks"

  default_node_pool {
    name           = "default"
    node_count     = var.aks_node_count
    vm_size        = var.aks_vm_size
    vnet_subnet_id = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = var.tags
}

# ── Grant AKS access to pull from ACR ────────────────────────
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}
