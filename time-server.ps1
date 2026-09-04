<#
  Tiny host-side time server for the C64 dresser clock BASIC program.

  Streams the local time as "HH:mm:ss`r" once a second over TCP to whoever
  connects - i.e. VICE's emulated userport RS232, wired up via
  -rsdev1ip232 in run-clock.ps1. One client at a time.

  ponytail: single blocking accept loop, no auth/multi-client support -
  add if this ever needs to serve more than one emulator at once.
#>
param(
    [int]$Port = 6510
)

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
$listener.Start()
Write-Host "Time server listening on 127.0.0.1:$Port (Ctrl+C to stop)"

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        Write-Host "[$(Get-Date -Format T)] client connected: $($client.Client.RemoteEndPoint)"
        $stream = $client.GetStream()
        try {
            while ($client.Connected) {
                $line  = (Get-Date -Format 'HH:mm:ss') + "`r"
                $bytes = [System.Text.Encoding]::ASCII.GetBytes($line)
                $stream.Write($bytes, 0, $bytes.Length)
                $stream.Flush()
                Start-Sleep -Seconds 1
            }
        } catch {
            Write-Host "[$(Get-Date -Format T)] client disconnected"
        } finally {
            $client.Close()
        }
    }
} finally {
    $listener.Stop()
}
