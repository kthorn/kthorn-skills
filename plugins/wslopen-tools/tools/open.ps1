$ErrorActionPreference = 'Stop'
$script:AllowedExtensions = @(
    '.doc', '.docx', '.md', '.odt', '.pdf', '.ppt', '.pptx', '.rtf', '.txt',
    '.csv', '.json', '.ods', '.tsv', '.xls', '.xlsx', '.xml', '.yaml', '.yml',
    '.bmp', '.gif', '.jpeg', '.jpg', '.png', '.tif', '.tiff', '.webp',
    '.aac', '.flac', '.m4a', '.m4v', '.mov', '.mp3', '.mp4', '.mpeg', '.mpg',
    '.ogg', '.wav', '.webm', '.wmv'
)

function Test-SafeDistro([string]$Distro) {
    return $Distro -match '^[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?$'
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

function Test-PathWithinRoot([string]$Path, [string]$Root) {
    return $Path -ceq $Root -or $Path.StartsWith("$Root/", [StringComparison]::Ordinal)
}

function Get-WslExecutable {
    $wsl = "$env:SystemRoot\System32\wsl.exe"
    if (-not (Test-Path -LiteralPath $wsl -PathType Leaf)) { throw 'wsl.exe is unavailable.' }
    return $wsl
}

function Resolve-WslPath([string]$Distro, [string]$Path) {
    $lines = @(& (Get-WslExecutable) -d $Distro --exec readlink -f -- $Path 2>$null)
    if ($LASTEXITCODE -ne 0 -or $lines.Count -ne 1) { throw 'The target path does not exist.' }

    $resolved = [string]$lines[0]
    if (-not (Test-SafeLinuxPath $resolved)) { throw 'Malformed WSL resolver output.' }
    return $resolved
}

function Test-WslDirectory([string]$Distro, [string]$Path) {
    & (Get-WslExecutable) -d $Distro --exec test -d $Path 2>$null
    return $LASTEXITCODE -eq 0
}

function Get-WslOpenConfig {
    $configPath = Join-Path $PSScriptRoot 'config.json'
    try {
        $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    } catch {
        throw 'Invalid wslopen configuration.'
    }

    $distro = [string]$config.distro
    $allowedRoot = [string]$config.allowedRoot
    if (-not (Test-SafeDistro $distro) -or -not (Test-CanonicalHomeRoot $allowedRoot)) {
        throw 'Invalid wslopen configuration.'
    }

    return [PSCustomObject]@{ Distro = $distro; AllowedRoot = $allowedRoot }
}

function Assert-WslOpenConfig([PSCustomObject]$Config) {
    $canonicalRoot = Resolve-WslPath $Config.Distro $Config.AllowedRoot
    if ($canonicalRoot -cne $Config.AllowedRoot -or -not (Test-WslDirectory $Config.Distro $canonicalRoot)) {
        throw 'Invalid wslopen configuration.'
    }
}

function Get-WslUncCandidates([string]$Distro, [string]$Path) {
    $windowsPath = $Path.Replace('/', '\')
    return @(
        ('\\wsl.localhost\{0}{1}' -f $Distro, $windowsPath),
        ('\\wsl$\{0}{1}' -f $Distro, $windowsPath)
    )
}

function Get-ExistingWslUncPath([string[]]$Candidates) {
    foreach ($uncPath in $Candidates) {
        if (Test-Path -LiteralPath $uncPath) { return $uncPath }
    }
    throw 'The target path does not exist.'
}

function Test-AllowedExtension([string]$Path) {
    return $script:AllowedExtensions -contains [IO.Path]::GetExtension($Path).ToLowerInvariant()
}

function Get-WslOpenPlan([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value.Contains('\') -or (Test-ContainsControl $Value)) {
        throw 'Malformed wslopen URI.'
    }
    if ($Value -match '%(?![0-9A-Fa-f]{2})') { throw 'Malformed URI escaping.' }

    try {
        $uri = [Uri]::new($Value, [UriKind]::Absolute)
    } catch {
        throw 'Malformed wslopen URI.'
    }

    if ($uri.Scheme -cne 'wslopen') { throw 'Only the wslopen scheme is allowed.' }
    if (-not $uri.IsDefaultPort) { throw 'The URI distro is not allowed.' }
    if ($uri.UserInfo) { throw 'URI credentials are not allowed.' }
    if ($uri.Query) { throw 'URI query strings are not allowed.' }
    if ($uri.Fragment) { throw 'URI fragments are not allowed.' }
    if ($uri.AbsolutePath -match '%(?![0-9A-Fa-f]{2})') { throw 'Malformed URI escaping.' }

    try {
        $path = [Uri]::UnescapeDataString($uri.AbsolutePath)
    } catch {
        throw 'Malformed URI escaping.'
    }
    if (-not (Test-SafeLinuxPath $path)) { throw 'Malformed WSL path.' }

    $config = Get-WslOpenConfig
    if (-not [string]::Equals($uri.Host, $config.Distro, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The URI distro is not allowed.'
    }
    Assert-WslOpenConfig $config
    if (-not (Test-PathWithinRoot $path $config.AllowedRoot)) { throw 'The path is outside the allowed root.' }

    $resolved = Resolve-WslPath $config.Distro $path
    if (-not (Test-PathWithinRoot $resolved $config.AllowedRoot)) { throw 'The resolved path is outside the allowed root.' }

    $uncPath = Get-ExistingWslUncPath (Get-WslUncCandidates $config.Distro $resolved)
    $item = Get-Item -LiteralPath $uncPath -Force
    if ($item.PSIsContainer) {
        return [PSCustomObject]@{ Kind = 'Directory'; Path = $uncPath }
    }

    if (-not (Test-AllowedExtension $uncPath)) { throw 'File type is not allowlisted.' }
    return [PSCustomObject]@{ Kind = 'File'; Path = $uncPath }
}

function Invoke-WslOpen([PSCustomObject]$Plan) {
    if ($Plan.Kind -eq 'Directory') {
        Start-Process -FilePath explorer.exe -ArgumentList ('"{0}"' -f $Plan.Path)
        return
    }
    Start-Process -FilePath $Plan.Path
}

function Get-OnlyUriArgument([string[]]$Values) {
    if ($Values.Count -ne 1 -or [string]::IsNullOrWhiteSpace($Values[0])) {
        throw 'Expected exactly one wslopen URI argument.'
    }
    return $Values[0]
}

function Invoke-WslOpenHandler([string[]]$Arguments) {
    Invoke-WslOpen (Get-WslOpenPlan (Get-OnlyUriArgument $Arguments))
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        Invoke-WslOpenHandler $args
    } catch {
        Add-Type -AssemblyName System.Windows.Forms
        [void][System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            'wslopen',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        exit 1
    }
}
