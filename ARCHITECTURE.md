# Architecture Deep Dive

This document explains the structural decisions, network flows, and design principles behind the SMB Azure Landing Zone.

## 1. Hub and Spoke Topology

We utilize a **Hub-and-Spoke** network topology. This is the Microsoft-recommended standard for cloud networks.

### The Hub Virtual Network
The Hub acts as the central point of connectivity for the entire cloud environment. It contains shared services that all other networks (Spokes) can utilize, reducing redundancy and cost.
- **Azure Firewall:** Inspects and filters all traffic moving between Spokes (East-West) and to the Internet (North-South).
- **VPN Gateway:** Provides a secure IPsec tunnel back to the SMB's on-premises office.
- **Azure Bastion:** Provides secure, seamless RDP/SSH access to VMs without exposing public IP addresses.

### The Spoke Virtual Networks
Spokes are separate VNets used to isolate workloads.
- **Production Spoke (`10.1.0.0/16`):** Houses customer-facing or business-critical applications.
- **Development Spoke (`10.2.0.0/16`):** Houses testing and staging environments. Can be easily torn down or scaled back to save costs.

## 2. Traffic Flow & Routing

A core tenet of this architecture is **Zero Trust**. By default, different Virtual Networks in Azure cannot communicate. We enable connectivity using **VNet Peering**, but we override the default routing behavior to force traffic through the firewall.

### Outbound Traffic (Spoke to Internet)
1. A VM in the `Prod-Spoke` attempts to reach `google.com`.
2. A Custom Route Table (UDR) attached to the VM's subnet intercepts the `0.0.0.0/0` traffic.
3. The traffic is forwarded to the Private IP of the **Azure Firewall** in the Hub.
4. The Firewall checks its Application/Network rules. If allowed, it SNATs the traffic out to the internet.

### Cross-Environment Traffic (Spoke to Spoke)
1. A VM in `Dev-Spoke` tries to access a database in `Prod-Spoke`.
2. VNet Peering allows the connection, but the Route Table intercepts it.
3. Traffic goes to the **Azure Firewall**.
4. The Firewall denies the traffic by default, preventing accidental cross-contamination between Dev and Prod unless explicitly allowed by an administrator.

## 3. Network Security Groups (NSGs)

While the Azure Firewall handles perimeter and cross-VNet security, **NSGs** handle subnet-level security.
- **Default Deny:** Azure's default NSGs allow all VNet inbound traffic. Our Bicep modules explicitly append a Priority `4096` Deny-All-Inbound rule.
- **Explicit Allow:** Application traffic (like HTTP 80 / HTTPS 443) must be explicitly defined in the Bicep parameters.

## 4. Centralized Observability

All networking components (VNets, Firewalls, NSGs) are configured via Bicep to send their diagnostic logs to a central **Log Analytics Workspace**. 
- This enables **Azure Monitor** and **Microsoft Sentinel** (if enabled later) to cross-reference network flows, identify blocked traffic, and alert on malicious behavior from a single pane of glass.