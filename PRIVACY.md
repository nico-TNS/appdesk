# Privacy policy

AppDesk has no maintainer-operated backend, analytics endpoint, account system or automatic telemetry. It does not read VPN profiles, saved credentials, browser data or Office keys.

When the user selects installation and confirms it, AppDesk asks WinGet and the selected software publishers to resolve or download packages. Office uses Microsoft’s deployment services. Those external services receive the network requests needed for their operation, such as the client IP address and requested package. Windows signature/certificate verification may also contact certificate-validation services. Their own privacy policies and application licenses apply. No promise is made to disable telemetry inside third-party software.

Session state, installation output, error logs, downloaded deployment tools and the path of a chosen FortiClient package are stored locally under `Documents/AppDesk`. Logs may contain local paths, application versions and installer messages. AppDesk does not upload them to its maintainers. Review and redact logs before manually sharing them in an issue.

Requests made by an installed application after installation are controlled by that application, not by AppDesk. No application is installed, upgraded or removed before the user initiates a queue and grants the necessary Windows authorization.

GitHub Actions and SignPath are development/release services; their processing of public source code, build artifacts and release metadata is separate from AppDesk’s end-user operation. Their published privacy policies apply to repository and signing-service users.
