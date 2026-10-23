# Security policy

## Reporting

After the repository is public, use its private GitHub **Report a vulnerability** feature when enabled. If unavailable, contact the maintainer via the public GitHub profile to arrange a private report. Do not post exploit details or secrets in a public issue. No response-time commitment or independent audit is claimed for this initial project.

Only the current maintained release is intended to receive fixes. Version 2.0 is currently a pre-release candidate; production signing and full installation tests are pending.

## Runtime model

The UI runs without elevation. A confirmed queue requests UAC authorization for a second instance of the same executable, which runs the embedded PowerShell engine and source resolver. Catalog IDs, publisher pages and download/redirect hosts are allowlisted. Dynamically resolved Fortinet and Microsoft tools require valid publisher signatures before execution; their computed SHA-256 values are recorded as provenance, not mistaken for an independently trusted checksum. Fortinet embedded versions must match the official page. WinGet handles integrity checks for its own packages. See [source policy](docs/SOURCES.md).

The engine is extracted into a local session directory. The current implementation starts Windows PowerShell with a process-scoped `-ExecutionPolicy Bypass` for that embedded engine. It does not change the machine/user execution policy or disable application-control, Defender, Smart App Control or certificate validation. **This design must be explicitly reviewed during SignPath admission.** An EXE signature does not automatically sign its extracted script or prove that every downstream host policy permits it. If the provider requires independently signed runtime scripts or a native engine, implement and validate that requirement before a production release. No workaround to a Windows block is provided.

Session files and package paths are local to the interactive user. The current design is not claimed to provide a security boundary against malware already running as that user. Review job-file/path handling, the WinGet launcher selection and the extraction/elevation boundary before endorsing a signed production build. Do not silently broaden package sources or launch arbitrary commands from a downloaded catalog.

## Release controls

Only the repository-built AppDesk artifact is eligible for signing. Do not submit third-party installers or manually replaced binaries. Treat signing tokens, production environments, release approvals and action updates as sensitive. Use MFA and revoke exposed tokens. Signed artifacts must be checked after download; no signature is presently supplied with this preparation.

Known functional limits, including the full-package requirement for FortiClient, are documented on the README. Tests so far cover compilation, plans, simulation and UI design; they do not establish end-to-end installation safety or compatibility.
