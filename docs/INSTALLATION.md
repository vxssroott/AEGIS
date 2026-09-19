# AEGIS Installation Guide

AEGIS is a local privacy control plane for Windows.

It provides a command-driven interface for observing, auditing, verifying,
and remediating local privacy and network exposure.

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or newer
- Git
- Administrator privileges for operations that modify protected Windows settings

Some commands only inspect the system and do not require elevation.
Remediation and security-sensitive operations may require an elevated shell.

## Installation

Open PowerShell and clone the repository:

    git clone https://github.com/vxssroott/AEGIS.git "$HOME\AEGIS"

Enter the repository:

    Set-Location "$HOME\AEGIS"

Run the installer:

    .\install.ps1

The installer initializes the AEGIS runtime environment and installs the
global AEGIS launcher.

After installation, a new PowerShell session can use:

    aegis

## First Run

Start with:

    aegis

The bare command displays the available command tree.

Check the installed version:

    aegis version

Check system health:

    aegis status

Run the diagnostic doctor:

    aegis doctor

Run verification:

    aegis verify

Inspect network state:

    aegis network status

Inspect network interfaces:

    aegis network interfaces

Run a privacy exposure audit:

    aegis audit

Run a broader scan:

    aegis scan

## Command Reference

Core commands:

    aegis status
    aegis audit
    aegis scan
    aegis verify
    aegis fix
    aegis lockdown
    aegis report
    aegis history
    aegis doctor
    aegis test
    aegis version
    aegis update
    aegis rollback

Network commands:

    aegis network
    aegis network status
    aegis network inspect
    aegis network interfaces
    aegis network identity
    aegis network fingerprint
    aegis network leaks
    aegis network virtual
    aegis network verify
    aegis network providers

Other command namespaces are exposed by the CLI as capabilities are
implemented.

Use help at any level:

    aegis --help
    aegis help
    aegis network --help

## Administrative Operations

Commands that modify Windows security configuration may require an elevated
PowerShell session.

For example:

    Start-Process powershell -Verb RunAs

Then:

    Set-Location "$HOME\AEGIS"

Do not run remediation commands blindly. AEGIS is designed to observe,
plan, execute, verify, and record meaningful changes.

## Firewall Remediation

Firewall remediation requires administrator privileges and explicit
confirmation.

The supported command requires:

    aegis fix --yes

AEGIS verifies the resulting firewall state after remediation.

## Testing

Run the complete repository test suite:

    aegis test

You can also execute the test scripts directly from PowerShell.

Tests cover the CLI, core functionality, networking, storage, diagnostics,
security, updates, and other implemented subsystems.

## Reports and Runtime Data

AEGIS creates runtime state under the repository data directories.

Examples include:

- reports
- logs
- events
- backups
- diagnostics
- update state
- version state

Runtime-generated data is intentionally excluded from normal Git commits.

## Updating

The update command currently reports update capability status and does not
perform unauthenticated remote upgrades.

Use:

    aegis update

Authenticated release acquisition, signature verification, staging,
post-update validation, and automatic rollback are part of the AEGIS
update architecture and are only enabled when implemented and verified.

## Uninstallation

Use the repository uninstaller:

    .\uninstall.ps1

Review what the uninstaller removes before confirming the operation.

## Troubleshooting

If the global command is not found after installation, open a new PowerShell
session and run:

    aegis

You can inspect the launcher location with:

    Get-Command aegis -All

Run:

    aegis doctor

If a command fails, run:

    aegis status
    aegis doctor
    aegis verify

Then run the complete test suite:

    aegis test

## Security Model

AEGIS is a local control plane.

It does not claim perfect anonymity, perfect untraceability, or guaranteed
erasure from external systems.

Network identity, privacy exposure, and leak detection are based on the
evidence available to the local Windows system and the capabilities that
AEGIS has implemented.

Protected routing, VPN, Tor, proxy, and kill-switch functionality must not
be interpreted as guarantees of anonymity.

## Development

Clone the repository and enter it:

    git clone https://github.com/vxssroott/AEGIS.git "$HOME\AEGIS"
    Set-Location "$HOME\AEGIS"

Run the test suite:

    aegis test

Check repository health:

    aegis doctor

Inspect the working tree:

    git status

## Project Structure

    AEGIS/
    ├── aegis.ps1
    ├── install.ps1
    ├── uninstall.ps1
    ├── src/
    ├── config/
    ├── policies/
    ├── tests/
    ├── docs/
    ├── data/
    ├── logs/
    ├── reports/
    └── versions/

The source tree is organized around the AEGIS control-plane architecture:

    Observe
        ↓
    Decide
        ↓
    Plan
        ↓
    Execute
        ↓
    Verify
        ↓
    Record

## Repository

GitHub:

    https://github.com/vxssroott/AEGIS
