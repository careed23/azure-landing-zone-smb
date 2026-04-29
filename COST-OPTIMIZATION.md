# Cost Optimization Strategy

For a Small-to-Medium Business (SMB), minimizing unnecessary cloud spend while maintaining high availability and security is paramount. This landing zone incorporates several FinOps and cost-optimization principles.

## 1. Environment Segregation & Toggling

By utilizing separate parameter files (`dev.parameters.json` and `prod.parameters.json`), we control what infrastructure is deployed based on the environment.
- **Dev:** `deployFirewall: false`, `deployVpnGateway: false`. The Dev environment can utilize cheaper networking (like basic NSGs instead of Azure Firewall) to drastically reduce monthly spend.
- **Prod:** Full Hub-and-Spoke with Azure Firewall and VPN Gateway for high security and connectivity.

## 2. Right-Sizing Compute

Instead of deploying large VMs, the architecture recommends **B-Series (Burstable) Virtual Machines** for basic app/web servers and jumpboxes.
- **B2ms:** ~ $60/month (Pay-As-You-Go). Excellent for active directory domain controllers, small web apps, and management tools that don't require sustained CPU.

## 3. Azure Reservations & Savings Plans

To lower the estimated monthly bill significantly, the SMB should utilize **Azure Reserved Instances (RIs)** or **Azure Savings Plans**.

| Resource | Pay-As-You-Go | 3-Year Reservation | Estimated Savings |
| --- | --- | --- | --- |
| B2ms Virtual Machine | ~$60 / month | ~$25 / month | Up to 58% |
| Log Analytics (100 GB/day) | ~$2.30 / GB | Capacity Reservation | Up to 15% |

## 4. Automation: Start/Stop VMs during off-hours

In the `Dev-Spoke`, developers usually only work 40 hours a week out of the available 168 hours. 
- Implement **Azure Automation** to shut down VMs in the Dev Spoke at 7:00 PM and start them at 7:00 AM on weekdays.
- This single change can cut compute costs in the Dev environment by over **70%**.

## 5. Cost Allocation via Tagging

We use Azure Policy (`modules/policy.bicep`) to enforce mandatory tags on every resource:
- `Environment`
- `CostCenter`
- `Project`

**Why?** In the Azure Billing Portal, you can group costs by the `CostCenter` or `Environment` tag. This allows the CFO or IT Director to see exactly how much the "Dev" environment costs vs. "Prod", preventing "shadow IT" and untracked spending.

## 6. Azure Firewall Costs

The **Azure Firewall** is the most expensive component of this Landing Zone (~$900/mo for Standard Tier). 
- If this cost is prohibitive for a very small business, consider downgrading to the **Azure Firewall Basic** SKU (~$295/mo), which provides essential L3-L7 filtering suitable for smaller throughput needs. The Bicep module can be easily modified to change the SKU from `Standard` to `Basic`.