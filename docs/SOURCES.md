# Automatic publisher sources

AppDesk resolves versions at the start of each requested installation. It does not run an updater in the background.

| Application | Source and version policy |
| --- | --- |
| Seven WinGet entries | Refresh the named `winget` source once per queue, then resolve the package without pinning a version. Failure to refresh is reported rather than silently using stale data. |
| Office Deployment Tool | Parse the current EXE link on Microsoft's [Download Center page](https://www.microsoft.com/en-us/download/details.aspx?id=49117), download it from `download.microsoft.com`, and require a valid Microsoft Authenticode signature before extraction. An old Nextcloud setup file is no longer used. |
| Office application files | ODT downloads the latest available version for the selected product/channel from Microsoft. No `Version` or local `SourcePath` is pinned. Office LTSC 2024 stays on `PerpetualVL2024`; selecting a different edition does not uninstall an existing edition. |
| FortiClient VPN x64 | Select the highest four-part VPN-only x64 version linked by the [official Fortinet regional download page](https://support.fortinet.com.cn/vpn/forticlient_vpn/fct_download). This regional service currently hosts full installers in its Fortinet-named Amazon S3 China bucket. Require a valid Fortinet signature, a full-size package and matching embedded version before execution. |

Fortinet's [global Windows VPN link](https://links.fortinet.com/forticlient/win/vpnagent) currently supplies an online bootstrapper, not the full silent installer. The regional release can lag or differ from the global channel: “latest” means the latest full VPN-only x64 package published on this specific official page, not every release available to authenticated Fortinet customers. Regional availability and connectivity can vary. AppDesk does not fall back to unofficial mirrors or run an interactive bootstrapper. A missing/changed source causes a visible error and the optional manual package selector remains available.

By default, updates to selected existing applications are enabled. Unchecking the update box preserves existing applications. AppDesk never automatically downgrades an installed FortiClient to an older regional version. Manual FortiClient selection is explicit and valid for the current session; use **Automatique** to restore online resolution.

Publisher pages and HTTPS redirect hosts are allowlisted. TLS/certificate validation remains enabled. HTML is parsed as data, not evaluated as scripts or commands. Source URL, advertised version and SHA-256 of verified Office/Fortinet downloads are recorded in the local `sources.jsonl` and exported report. Dynamic download checks rely on a trusted publisher signature rather than an obsolete hard-coded SHA-256. WinGet performs its package manifest integrity checks.

An integrated report opens after completion, errors or stopping. It lists each queued application, its result, error details and exit code, including unprocessed applications. A plain-text copy is saved in the session directory and can be exported from the report view. Reopening a saved session with `--report-session <session-directory>` only reads its results and never starts an installation.

## Office removal

**Office Removal — Office + OneNote…** is a separate action, including OneNote-only cleanup. It detects compatible Office Click-to-Run suite IDs, displays the products to remove and requires explicit confirmation before UAC. The current signed Microsoft ODT is used with targeted `<Remove All="FALSE"><Product ID="..." /></Remove>` entries. No `Add`, `RemoveMSI` or blanket `Remove All="TRUE"` is generated. The removal allowlist includes Office suite IDs and OneNoteFreeRetail. Visio and Project remain excluded. Windows MSI/Store installations are not removed by this action; use Windows installed-apps settings for those.

The engine checks the confirmed targets against the installed suite IDs again before removal, refuses to proceed while Office apps are running, does not force-close processes or restart the PC, and checks for remaining targeted IDs after a successful non-reboot result. A removal-specific final report is generated. It does not reinstall another edition automatically, cancel subscriptions or explicitly delete personal documents. Keep your license/account available for a later reinstall. Plan/simulation tests do not establish a successful real uninstall on every supported Office product.

Microsoft documents [targeted ODT removal](https://learn.microsoft.com/en-us/microsoft-365-apps/deploy/office-deployment-tool-configuration-options#remove-element). Its separate Get Help uninstall troubleshooter does not currently support Office 2024, so AppDesk does not depend on that troubleshooter.

Source-resolution and download-signature checks are distinct from real installation tests. No promise is made that all VPN configurations or every future publisher package remain compatible or fully silent.

Preview 2.3 uses unique partial files and up to three attempts for transient binary-transfer errors. Retries start again from the beginning; an interrupted transfer is not resumed by byte range. A failed transfer cannot replace an existing file. The installation queue is guarded against overlap with other new AppDesk engines. See the [compatibility matrix](COMPATIBILITY.md) for actual evidence and pending validation.

When standalone OneNote remains before an LTSC installation, AppDesk requires separate confirmation to replace it with the OneNote included in LTSC; without confirmation it never adds a OneNote removal to the install configuration. See Microsoft OneNote deployment guidance: https://learn.microsoft.com/en-us/deployoffice/deployment-guide-onenote
