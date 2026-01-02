[CmdletBinding(DefaultParameterSetName = "Bump")]
param(
  [Parameter(Mandatory = $true, ParameterSetName = "Bump")]
  [ValidateSet("minor", "major")]
  [string]$Bump,

  [Parameter(Mandatory = $true, ParameterSetName = "UseCurrent")]
  [switch]$UseCurrentVersion,

  [string]$ApiKey = $env:NUGET_API_KEY,

  [string]$Source = "https://api.nuget.org/v3/index.json",

  [switch]$SkipPush
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-RepoRoot {
  return $PSScriptRoot
}

function Get-VersionFromPropsFile {
  param([Parameter(Mandatory = $true)][string]$PropsPath)

  $text = Get-Content -Path $PropsPath -Raw
  $match = [regex]::Match($text, "<Version>(?<version>[^<]+)</Version>")
  if (-not $match.Success) {
    throw "Could not find <Version> in $PropsPath"
  }

  return $match.Groups["version"].Value.Trim()
}

function Get-BumpedVersion {
  param(
    [Parameter(Mandatory = $true)][string]$CurrentVersion,
    [Parameter(Mandatory = $true)][ValidateSet("minor", "major")][string]$Bump
  )

  if ($CurrentVersion -notmatch "^(\d+)\.(\d+)\.(\d+)$") {
    throw "Unsupported version format '$CurrentVersion'. Expected 'major.minor.patch'."
  }

  $major = [int]$Matches[1]
  $minor = [int]$Matches[2]
  $patch = [int]$Matches[3]

  switch ($Bump) {
    "minor" {
      $minor++
      $patch = 0
    }
    "major" {
      $major++
      $minor = 0
      $patch = 0
    }
  }

  return "$major.$minor.$patch"
}

function Set-VersionInPropsFile {
  param(
    [Parameter(Mandatory = $true)][string]$PropsPath,
    [Parameter(Mandatory = $true)][string]$Version
  )

  $assemblyAndFileVersion = "$Version.0"

  $text = Get-Content -Path $PropsPath -Raw
  $text = $text -replace "<Version>[^<]+</Version>", "<Version>$Version</Version>"

  if ($text -match "<AssemblyVersion>[^<]+</AssemblyVersion>") {
    $text = $text -replace "<AssemblyVersion>[^<]+</AssemblyVersion>", "<AssemblyVersion>$assemblyAndFileVersion</AssemblyVersion>"
  }

  if ($text -match "<FileVersion>[^<]+</FileVersion>") {
    $text = $text -replace "<FileVersion>[^<]+</FileVersion>", "<FileVersion>$assemblyAndFileVersion</FileVersion>"
  }

  Set-Content -Path $PropsPath -Value $text -Encoding utf8
}

function Get-PackTarget {
  param([Parameter(Mandatory = $true)][string]$RepoRoot)

  $slnFiles = @(Get-ChildItem -Path $RepoRoot -Filter "*.sln" -File -ErrorAction SilentlyContinue)
  if ($slnFiles.Count -eq 1) {
    return $slnFiles[0].FullName
  }

  $srcPath = Join-Path $RepoRoot "src"
  if (-not (Test-Path $srcPath)) {
    throw "Could not find a single *.sln in $RepoRoot and '$srcPath' does not exist."
  }

  $csprojFiles = @(
    Get-ChildItem -Path $srcPath -Recurse -Filter "*.csproj" -File |
    Where-Object { $_.FullName -notmatch "\\\\(bin|obj)\\\\" }
  )

  if ($csprojFiles.Count -eq 1) {
    return $csprojFiles[0].FullName
  }

  if ($csprojFiles.Count -eq 0) {
    throw "No .csproj files found under $srcPath"
  }

  $csprojList = ($csprojFiles | ForEach-Object { $_.FullName }) -join "`n"
  throw "Multiple .csproj files found under $srcPath. Specify a single pack target manually.`n$csprojList"
}

function Invoke-DotNet {
  param(
    [Parameter(Mandatory = $true)][string[]]$Args
  )

  $displayArgs = @($Args)
  for ($i = 0; $i -lt $displayArgs.Count; $i++) {
    if ($displayArgs[$i] -in @("--api-key", "-k")) {
      if ($i + 1 -lt $displayArgs.Count) {
        $displayArgs[$i + 1] = "***"
      }
    }
  }

  Write-Host ("dotnet " + ($displayArgs -join " "))
  & dotnet @Args
  if ($LASTEXITCODE -ne 0) {
    throw "dotnet command failed (exit code $LASTEXITCODE): dotnet $($displayArgs -join ' ')"
  }
}

$repoRoot = Get-RepoRoot
$propsPath = Join-Path $repoRoot "Directory.Build.props"
if (-not (Test-Path $propsPath)) {
  throw "Missing file: $propsPath"
}

$propsOriginalText = Get-Content -Path $propsPath -Raw

$currentVersion = Get-VersionFromPropsFile -PropsPath $propsPath
$targetVersion = $currentVersion
$shouldUpdateVersionInPropsFile = $false

switch ($PSCmdlet.ParameterSetName) {
  "Bump" {
    $targetVersion = Get-BumpedVersion -CurrentVersion $currentVersion -Bump $Bump
    $shouldUpdateVersionInPropsFile = $true
  }
  "UseCurrent" {
    $targetVersion = $currentVersion
    $shouldUpdateVersionInPropsFile = $false
  }
  default {
    throw "Unexpected parameter set: $($PSCmdlet.ParameterSetName)"
  }
}

Write-Host "Repo: $repoRoot"
Write-Host "Version: $currentVersion -> $targetVersion"

if ($shouldUpdateVersionInPropsFile) {
  Set-VersionInPropsFile -PropsPath $propsPath -Version $targetVersion
}

try {
  if ($ApiKey -and $ApiKey -match "-Bump") {
    throw "Your -ApiKey value contains '-Bump'. Check your command formatting (missing space) and try: .\\publish-nuget.ps1 -Bump minor -ApiKey YOUR_KEY"
  }

  $packTarget = Get-PackTarget -RepoRoot $repoRoot
  $artifactsDir = Join-Path $repoRoot "artifacts"
  New-Item -ItemType Directory -Force -Path $artifactsDir | Out-Null

  Invoke-DotNet -Args @("restore", $packTarget)
  Invoke-DotNet -Args @("build", $packTarget, "-c", "Release", "--no-restore")
  Invoke-DotNet -Args @("pack", $packTarget, "-c", "Release", "-o", $artifactsDir, "--no-build", "/p:ContinuousIntegrationBuild=true")

  $nupkgs = @(
    Get-ChildItem -Path $artifactsDir -Filter "*.$targetVersion.nupkg" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notlike "*.symbols.nupkg" }
  )

  $snupkgs = @(Get-ChildItem -Path $artifactsDir -Filter "*.$targetVersion.snupkg" -File -ErrorAction SilentlyContinue)

  if ($nupkgs.Count -eq 0) {
    throw "No .nupkg files found for version $targetVersion under $artifactsDir"
  }

  Write-Host "Artifacts:"
  $nupkgs | ForEach-Object { Write-Host "  - $($_.Name)" }
  $snupkgs | ForEach-Object { Write-Host "  - $($_.Name)" }

  if ($SkipPush) {
    Write-Host "SkipPush enabled; not publishing to $Source"
    exit 0
  }

  if (-not $ApiKey) {
    throw "Missing NuGet API key. Set NUGET_API_KEY env var or pass -ApiKey."
  }

  foreach ($pkg in $nupkgs) {
    Invoke-DotNet -Args @("nuget", "push", $pkg.FullName, "--api-key", $ApiKey, "--source", $Source, "--skip-duplicate")
  }

  foreach ($pkg in $snupkgs) {
    try {
      Invoke-DotNet -Args @("nuget", "push", $pkg.FullName, "--api-key", $ApiKey, "--source", $Source, "--skip-duplicate")
    }
    catch {
      Write-Warning "Symbol push failed for '$($pkg.Name)'. The main package may already be published. Details: $($_.Exception.Message)"
    }
  }

  Write-Host "Done."
}
catch {
  if ($shouldUpdateVersionInPropsFile) {
    Set-Content -Path $propsPath -Value $propsOriginalText -Encoding utf8
    Write-Warning "Rolled back version change in Directory.Build.props due to failure."
  }

  throw
}
