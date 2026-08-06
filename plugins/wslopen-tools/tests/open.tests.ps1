[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Distro,
    [Parameter(Mandatory)][string]$AllowedRoot
)

$ErrorActionPreference = 'Stop'
trap { Write-Error "$($_.Exception.Message)`n$($_.ScriptStackTrace)"; exit 1 }
$script:Wsl = "$env:SystemRoot\System32\wsl.exe"
$script:AllowedExtensions = @(
    '.doc', '.docx', '.md', '.odt', '.pdf', '.ppt', '.pptx', '.rtf', '.txt',
    '.csv', '.json', '.ods', '.tsv', '.xls', '.xlsx', '.xml', '.yaml', '.yml',
    '.bmp', '.gif', '.jpeg', '.jpg', '.png', '.tif', '.tiff', '.webp',
    '.aac', '.flac', '.m4a', '.m4v', '.mov', '.mp3', '.mp4', '.mpeg', '.mpg',
    '.ogg', '.wav', '.webm', '.wmv'
)

function Assert-Equal([object]$Actual, [object]$Expected, [string]$Message) {
    if ($Actual -cne $Expected) { throw "$Message`nExpected: $Expected`nActual: $Actual" }
}

function Assert-Throws([scriptblock]$Action, [string]$MessagePart) {
    try {
        & $Action
    } catch {
        if ($_.Exception.Message -notlike "*$MessagePart*") { throw "Expected failure containing '$MessagePart', got '$($_.Exception.Message)'." }
        return
    }
    throw "Expected failure containing '$MessagePart'."
}

function Invoke-Wsl([string[]]$Arguments) {
    & $script:Wsl -d $Distro --exec @Arguments
    if ($LASTEXITCODE -ne 0) { throw "wsl.exe failed: $($Arguments -join ' ')" }
}

function New-WslOpenUri([string]$Path) {
    return "wslopen://$Distro$([Uri]::EscapeDataString($Path).Replace('%2F', '/'))"
}

$stage = Join-Path ([IO.Path]::GetTempPath()) "wslopen-open-tests-$([guid]::NewGuid())"
$fixture = "$AllowedRoot/.wslopen-open-tests-$([guid]::NewGuid())"
$sibling = "$AllowedRoot-sibling-$([guid]::NewGuid())"

try {
    New-Item -ItemType Directory -Path $stage | Out-Null
    Copy-Item (Join-Path $PSScriptRoot '../tools/open.ps1') (Join-Path $stage 'open.ps1')
    @{ distro = $Distro; allowedRoot = $AllowedRoot } | ConvertTo-Json | Set-Content (Join-Path $stage 'config.json')
    . (Join-Path $stage 'open.ps1')

    Assert-Throws { Invoke-WslOpenHandler -Arguments @() } 'exactly one'
    Assert-Throws { Invoke-WslOpenHandler -Arguments @('-TargetUri', 'wslopen://Ubuntu/home/alice/notes.md') } 'exactly one'

    Invoke-Wsl @('mkdir', '-p', '--', $fixture)
    $allowedFiles = foreach ($extension in $script:AllowedExtensions) { "$fixture/allowed$extension" }
    Invoke-Wsl (@('touch', '--') + $allowedFiles + @("$fixture/UPPER.MD", "$fixture/space name.md", "$fixture/shell;name.md", "$fixture/no-extension", "$fixture/unlisted.ini", "$fixture/blocked.ps1"))
    Invoke-Wsl @('ln', '-s', '--', "$fixture/allowed.md", "$fixture/in-root-link.md")
    Invoke-Wsl @('ln', '-s', '--', '/etc/passwd', "$fixture/outside-link.md")

    $rootPlan = Get-WslOpenPlan (New-WslOpenUri $fixture)
    Assert-Equal $rootPlan.Kind 'Directory' 'The exact allowed root must create a directory plan.'

    $regularPath = "$fixture/allowed.md"
    $regularPlan = Get-WslOpenPlan (New-WslOpenUri $regularPath)
    Assert-Equal $regularPlan.Kind 'File' 'An allowlisted child file must create a file plan.'

    $linkPlan = Get-WslOpenPlan (New-WslOpenUri "$fixture/in-root-link.md")
    Assert-Equal $linkPlan.Path $regularPlan.Path 'An in-root symlink must resolve to the target UNC path.'

    foreach ($extension in $script:AllowedExtensions) {
        Assert-Equal (Test-AllowedExtension "$fixture/allowed$extension") $true "Allowlisted $extension must be recognized."
    }
    Assert-Equal (Test-AllowedExtension "$fixture/UPPER.MD") $true 'Extensions must be case-insensitive.'
    Assert-Equal (Get-WslOpenPlan (New-WslOpenUri "$fixture/space name.md")).Kind 'File' 'Direct WSL execution must preserve a path with spaces.'
    Assert-Equal (Get-WslOpenPlan (New-WslOpenUri "$fixture/shell;name.md")).Kind 'File' 'Direct WSL execution must preserve shell metacharacters as data.'

    Assert-Throws { Get-WslOpenPlan (New-WslOpenUri "$fixture/outside-link.md") } 'outside'
    Assert-Throws { Get-WslOpenPlan (New-WslOpenUri "$fixture/no-extension") } 'allowlisted'
    Assert-Throws { Get-WslOpenPlan (New-WslOpenUri "$fixture/unlisted.ini") } 'allowlisted'
    Assert-Throws { Get-WslOpenPlan (New-WslOpenUri "$fixture/blocked.ps1") } 'allowlisted'
    Assert-Throws { Get-WslOpenPlan (New-WslOpenUri "$sibling/outside.md") } 'outside'
    Assert-Throws { Get-WslOpenPlan "wslopen://$Distro$([Uri]::EscapeDataString($regularPath).Replace('%2F', '/'))#L42" } 'fragment'
    Assert-Throws { Get-WslOpenPlan "wslopen://$Distro/home/other/%ZZ" } 'Malformed'
    Assert-Throws { Get-WslOpenPlan (New-WslOpenUri $regularPath.Replace('/home/', '/Home/')) } 'outside'

    $candidates = Get-WslUncCandidates $Distro $regularPath
    Assert-Equal $candidates.Count 2 'The handler must expose exactly two ordered UNC candidates.'
    Assert-Equal $candidates[0] "\\wsl.localhost\$Distro$($regularPath.Replace('/', '\'))" 'The localhost UNC candidate must be first.'
    Assert-Equal $candidates[1] "\\wsl`$\$Distro$($regularPath.Replace('/', '\'))" 'The legacy UNC candidate must be second.'
    $existingCandidates = $candidates
    function Test-Path([string]$LiteralPath) { return $existingCandidates -ccontains $LiteralPath }
    try {
        Assert-Equal (Get-ExistingWslUncPath $candidates) $candidates[0] 'The localhost UNC candidate must win when both candidates exist.'
        $existingCandidates = @($candidates[1])
        Assert-Equal (Get-ExistingWslUncPath $candidates) $candidates[1] 'The legacy UNC candidate must be selected when localhost is unavailable.'
        $existingCandidates = @()
        Assert-Throws { Get-ExistingWslUncPath $candidates } 'does not exist'
    } finally {
        Remove-Item function:Test-Path -ErrorAction SilentlyContinue
    }

    @{ distro = $Distro; allowedRoot = "$fixture/allowed.md" } | ConvertTo-Json | Set-Content (Join-Path $stage 'config.json')
    Assert-Throws { Get-WslOpenPlan (New-WslOpenUri "$fixture/quote`"name.md") } 'Malformed'
    foreach ($codePoint in (@(0..31) + @(127..159))) {
        Assert-Throws { Get-WslOpenPlan (New-WslOpenUri "$fixture/control$([char]$codePoint).md") } 'Malformed'
    }
    Assert-Throws { Get-WslOpenPlan "wslopen://other-distro$([Uri]::EscapeDataString($regularPath).Replace('%2F', '/'))" } 'distro'
    Assert-Throws { Get-WslOpenPlan "wslopen://${Distro}:123$([Uri]::EscapeDataString($regularPath).Replace('%2F', '/'))" } 'distro'
    Assert-Throws { Get-WslOpenPlan (New-WslOpenUri $regularPath) } 'configuration'

    'open.tests.ps1 passed'
} finally {
    if (Test-Path -LiteralPath $stage) { Remove-Item -Recurse -Force -LiteralPath $stage }
    & $script:Wsl -d $Distro --exec rm -rf -- $fixture 2>$null
}
