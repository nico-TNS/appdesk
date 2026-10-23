# Third-party materials and software

The C# code, PowerShell engine, XAML layout, project icon and letter-based package cards in this repository are provided under the MIT license in `LICENSE`.

AppDesk depends on Windows, .NET Framework, Windows PowerShell and WinGet already present on the user’s system. These system components are not copied into this repository or redistributed inside AppDesk.

The application references third-party package IDs and official download URLs. Chrome, Firefox, Opera, Acrobat Reader, WireGuard, FortiClient VPN, OpenVPN, 3CX, Microsoft Office and their installers retain their respective publisher licenses and trademarks. They are not part of AppDesk’s source license, not bundled in its binary and not submitted for signature under AppDesk’s identity. Office activation and other vendor entitlements remain the user’s responsibility.

GitHub Actions used by the workflows are external build tools pinned by commit. Their licenses and notices remain in their upstream repositories: `actions/checkout`, `actions/upload-artifact` and `signpath/github-action-submit-signing-request`. No copies of those tools are vendored here.
