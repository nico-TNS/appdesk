# Changelog

## 2.4.0-preview.1

- Show installed and available versions with asynchronous read-only inventory and refresh.
- Prepare update-only queues for installed catalogue applications; preserve supported Office edition/channel and reject absent products before installer IO.
- Save/restore validated application selections without consent or destructive-operation confirmations.
- Retry only explicitly failed applications from the final report, preserving previous attempt settings and requiring a new review.
- Add inventory, selection and update-only regression tests; fix UTF-8 accents in the older GitHub preview title.

## v2.3.0-preview.1 — reliability controls (file version 2.3.0.0)

- Atomic download publication, bounded transient retries and partial-file cleanup.
- Cross-process installation queue guard and captured worker diagnostics.
- Correct Office update-channel configuration and reboot-required detection timing.
- Add transfer/queue/worker fault tests and a compatibility matrix that distinguishes real outcomes from simulation.

## v2.2.1-preview.1 — allow installation after suite removal (file version 2.2.1.0)

- Fix the guard that mistook standalone OneNote for an existing Office suite after removal.
- Include standalone OneNote in the dedicated Office Removal action and support OneNote-only cleanup.
- Offer an explicitly confirmed standalone-OneNote replacement when installing LTSC, per Microsoft's compatibility requirements.
- Preserve different-suite and 32-bit architecture conflict checks; let Microsoft ODT handle standalone-product coexistence.
- Add regression tests for the actual OneNote-only post-removal state and related suite/architecture cases.

## v2.2.0-preview.1 — targeted Office removal (file version 2.2.0.0)

- Separate Office removal action with installed-product detection and a No-default confirmation.
- Use the latest signed Microsoft ODT and remove only confirmed suite product IDs.
- Exclude standalone OneNote, Visio, Project, MSI and Store installations from automated removal.
- Block removal while Office apps run; add an explicit removal result to the integrated report.
- Add negative removal-plan and report tests; no actual Office removal was used for testing.

## v2.1.0-preview.1 — automatic sources and integrated report (file version 2.1.0.0)

- Resolve the current Office Deployment Tool from Microsoft, without reusing old local tools.
- Resolve full FortiClient VPN x64 packages from the official regional portal, verify publisher/version, and prevent automatic downgrades.
- Refresh WinGet once per queue; enable selected-application updates by default.
- Display a final report for success, failure, interruptions and stopping, with details, export and local logs.
- Keep Office edition/architecture conflicts visible rather than silently replacing Office.

## v2.0.0-preview.1 — first unsigned preview (file version 2.0.0.0)

- Native WPF interface and single portable executable.
- Selection of nine applications and six Office editions.
- Per-application activity, queue progress, stopping and local result logs.
- Source and build preparation for an MIT-licensed public repository.
- GitHub Actions build/test workflow and disabled-by-default SignPath production workflow.

Known limitations and test status are on the README. Real installation tests, runtime signing review and SignPath admission remain pending. No signed production release is claimed.
