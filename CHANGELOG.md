# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned / Roadmap
- **Key Vault Integration:** Add a central Azure Key Vault module in the Hub for secret management.
- **Private DNS Zones:** Integrate Azure Private DNS for PaaS services to enable Private Endpoints.
- **Azure Backup:** Add recovery services vault modules to enforce automated VM backups.
- **Sentinel Onboarding:** Enable Microsoft Sentinel on top of the Log Analytics Workspace for SIEM capabilities.
- **GitHub Actions OIDC:** Implement OpenID Connect (OIDC) authentication for passwordless GitHub Actions deployments to Azure.

## [1.0.0] - 2026-04-28

### Added
- Initial release of the SMB Azure Landing Zone portfolio project.
- Complete Hub-and-Spoke Bicep modules.
- Azure Firewall, VPN Gateway, and Azure Bastion integration.
- Zero-trust Network Security Groups (NSGs).
- Azure Policy for tag and location governance.
- Entra ID RBAC framework module.
- Comprehensive Markdown documentation (Architecture, Cost Optimization, Governance, Implementation, RBAC).
- GitHub Actions CI/CD validation workflow.
- Bash helper scripts (`deploy.sh`, `cleanup.sh`).