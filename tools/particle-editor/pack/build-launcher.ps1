param(
    [Parameter(Mandatory = $true)]
    [string] $OutputDirectory
)

$ErrorActionPreference = 'Stop'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) {
    $compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
}
if (-not (Test-Path -LiteralPath $compiler)) {
    throw 'The .NET Framework C# compiler is required to build the Windows launcher.'
}

$destination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDirectory)
$null = [System.IO.Directory]::CreateDirectory($destination)
$executable = Join-Path $destination 'AuraParticleEditor.exe'
$source = Join-Path $PSScriptRoot 'Launcher.cs'
& $compiler '/nologo' '/target:winexe' '/optimize+' '/r:System.Windows.Forms.dll' "/out:$executable" $source
if ($LASTEXITCODE -ne 0) { throw 'The Windows launcher failed to compile.' }
Write-Output $executable
