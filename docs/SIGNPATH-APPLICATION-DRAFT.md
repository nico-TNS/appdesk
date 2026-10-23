# SignPath Foundation application draft

**Draft only. Not submitted.** Replace the pending fields after publishing the project. Do not claim a public release, external users or an operational signing setup before they exist.

## Project

- Name: AppDesk
- Proposed repository: `https://github.com/nico-TNS/appdesk` — not created by this preparation
- Public download/release URL: pending publication
- License: MIT, covering all project-owned source and assets
- Proposed maintainer, reviewer and signing approver: `nico-TNS`
- Applicant’s legal name, contact email and SignPath account: to be supplied privately by the applicant
- MFA status: to be confirmed by the maintainer; not checked by this preparation

## Description

AppDesk is a small Windows desktop application for selecting and installing common workstation applications. Its portable WPF executable embeds our own UI, catalog and PowerShell execution engine. It uses the Windows Package Manager for most packages, the official Office Deployment Tool for Office, and a user-supplied full official FortiClient VPN package. It does not bundle or request signing of those vendors’ binaries.

Users explicitly select applications, accept the relevant terms and authorize the installation queue through Windows UAC. The UI shows progress and per-application results. No unattended task, service or startup persistence is created. Uninstallation instructions are documented. Office licensing, VPN profiles and 3CX accounts remain the user’s responsibility.

## Why signing is requested

The initial unsigned executable was blocked by Windows application-control on the development computer. We want a legitimate, auditable distribution process for the project’s own binary rather than changing users’ security settings. We understand that signing is conditional on your review and is not evidence that every application installation has been audited.

## Track record and current limitations

This is a new project. We do not yet claim an established public reputation, external user base, multiple maintainers or a history of public releases. Repository publication, a documented initial release and GitHub-hosted CI must be completed before this draft is submitted. We understand that a new project may not yet satisfy your reputation requirements.

Local checks cover compilation, declarative UI rendering, silent installation plans, six Office configurations, queue simulation, stopping and dependency-error handling. End-to-end installation testing and production signing are pending. The FortiClient online bootstrapper does not satisfy our silent-install requirements; a full official package is required.

## Runtime and security review disclosure

The current worker extracts our embedded PowerShell engine and starts it with process-scoped `-ExecutionPolicy Bypass`. It does not modify the machine or user execution policy or turn off Windows application-control. We explicitly disclose this implementation for review; we do not assume that a signature on the EXE also signs or authorizes the extracted script. Before production signing, we will resolve any architecture/signing requirements you identify and complete the security review and end-to-end tests described in `SECURITY.md`.

## Build and approval plan

Sources and build scripts are maintained in the same public repository. Build/test workflows run on GitHub-hosted Windows runners. Dependencies are system libraries; no proprietary installer is embedded. GitHub Actions are pinned to full commit SHAs.

The planned signing workflow builds from reviewed `main`, uploads the executable as a GitHub artifact, submits its artifact ID to the SignPath GitHub connector and waits for manual production-policy approval. The artifact configuration restricts the executable name, product, company and version. The workflow is disabled until admission and credentials are configured. The returned signature and publisher must be verified before a maintainer publishes a release.

## Privacy

AppDesk has no maintainer-controlled telemetry endpoint. Its network activity is limited to the package/deployment operations explicitly requested by the user. Local session logs can contain application versions and paths and are not automatically uploaded. The project includes a privacy policy describing publisher services, local files and development/release services.

## Request

Please assess whether this project qualifies for the Foundation program and advise whether additional public maintenance history, reputation evidence, runtime changes or signing controls are required. We do not request that the usual admission or build-origin requirements be waived.

## Submission checklist

- [ ] Public repository and download page exist.
- [ ] Initial source and binary release are published, honestly labeled as unsigned.
- [ ] CI has run successfully on GitHub-hosted runners.
- [ ] Real installation and security tests are recorded.
- [ ] Proposed roles, ownership, contact details and MFA are confirmed.
- [ ] Runtime PowerShell/signing design has been reviewed and any required changes resolved.
- [ ] Remaining limitations and the project’s actual reputation are disclosed.
- [ ] The maintainer has read the current Foundation conditions.
