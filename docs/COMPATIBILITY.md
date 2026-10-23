# Compatibility and reliability status

AppDesk 2.3 is published as a **stable, unsigned release**. Stable is the project's release designation, not universal compatibility certification. The executable targets x64 Windows with .NET Framework 4.8. WinGet is required for WinGet catalogue entries. Internet and the requested Windows elevation are required for real installation/removal operations. Windows application-control can block an unsigned executable or its extracted PowerShell engine; signing admission and runtime review remain pending.

## Evidence recorded on 23 October 2026

| Configuration or scenario | Evidence | Limit |
| --- | --- | --- |
| Windows 11 Pro x64, build 26200 | Native UI opens; embedded engine and report run | One development PC; not every Windows 11 build or policy |
| Microsoft 365 Personal/Family removal | ODT exit 0; target suite ID disappeared | Does not cover every Office edition or damaged installation |
| Standalone OneNote removal | ODT exit 0; no remaining product ID | Not a notebook backup or restore test |
| Office LTSC 2024 Standard x64 installation | ODT exit 0; registry confirms Standard2024Volume, version 16.0.17932.21056 | Activation/licensing and application use were not validated |
| FortiClient VPN fresh installation through AppDesk 2.3 | Automatic full-package download; valid Fortinet signatures; exit 0; installed version 7.4.3.6002; service running; MSI UILevel=2; no installer wizard observed; final report automatically displayed with 1 success/0 failures in 1m14s | User accepted UAC; VPN connection and upgrade were not tested |
| Office Deployment Tool source | Real Microsoft download and valid publisher signature; also used by the successful Office operations | Publisher page format and availability can change |
| Six Office configuration choices | Offline plans, update-channel consistency and conflict tests | Only LTSC Standard was installed in the recorded real test |
| Seven WinGet entries | Silent plans, simulation and previous already-installed outcomes | Fresh installation/upgrade of every entry is not established |
| Windows Server 2022 CI runner | Compile, resource checks, queue simulation, source tests, fault tests and report rendering | CI is not a Windows desktop installation matrix |
| Windows 10 x64 | Intended target, not independently exercised here | Needs a clean-machine validation run |
| ARM64, 32-bit Windows, macOS/Linux | Not validated; x64 executable only | No compatibility claim |

## Reliability controls

- Download into a unique `.part` file and publish the final filename only after a complete non-empty transfer. Failure leaves an existing file intact and removes partial data.
- Retry transient transfer failures up to three attempts, starting again from the beginning. This is not byte-range resume. Unknown download hosts, invalid publisher signatures and unexpected versions are never ignored.
- Hold one named installation-queue mutex across all AppDesk versions using the new engine. A second queue reports a failure rather than installing concurrently. Older AppDesk versions that lack this guard cannot be controlled by it. Simulation uses a separate local mutex.
- Capture PowerShell output/error logs and write a final fatal state for bootstrap failures so they appear in the integrated report.
- Keep Office update channels aligned with the selected installation channel, including PerpetualVL2024 for LTSC 2024.
- Treat reboot-required installer results as pending final verification after reboot rather than immediately failing a registry check. Do not restart automatically.
- Preserve separate confirmation for destructive Office/OneNote removal, keep Visio/Project outside that removal scope, and refuse to force-close Office processes.

## Checks before broad deployment

Run real installs, upgrades and removals on clean Windows 10/11 x64 machines, including existing Office 32-bit, consumer/volume editions, OneNote, offline/proxy networks and reboot-required outcomes. Validate FortiClient against the actual VPN gateway and organisational release policy. Record activation and application-launch results. Complete the runtime security review and trusted signing process. The stable release retains these documented validation limits and does not imply trusted signing.
