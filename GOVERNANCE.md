# Governance and Compliance

To maintain a secure and organized cloud environment, this Landing Zone implements **Azure Policy** and the **Microsoft Cloud Adoption Framework (CAF)**.

## 1. Cloud Adoption Framework (CAF) Naming Conventions

All Bicep modules in this repository dynamically generate resource names based on CAF best practices. This ensures consistency and makes resources easily identifiable by their name alone.

**Format:** `<resource-type>-<workload/tier>-<environment>-<region>`

| Resource | Bicep Variable Format | Example Result |
| --- | --- | --- |
| Virtual Network | `'vnet-spoke-${spokeName}-${environment}-${location}'` | `vnet-spoke-prod-eastus` |
| Azure Firewall | `'afw-hub-${environment}-${location}'` | `afw-hub-prod-eastus` |
| Network Security Group | `'nsg-${tierName}-${environment}-${location}'` | `nsg-app-prod-eastus` |
| Log Analytics Workspace | `'log-landingzone-${environment}-${location}'` | `log-landingzone-prod-eastus` |

## 2. Azure Policy

The `modules/policy.bicep` module deploys several critical Governance guardrails at the Resource Group level.

### A. Restrict Allowed Locations
**Policy Definition:** `e56962a6-4747-49cd-b67b-bf8b01975c4c`
- **Purpose:** Prevents developers or administrators from deploying resources in unauthorized Azure regions (e.g., deploying to `westeurope` when the business operates strictly in `eastus`).
- **Benefit:** Ensures data sovereignty and compliance with local laws.

### B. Require Mandatory Tags
**Policy Definition:** `871b6d14-10aa-478d-b590-94f262ecfa99`
- **Purpose:** Audits the creation of any resource that does not include the `Environment` and `CostCenter` tags.
- **Benefit:** Prevents untracked shadow IT and allows FinOps teams to accurately generate billing reports.

## 3. Compliance Frameworks

By implementing this architecture, the SMB inherently aligns with several controls of major compliance frameworks (e.g., SOC 2, ISO 27001):
- **Logical Access Control:** Enforced via Entra ID RBAC.
- **Network Security:** Enforced via Hub-and-Spoke isolation, Azure Firewall, and explicit-deny NSGs.
- **Audit Logging:** Enforced via centralized Log Analytics Workspace capturing all diagnostic data.