<#
  Builds and runs the C64 dresser-clock BASIC program in VICE.

  - reads tool locations from paths.ini
  - starts the host time server (time-server.ps1) in its own window
  - tokenizes clock.bas to clock.prg with petcat (ships with VICE), using
    Basic v2.0 (C64) keywords
  - autostarts it in x64sc, wired to the emulated userport RS232 over a
    TCP loopback connection to the time server
#>
param(
    [int]$Port = 6510
)

$root = $PSScriptRoot
$ini  = Get-Content (Join-Path $root 'paths.ini') -Raw

function Get-IniPath([string]$section, [string]$content) {
    $pattern = '(?ims)\[{0}\].*?RootPath\s*=\s*"([^"]+)"' -f [regex]::Escape($section)
    if ($content -match $pattern) { return $Matches[1] }
    throw "RootPath not found for [$section] in paths.ini"
}

$vicePath = Get-IniPath 'VICE' $ini
$cc65Path = Get-IniPath 'CC65' $ini   # not needed here - clock.bas is plain BASIC, not C
Write-Host "VICE: $vicePath"
Write-Host "cc65: $cc65Path (unused for this BASIC-only program)"

$petcat = Join-Path $vicePath 'bin\petcat.exe'
$x64sc  = Join-Path $vicePath 'bin\x64sc.exe'
$basSrc = Join-Path $root 'clock.bas'
$prg    = Join-Path $root 'clock.prg'
$server = Join-Path $root 'time-server.ps1'

& $petcat -w2 -o $prg -- $basSrc
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $prg)) { throw "petcat failed to tokenize $basSrc" }

$serverProc = Start-Process pwsh -ArgumentList @('-NoExit', '-File', $server, '-Port', $Port) -PassThru

try {
    Start-Sleep -Seconds 1   # let the listener bind before VICE tries to connect
    # ponytail: "& $x64sc" looked synchronous but this GTK3 build's launcher process
    # returns almost immediately while the real emulator window keeps running -
    # Start-Process -Wait blocks on the actual process handle instead.
    Start-Process $x64sc -ArgumentList @(
        '-userportdevice', '2', '-rsuserdev', '0', '-rsdev1', "127.0.0.1:$Port",
        '-rsdev1ip232', '-rsuserbaud', '1200', '-autostart', $prg
    ) -Wait
} finally {
    if (-not $serverProc.HasExited) { Stop-Process -Id $serverProc.Id -Force }
}
