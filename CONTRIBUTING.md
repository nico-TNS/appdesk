# Contributing

Use issues to describe a reproducible problem or propose an application catalog change. Do not post license keys, API tokens, VPN profiles, account credentials or logs containing private information.

Send focused pull requests with a clear description and the results of:

```powershell
.\scripts\Test-Project.ps1
.\scripts\Test-Engine.ps1
.\scripts\Build.ps1
```

These tests must not install applications. Real installation tests belong in a disposable, authorized Windows environment and must be clearly identified in the report.

Contributions are accepted under the MIT license. Contributors must have the right to submit their code and assets. Do not commit application installers, proprietary code, copied product logos, certificates with private keys or credentials. The package-card glyphs and app icon in this repository were drawn for this project; they are not vendor logos.

Changes to the engine, elevation, download verification, source lists, build scripts, workflows, signing policy or artifact configuration require explicit maintainer review. Updating the allowlist requires testing the exact package identity and checking its publisher source. Never weaken integrity checks to make an installation pass.

Pin GitHub Actions by full commit SHA. Review Dependabot updates rather than automatically merging them. Do not run signing workflows from fork PRs or use `pull_request_target` to execute untrusted source.
