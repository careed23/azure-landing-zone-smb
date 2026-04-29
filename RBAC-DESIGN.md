# Entra ID & RBAC Design

Securing an Azure Landing Zone goes beyond network firewalls; it requires strict Identity and Access Management (IAM) leveraging **Microsoft Entra ID**. 

This Landing Zone implements the **Principle of Least Privilege (PoLP)**. Rather than assigning broad "Owner" or "Contributor" permissions at the Subscription level, roles are granted at the Resource Group or specific Resource levels.

## Built-In Roles Matrix

To accommodate a typical SMB IT team structure, we map Entra ID Security Groups to specific Azure Built-in Roles.

| Entra ID Group | Azure Role | Scope | Justification |
| --- | --- | --- | --- |
| **IT-Admins** | `Owner` | Subscription | Requires full access to assign permissions, modify billing, and deploy overarching policies. |
| **Network-Admins** | `Network Contributor` | Hub Resource Group | Allows the network team to manage the Azure Firewall, VPN Gateway, and VNet peerings without granting compute or data access. |
| **DevOps-Engineers** | `Contributor` | Dev Resource Group | Developers need the ability to create, modify, and destroy PaaS/IaaS resources in the Development Spoke, but should not have access to Prod. |
| **SecOps** | `Reader` & `Log Analytics Reader` | Subscription | Security analysts need visibility into all resources and diagnostic logs to hunt for threats, but do not need permissions to alter infrastructure. |

## Bicep Implementation

The `modules/rbac.bicep` module automates the assignment of these roles.

When deploying the Bicep template via GitHub Actions or the CLI, the Service Principal used for deployment must have the `User Access Administrator` or `Owner` role on the target scope to perform these assignments.

```bicep
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignments: {
  name: guid(resourceGroup().id, assignment.principalId, assignment.roleDefinitionId)
  properties: {
    principalId: assignment.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', assignment.roleDefinitionId)
    principalType: 'Group'
  }
}]
```

*Note: In this repository's `main.bicep`, the RBAC module is provided as a framework. You must populate the `roleAssignments` array with the specific Object IDs of the Entra ID Groups in your tenant.*

## Conditional Access & MFA

While outside the scope of Bicep Resource Manager deployments, it is **highly recommended** that the SMB configures Entra ID Conditional Access policies:
1. **Require MFA for Admins:** Any user in the IT-Admins or Network-Admins group must pass Multi-Factor Authentication to access the Azure Portal.
2. **Block Legacy Authentication:** Disable protocols that do not support modern auth/MFA.
3. **PIM (Privileged Identity Management):** (If using Entra ID P2) Require users to "activate" their Owner/Contributor roles with a time limit and justification.