[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Distro,
    [string]$AllowedRoot
)

$ErrorActionPreference = 'Stop'

function Test-SafeDistro([string]$Value) {
    return $Value -match '^[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?$'
}

function Test-ContainsControl([string]$Value) {
    if ($null -eq $Value) { return $false }
    foreach ($character in $Value.ToCharArray()) {
        if ([char]::IsControl($character)) { return $true }
    }
    return $false
}

function Test-SafeLinuxPath([string]$Path) {
    return -not [string]::IsNullOrWhiteSpace($Path) -and
        $Path.StartsWith('/', [StringComparison]::Ordinal) -and
        -not $Path.Contains('\') -and
        -not $Path.Contains('"') -and
        -not (Test-ContainsControl $Path)
}

function Test-CanonicalHomeRoot([string]$Path) {
    if (-not (Test-SafeLinuxPath $Path) -or $Path -notmatch '^/home/[^/]+(?:/[^/]+)*$') { return $false }
    return -not ($Path -split '/' | Where-Object { $_ -eq '.' -or $_ -eq '..' })
}

function Get-WslExecutable {
    $wsl = "$env:SystemRoot\System32\wsl.exe"
    if (-not (Test-Path -LiteralPath $wsl -PathType Leaf)) { throw 'wsl.exe is unavailable.' }
    return $wsl
}

function Resolve-WslPath([string]$TargetDistro, [string]$Path) {
    $lines = @(& (Get-WslExecutable) -d $TargetDistro --exec readlink -f -- $Path 2>$null)
    if ($LASTEXITCODE -ne 0 -or $lines.Count -ne 1) { throw 'Allowed root does not exist.' }

    $resolved = [string]$lines[0]
    if (-not (Test-SafeLinuxPath $resolved)) { throw 'Allowed root is malformed.' }
    return $resolved
}

function Test-WslDirectory([string]$TargetDistro, [string]$Path) {
    & (Get-WslExecutable) -d $TargetDistro --exec test -d $Path 2>$null
    return $LASTEXITCODE -eq 0
}

function Get-CanonicalAllowedRoot([string]$TargetDistro, [string]$Root) {
    if (-not (Test-SafeDistro $TargetDistro)) { throw 'Configured distro is invalid.' }
    if (-not (Test-SafeLinuxPath $Root)) { throw 'Allowed root is invalid.' }

    $canonicalRoot = Resolve-WslPath $TargetDistro $Root
    if (-not (Test-WslDirectory $TargetDistro $canonicalRoot)) { throw 'Allowed root must be a directory.' }
    if (-not (Test-CanonicalHomeRoot $canonicalRoot)) { throw 'Allowed root must be a directory under /home/<user>.' }
    return $canonicalRoot
}

function New-RuntimeConfig([string]$TargetDistro, [string]$CanonicalRoot) {
    return [PSCustomObject]@{ distro = $TargetDistro; allowedRoot = $CanonicalRoot }
}

function New-AgentInstructions([string]$TargetDistro, [string]$CanonicalRoot) {
    return @"
wslopen is installed for this Windows user.
Configured WSL distro: $TargetDistro
Allowed WSL root: $CanonicalRoot
The allowed root is a canonical directory equal to /home/<user> or beneath it; it is never /, /home, or a mounted Windows filesystem.
When sharing a path with this user, emit a wslopen Markdown link only when the absolute WSL path equals the allowed root or is beneath it on a slash-segment boundary. Use wslopen://$TargetDistro/<percent-encoded-absolute-WSL-path>, with the absolute path's leading slash forming the slash after the host. Keep line numbers in link text, not the URI. For every other path, use a plain path. Never infer or substitute a different distro or root.
"@.Trim()
}

function New-ProtocolCommand([string]$InstallDirectory) {
    $powerShell = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    $handler = Join-Path $InstallDirectory 'open.ps1'
    return '"{0}" -NoProfile -ExecutionPolicy Bypass -File "{1}" "%1"' -f $powerShell, $handler
}

function Write-GeneratedFile([string]$Path, [string]$Content) {
    $temporaryPath = Join-Path (Split-Path -Parent $Path) ".wslopen-$([guid]::NewGuid()).tmp"
    [IO.File]::WriteAllText($temporaryPath, $Content, (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
}

function Invoke-WslOpenInstall {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Distro,
        [Parameter(Mandatory)][string]$AllowedRoot
    )

    $canonicalRoot = Get-CanonicalAllowedRoot $Distro $AllowedRoot
    $installDirectory = Join-Path $env:LOCALAPPDATA 'wslopen'
    $sourceHandler = Join-Path $PSScriptRoot 'open.ps1'
    $handlerPath = Join-Path $installDirectory 'open.ps1'
    $configPath = Join-Path $installDirectory 'config.json'
    $instructionsPath = Join-Path $installDirectory 'agent-instructions.md'
    $runtimeConfig = New-RuntimeConfig $Distro $canonicalRoot | ConvertTo-Json
    $agentInstructions = New-AgentInstructions $Distro $canonicalRoot
    $registryRoot = 'HKCU:\Software\Classes\wslopen'
    $commandKey = Join-Path $registryRoot 'shell\open\command'
    $command = New-ProtocolCommand $installDirectory

    if (-not (Test-Path -LiteralPath $sourceHandler -PathType Leaf)) { throw 'open.ps1 is missing beside install.ps1.' }

    if ($PSCmdlet.ShouldProcess($installDirectory, 'Create wslopen installation directory')) {
        New-Item -ItemType Directory -Force -Path $installDirectory | Out-Null
    }
    if ($PSCmdlet.ShouldProcess($handlerPath, 'Copy URI handler')) {
        Copy-Item -LiteralPath $sourceHandler -Destination $handlerPath -Force
    }
    if ($PSCmdlet.ShouldProcess($configPath, 'Write runtime configuration')) {
        Write-GeneratedFile $configPath $runtimeConfig
    }
    if ($PSCmdlet.ShouldProcess($instructionsPath, 'Write agent instructions')) {
        Write-GeneratedFile $instructionsPath $agentInstructions
    }
    if ($PSCmdlet.ShouldProcess($commandKey, 'Register wslopen URI protocol')) {
        New-Item -Path $commandKey -Force | Out-Null
        Set-Item -Path $registryRoot -Value 'URL:wslopen Protocol'
        New-ItemProperty -Path $registryRoot -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
        Set-Item -Path $commandKey -Value $command
    }

    Write-Output $agentInstructions
}

if ($MyInvocation.InvocationName -ne '.') {
    $arguments = @{ Distro = $Distro; AllowedRoot = $AllowedRoot }
    if ($WhatIfPreference) { $arguments.WhatIf = $true }
    Invoke-WslOpenInstall @arguments
}
