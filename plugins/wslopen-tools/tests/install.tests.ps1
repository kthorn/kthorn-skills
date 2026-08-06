[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Distro,
    [Parameter(Mandatory)][string]$AllowedRoot
)

$ErrorActionPreference = 'Stop'
trap { Write-Error $_; exit 1 }

function Assert-Equal([object]$Actual, [object]$Expected, [string]$Message) {
    if ($Actual -cne $Expected) { throw "$Message`nExpected: $Expected`nActual: $Actual" }
}

function Assert-Throws([scriptblock]$Action, [string]$MessagePart) {
    try {
        & $Action
    } catch {
        if ($_.Exception.Message -notlike "*$MessagePart*") { throw }
        return
    }
    throw "Expected failure containing '$MessagePart'."
}

$configuredDistro = $Distro
$configuredRoot = $AllowedRoot
. (Join-Path $PSScriptRoot '../tools/install.ps1')

$canonicalRoot = Get-CanonicalAllowedRoot $configuredDistro $configuredRoot
Assert-Equal $canonicalRoot $configuredRoot 'The supplied test root must already be canonical.'
Assert-Throws { Get-CanonicalAllowedRoot $configuredDistro '/' } 'under /home'
Assert-Throws { Get-CanonicalAllowedRoot $configuredDistro '/home' } 'under /home'
Assert-Throws { Get-CanonicalAllowedRoot $configuredDistro '/etc' } 'under /home'
Assert-Throws { Get-CanonicalAllowedRoot $configuredDistro '/etc/passwd' } 'directory'
Assert-Throws { Get-CanonicalAllowedRoot $configuredDistro "$configuredRoot/quote`"name" } 'invalid'
Assert-Throws { Get-CanonicalAllowedRoot $configuredDistro "$configuredRoot/tab`tname" } 'invalid'

$config = New-RuntimeConfig $configuredDistro $canonicalRoot
Assert-Equal $config.distro $configuredDistro 'Runtime configuration must preserve the configured distro.'
Assert-Equal $config.allowedRoot $canonicalRoot 'Runtime configuration must preserve the canonical root.'

$expectedInstructions = @"
wslopen is installed for this Windows user.
Configured WSL distro: $configuredDistro
Allowed WSL root: $canonicalRoot
The allowed root is a canonical directory equal to /home/<user> or beneath it; it is never /, /home, or a mounted Windows filesystem.
When sharing a path with this user, emit a wslopen Markdown link only when the absolute WSL path equals the allowed root or is beneath it on a slash-segment boundary. Use wslopen://$configuredDistro/<percent-encoded-absolute-WSL-path>, with the absolute path's leading slash forming the slash after the host. Keep line numbers in link text, not the URI. For every other path, use a plain path. Never infer or substitute a different distro or root.
"@.Trim()
Assert-Equal (New-AgentInstructions $configuredDistro $canonicalRoot) $expectedInstructions 'Generated agent instructions must be exact.'

$installDirectory = 'C:\Users\Example\AppData\Local\wslopen'
$expectedCommand = '"{0}\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Example\AppData\Local\wslopen\open.ps1" "%1"' -f $env:SystemRoot
Assert-Equal (New-ProtocolCommand $installDirectory) $expectedCommand 'The protocol command must be quoted and pass one URI argument.'

$script:PersistentWriteAttempted = $false
$originalWriteGeneratedFile = ${function:Write-GeneratedFile}
function global:Copy-Item { $script:PersistentWriteAttempted = $true; throw 'Copy-Item must not run under -WhatIf.' }
function global:New-Item { $script:PersistentWriteAttempted = $true; throw 'New-Item must not run under -WhatIf.' }
function global:New-ItemProperty { $script:PersistentWriteAttempted = $true; throw 'New-ItemProperty must not run under -WhatIf.' }
function global:Set-Item { $script:PersistentWriteAttempted = $true; throw 'Set-Item must not run under -WhatIf.' }
function Write-GeneratedFile { $script:PersistentWriteAttempted = $true; throw 'Write-GeneratedFile must not run under -WhatIf.' }

try {
    Invoke-WslOpenInstall -Distro $configuredDistro -AllowedRoot $canonicalRoot -WhatIf
} finally {
    Remove-Item function:global:Copy-Item -ErrorAction SilentlyContinue
    Remove-Item function:global:New-Item -ErrorAction SilentlyContinue
    Remove-Item function:global:New-ItemProperty -ErrorAction SilentlyContinue
    Remove-Item function:global:Set-Item -ErrorAction SilentlyContinue
    Microsoft.PowerShell.Management\Set-Item function:Write-GeneratedFile $originalWriteGeneratedFile
}
if ($script:PersistentWriteAttempted) { throw 'A persistent write function ran under -WhatIf.' }

'install.tests.ps1 passed'
