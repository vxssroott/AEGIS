$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")

$required = @(
    "README.md",
    "docs\INSTALLATION.md",
    "install.ps1",
    "uninstall.ps1",
    "aegis.ps1"
)

foreach ($relative in $required) {
    $path = Join-Path $root $relative

    if (-not (Test-Path $path)) {
        throw "Missing required documentation/install file: $relative"
    }

    $content = Get-Content $path -Raw

    if ([string]::IsNullOrWhiteSpace($content)) {
        throw "File is empty: $relative"
    }

    Write-Host "[PASS] $relative"
}

$guide = Get-Content (Join-Path $root "docs\INSTALLATION.md") -Raw

$requiredSections = @(
    "# AEGIS Installation Guide",
    "## Requirements",
    "## Installation",
    "## First Run",
    "## Command Reference",
    "## Administrative Operations",
    "## Testing",
    "## Troubleshooting",
    "## Security Model",
    "## Development"
)

foreach ($section in $requiredSections) {
    if ($guide -notmatch [regex]::Escape($section)) {
        throw "Installation guide is missing section: $section"
    }

    Write-Host "[PASS] Installation guide section: $section"
}

if ($guide -notmatch 'github\.com/vxssroott/AEGIS') {
    throw "Installation guide is missing the repository URL."
}

Write-Host "[PASS] Repository URL documented."
Write-Host "[PASS] Documentation validation complete."
