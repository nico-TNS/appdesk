# Release checklist

## Source and build

- [ ] Review source, release version and package-source changes on protected `main`.
- [ ] Check the MIT license, notices, security and privacy policies.
- [ ] Run project checks, engine simulations and compilation.
- [ ] Obtain a successful GitHub-hosted build and embedded-resource smoke test.
- [ ] Test installations, failures, UAC cancellation, existing software and reboot-required results in an authorized test environment.
- [ ] Test on a clean Windows profile and verify uninstall instructions.

## Candidate status

- [ ] Resolve the extracted PowerShell/signing design review before claiming compatibility with a protected target PC.
- [ ] Record unresolved restrictions, including package prerequisites and Office licenses.
- [ ] Label unsigned candidates clearly; do not suggest disabling application-control to run them.
- [ ] Attach only the project-built executable and its matching checksum. Do not attach vendor installers or private session logs.

## After SignPath admission

- [ ] Confirm owner roles, MFA, environment protections and manual SignPath approval.
- [ ] Submit only the workflow-built owned artifact.
- [ ] Check the returned signature, expected publisher and version; regenerate checksums after signing.
- [ ] Test the signed candidate’s full runtime behavior before publication.
- [ ] Add the required sponsorship credit only while the sponsorship is actually active.
- [ ] Publish reviewed release notes with test evidence and known limitations.
