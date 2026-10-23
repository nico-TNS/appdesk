# Code signing policy

## Current status

AppDesk is preparing an application to SignPath Foundation. No application has been submitted, no certificate has been granted, and no release is represented as signed by SignPath. The production signing workflow is disabled until explicitly configured following acceptance.

The following acknowledgment is conditional on acceptance and must become an active credit on the README and release download pages only after sponsorship starts:

> Free code signing provided by [SignPath.io](https://about.signpath.io), certificate by [SignPath Foundation](https://signpath.org).

## Ownership and roles

The intended repository owner, author, reviewer and release approver is [@nico-TNS](https://github.com/nico-TNS), subject to confirmation before publication. There is presently one proposed maintainer; an independent reviewer is not claimed. Changes from external contributors require maintainer review. See [MAINTAINERS.md](MAINTAINERS.md).

All maintainers must enable MFA on GitHub and SignPath before production signing. This preparation has not checked their account settings and does not attest that MFA or repository protections are already enabled.

## Eligible artifacts

Only `MonInstallateur.exe`, built from this repository’s reviewed sources on a GitHub-hosted Windows runner, may be submitted. Do not sign third-party application installers, locally uploaded replacement binaries, unreviewed PR artifacts or arbitrary workflow inputs.

The executable embeds our PowerShell engine and XAML interface. Both are maintained here and covered by the MIT license. Proprietary applications and their installers are not bundled or submitted to SignPath. The runtime model and open review issues are documented in [SECURITY.md](SECURITY.md).

## Production process

1. Review source changes, license provenance, tests and release metadata on the protected `main` branch.
2. Run the manual `SignPath production` workflow from `main` after admission and configuration.
3. GitHub builds, tests and uploads the unsigned executable as a workflow artifact. SignPath verifies its GitHub origin through its connector.
4. Submit the request with the designated production policy. A maintainer must manually approve it in SignPath. Configure the GitHub production environment to require approval too where available.
5. Download the signed result, verify Authenticode and expected publisher, and upload it as a **signed** workflow artifact.
6. A maintainer verifies installation behavior in an authorized test environment, prepares release notes and publishes the release. Uploading an artifact is not an automatic public release.

The workflow uses commit-pinned actions and minimum repository permissions. Signing credentials belong only in the production environment’s secrets. Do not provide production secrets to PR workflows. The signing workflow fails if its required settings are missing, and remains skipped while `SIGNPATH_ENABLED` is not `true`.

## Privacy and revocation

AppDesk does not send application telemetry to its maintainers. Installation explicitly contacts package sources and publishers; see [PRIVACY.md](PRIVACY.md). To report a suspected malicious or compromised release, follow [SECURITY.md](SECURITY.md). Suspend signing and investigate provenance before issuing any replacement release.

## Admission is pending

Public source alone does not guarantee acceptance. SignPath considers reputation, release history and verifiable builds, among other conditions. A new project must describe its actual track record honestly. This policy is an operating plan, not a statement that branch protection, environment approval, SignPath approval or sponsorship is already active.
