# Azure Landing Zone for SMBs 🚀

[![Azure](https://img.shields.io/badge/azure-%230072C6.svg?style=for-the-badge&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)
[![Bicep](https://img.shields.io/badge/Bicep-0078D4?style=for-the-badge&logo=Microsoft&logoColor=white)](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
[![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/features/actions)
[![Entra ID](https://img.shields.io/badge/Entra_ID-0078D4?style=for-the-badge&logo=microsoft&logoColor=white)](https://www.microsoft.com/security/business/identity-access/microsoft-entra-id)
[![Log Analytics](https://img.shields.io/badge/Log_Analytics-0072C6?style=for-the-badge&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/en-us/services/monitor/)

Welcome to the **Azure Landing Zone for SMBs** project! This repository contains a production-ready Infrastructure-as-Code (IaC) deployment for Small-to-Medium Businesses (SMB) built with **Azure Bicep**. 

This portfolio project demonstrates applied Azure architecture, expanding on core AZ-900 fundamentals by integrating modern cloud principles, security, governance, and cost optimization.

---

## 🏛️ Architecture Diagram

Below is the hub-and-spoke network topology used in this Landing Zone. 

*(Note: If the Mermaid diagram doesn't render, view the [PNG fallback diagram here](./docs/architecture.png) - Exported via VS Code Mermaid Extension).*

```mermaid
graph TD
    %% Global Services
    EntraID[Microsoft Entra ID - RBAC]
    Policy[Azure Policy - Governance]
    LAW[Log Analytics Workspace]
    
    %% Hub Virtual Network
    subgraph HubVNet[Hub VNet: 10.0.0.0/16]
        direction TB
        FW[Azure Firewall]
        VPNGW[VPN Gateway]
        Bastion[Azure Bastion]
        HubNSG[Hub Subnets NSG]
    end
    
    %% Spoke Virtual Networks
    subgraph SpokeProd[Spoke VNet: Production - 10.1.0.0/16]
        ProdNSG[Prod NSG]
        ProdApp[Prod Workloads]
        ProdNSG -.-> ProdApp
    end

    subgraph SpokeDev[Spoke VNet: Development - 10.2.0.0/16]
        DevNSG[Dev NSG]
        DevApp[Dev Workloads]
        DevNSG -.-> DevApp
    end

    subgraph SpokeMgmt[Spoke VNet: Management - 10.3.0.0/16]
        MgmtNSG[Mgmt NSG]
        MgmtTools[Mgmt Tools / Jumpbox]
        MgmtNSG -.-> MgmtTools
    end

    %% VNet Peering
    HubVNet <-->|VNet Peering| SpokeProd
    HubVNet <-->|VNet Peering| SpokeDev
    HubVNet <-->|VNet Peering| SpokeMgmt

    %% Traffic Flow
    Internet((Internet)) --> FW
    FW --> VPNGW
    Internet --> VPNGW
    Internet --> Bastion
    
    FW --> |Filtered Traffic| SpokeProd
    FW --> |Filtered Traffic| SpokeDev
    FW --> |Filtered Traffic| SpokeMgmt
    
    Bastion --> |RDP/SSH| SpokeProd
    Bastion --> |RDP/SSH| SpokeDev
    Bastion --> |RDP/SSH| SpokeMgmt
    
    %% Diagnostics
    HubVNet -.->|Diagnostic Logs| LAW
    SpokeProd -.->|Diagnostic Logs| LAW
    SpokeDev -.->|Diagnostic Logs| LAW
    SpokeMgmt -.->|Diagnostic Logs| LAW
    
    %% Governance
    EntraID -.->|Role Assignments| HubVNet
    EntraID -.->|Role Assignments| SpokeProd
    EntraID -.->|Role Assignments| SpokeDev
    EntraID -.->|Role Assignments| SpokeMgmt
    
    Policy -.->|Enforce Rules| HubVNet
    Policy -.->|Enforce Rules| SpokeProd
    Policy -.->|Enforce Rules| SpokeDev
    Policy -.->|Enforce Rules| SpokeMgmt

    classDef default fill:#f9f9f9,stroke:#333,stroke-width:2px;
    classDef hub fill:#e1f5fe,stroke:#0288d1,stroke-width:2px;
    classDef spoke fill:#e8f5e9,stroke:#388e3c,stroke-width:2px;
    classDef global fill:#fff3e0,stroke:#f57c00,stroke-width:2px;
    
    class HubVNet hub;
    class SpokeProd,SpokeDev,SpokeMgmt spoke;
    class EntraID,Policy,LAW global;
```

---

## 🧠 Why This Architecture? (Connecting to AZ-900 Principles)

This design embodies core Azure cloud concepts suitable for a growing SMB:
1. **High Availability & Fault Tolerance:** By isolating workloads into multiple Spoke VNets (Prod, Dev, Mgmt), a failure or compromise in one environment doesn't automatically cascade to the others.
2. **Security & Least Privilege:** Employs zero-trust principles. All Spoke ingress/egress is routed through the Hub's Azure Firewall. Network Security Groups (NSGs) utilize explicit allow/deny rules, and Microsoft Entra ID applies strict RBAC limits.
3. **Governance & Compliance:** Azure Policy ensures that only approved regions are used and mandatory tags (Environment, Owner, CostCenter, Project) are appended to all resources, aligning with Microsoft Cloud Adoption Framework (CAF).
4. **Predictable Cost & Scalability:** Resource decoupling allows the Dev spoke to be scaled down or stopped during off-hours, while the Prod spoke remains highly available.
5. **Operational Excellence:** A centralized Log Analytics Workspace aggregates diagnostics logs across all layers, providing unified observability.

---

## 💰 Cost Estimate (Monthly Approximation for SMB Scale)

*Prices are estimated in USD and will vary based on Azure Region, actual usage, and licensing.*

| Component | Azure SKU / Configuration | Monthly Est. Cost |
| --- | --- | --- |
| **Azure Firewall** | Standard Tier (Base + Data Processing) | $900.00 |
| **VPN Gateway** | VpnGw1 (Base + Egress) | $140.00 |
| **Azure Bastion** | Basic Tier | $135.00 |
| **Log Analytics** | Pay-as-you-go (Est. 50GB ingest) | $150.00 |
| **Virtual Networks** | Hub + 3 Spokes (VNet Peering Traffic) | $50.00 |
| **Compute (Spokes)** | 3x B2ms VMs (Jumpbox, App, DB Placeholder) | $130.00 |
| **Governance / RBAC** | Azure Policy & Entra ID Free/P1 | $0.00 |
| **Total Estimated Monthly** | **Baseline Infrastructure** | **~ $1,505.00** |

*For more details on cost reduction strategies (like Reserved Instances), see [COST-OPTIMIZATION.md](./COST-OPTIMIZATION.md).*

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your local machine:
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
- An active Azure Subscription

### Deployment Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/azure-landing-zone-smb.git
   cd azure-landing-zone-smb
   ```

2. **Login to Azure:**
   ```bash
   az login
   az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
   ```

3. **Deploy the Landing Zone (Dev Environment):**
   ```bash
   # Create a resource group for the deployment
   az group create --name rg-smb-landingzone-dev-eus --location eastus

   # Deploy the main Bicep template using the Dev parameter file
   az deployment group create \
     --resource-group rg-smb-landingzone-dev-eus \
     --template-file main.bicep \
     --parameters @parameters/dev.parameters.json
   ```

For a detailed deployment breakdown, review the [IMPLEMENTATION-GUIDE.md](./IMPLEMENTATION-GUIDE.md).

---

## 📂 Documentation

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Deep dive into Hub-and-Spoke design and traffic flows.
- [RBAC-DESIGN.md](./RBAC-DESIGN.md) - Role matrix and least-privilege Entra ID configurations.
- [COST-OPTIMIZATION.md](./COST-OPTIMIZATION.md) - Right-sizing, reserved instances, and tagging strategies.
- [GOVERNANCE.md](./GOVERNANCE.md) - Azure Policy, naming conventions, and compliance.
- [IMPLEMENTATION-GUIDE.md](./IMPLEMENTATION-GUIDE.md) - Step-by-step deployment and validation.
- [CHANGELOG.md](./CHANGELOG.md) - Roadmap and future additions.