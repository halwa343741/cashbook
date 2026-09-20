# Cashbook Runner Script
param(
    [string]$Device = "",
    [string]$LastOctet = "",
    [string]$Ip = "",
    [string]$Port = "",
    [switch]$Pair,
    [switch]$Clean,
    [switch]$Release
)

# 1. Pastikan ADB ada di PATH
$adbCmd = Get-Command adb -ErrorAction SilentlyContinue
if (-not $adbCmd) {
    if (Test-Path "D:\SDK\platform-tools\adb.exe") {
        $env:PATH = "D:\SDK\platform-tools;$env:PATH"
    } elseif (Test-Path "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe") {
        $env:PATH = "$env:LOCALAPPDATA\Android\Sdk\platform-tools;$env:PATH"
    }
}

# 2. Deteksi IP aktif & subnet komputer tempat project dijalankan (tanpa hardcode)
function Get-HostNetworkInfo {
    # Metode 1: UdpClient query route OS ke gateway/internet
    try {
        $s = New-Object System.Net.Sockets.UdpClient
        $s.Connect("8.8.8.8", 53)
        $detectedIp = $s.Client.LocalEndPoint.Address.ToString()
        $s.Close()
        if ($detectedIp -match "^(\d+\.\d+\.\d+\.)") {
            return [PSCustomObject]@{ Subnet = $matches[1]; HostIp = $detectedIp }
        }
    } catch {}

    # Metode 2: Cari route default gateway aktif (0.0.0.0/0)
    try {
        $route = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1
        if ($route) {
            $ipObj = Get-NetIPAddress -InterfaceIndex $route.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($ipObj -and $ipObj.IPAddress -match "^(\d+\.\d+\.\d+\.)") {
                return [PSCustomObject]@{ Subnet = $matches[1]; HostIp = $ipObj.IPAddress }
            }
        }
    } catch {}

    # Metode 3: IPv4 non-loopback dan non-APIPA pertama
    try {
        $firstIp = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { 
            $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" -and $_.IPAddress -notlike "172.26.*" 
        } | Select-Object -First 1).IPAddress
        if ($firstIp -match "^(\d+\.\d+\.\d+\.)") {
            return [PSCustomObject]@{ Subnet = $matches[1]; HostIp = $firstIp }
        }
    } catch {}

    return [PSCustomObject]@{ Subnet = ""; HostIp = "" }
}

$netInfo = Get-HostNetworkInfo
$computerIp = $netInfo.HostIp
$subnetPrefix = $netInfo.Subnet

# Helper untuk menyusun IP lengkap dari input user (angka terakhir atau full IP)
function Resolve-DeviceIp([string]$rawInput, [string]$fallbackOctet = "") {
    if ([string]::IsNullOrWhiteSpace($rawInput)) {
        if (-not [string]::IsNullOrWhiteSpace($fallbackOctet)) {
            return "$subnetPrefix$fallbackOctet"
        }
        return ""
    }
    $trimmed = $rawInput.Trim()
    # Jika sudah format full IP (minimal ada 3 titik)
    if ($trimmed -match "^\d+\.\d+\.\d+\.\d+$") {
        return $trimmed
    }
    # Jika hanya angka terakhir (misal: 26 atau .26)
    $cleanOctet = $trimmed.TrimStart('.')
    if (-not [string]::IsNullOrWhiteSpace($subnetPrefix)) {
        return "$subnetPrefix$cleanOctet"
    }
    return $cleanOctet
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       CASHBOOK APP RUNNER              " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
if (-not [string]::IsNullOrWhiteSpace($computerIp)) {
    Write-Host "[i] IP Komputer ini : $computerIp" -ForegroundColor DarkGray
    Write-Host "[i] Subnet Jaringan : $subnetPrefix*" -ForegroundColor DarkGray
}

# 3. Clean jika diminta
if ($Clean) {
    Write-Host "`n[*] Membersihkan cache build (flutter clean)..." -ForegroundColor Yellow
    flutter clean
    Write-Host "[*] Mengambil dependencies (flutter pub get)..." -ForegroundColor Yellow
    flutter pub get
}

# 4. Mode Pairing Wi-Fi Debugging
if ($Pair) {
    Write-Host "`n--- Wi-Fi ADB Pairing ---" -ForegroundColor Magenta
    $promptLabel = if ($subnetPrefix) { "Masukkan ujung IP HP ($subnetPrefix[xxx]) atau full IP" } else { "Masukkan IP HP" }
    $inputOctet = Read-Host $promptLabel
    $pairIp = Resolve-DeviceIp $inputOctet
    $pairPort = Read-Host "Masukkan 5-digit Pairing Port (misal: 41245)"
    $pairCode = Read-Host "Masukkan 6-digit Pairing Code (misal: 532222)"
    
    Write-Host "[*] Melakukan pairing ke $pairIp`:$pairPort..." -ForegroundColor Cyan
    adb pair "$pairIp`:$pairPort" $pairCode
    
    $connectPort = Read-Host "`nMasukkan Port Sambungan Wireless Debugging utama (di bawah IP address)"
    if (-not [string]::IsNullOrWhiteSpace($connectPort)) {
        $Port = $connectPort
        $Ip = $pairIp
    }
}

# 5. Tentukan IP tujuan dari parameter jika diberikan
$targetIp = ""
if (-not [string]::IsNullOrWhiteSpace($Ip)) {
    $targetIp = Resolve-DeviceIp $Ip
} elseif (-not [string]::IsNullOrWhiteSpace($LastOctet)) {
    $targetIp = Resolve-DeviceIp $LastOctet
}

# Hubungkan jika Port dan IP sudah tersedia
if (-not [string]::IsNullOrWhiteSpace($Port) -and -not [string]::IsNullOrWhiteSpace($targetIp)) {
    Write-Host "[*] Menghubungkan ke $targetIp`:$Port..." -ForegroundColor Cyan
    adb connect "$targetIp`:$Port"
}

# 6. Cek Perangkat Terhubung
Write-Host "`n[*] Memeriksa perangkat yang aktif..." -ForegroundColor Gray
$attachedDevices = @()
$adbOutput = adb devices -l 2>$null
if ($adbOutput) {
    foreach ($line in $adbOutput) {
        if ($line -match "^([^\s]+)\s+device\s+(.*)$") {
            $devId = $matches[1]
            $devInfo = $matches[2]
            $attachedDevices += [PSCustomObject]@{ Id = $devId; Info = $devInfo }
        }
    }
}

# 7. Tentukan Target Device
$targetDevice = $Device

if ([string]::IsNullOrWhiteSpace($targetDevice)) {
    if ($attachedDevices.Count -eq 1) {
        $targetDevice = $attachedDevices[0].Id
        Write-Host "[+] Terdeteksi 1 perangkat Android: $targetDevice ($($attachedDevices[0].Info))" -ForegroundColor Green
    } elseif ($attachedDevices.Count -gt 1) {
        Write-Host "`nBeberapa perangkat terdeteksi:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $attachedDevices.Count; $i++) {
            Write-Host "  [$($i + 1)] $($attachedDevices[$i].Id) - $($attachedDevices[$i].Info)"
        }
        $pilihan = Read-Host "Pilih nomor perangkat (atau tekan Enter untuk auto)"
        if ($pilihan -match "^\d+$" -and [int]$pilihan -le $attachedDevices.Count) {
            $targetDevice = $attachedDevices[[int]$pilihan - 1].Id
        }
    } else {
        # Tidak ada device ADB terhubung, tampilkan menu
        Write-Host "`n[!] Belum ada perangkat Android terhubung via ADB." -ForegroundColor Yellow
        Write-Host "Pilih target yang ingin dijalankan:"
        Write-Host "  [1] Hubungkan Android via Wi-Fi" -ForegroundColor Cyan
        Write-Host "  [2] Jalankan di Windows Desktop" -ForegroundColor White
        Write-Host "  [3] Jalankan di Chrome (Web)" -ForegroundColor White
        Write-Host "  [4] Tampilkan semua device Flutter" -ForegroundColor White
        $choice = Read-Host "Pilihan [1/2/3/4] (Default: 1)"
        
        switch ($choice) {
            "2" { $targetDevice = "windows" }
            "3" { $targetDevice = "chrome" }
            "4" { 
                flutter devices
                $targetDevice = Read-Host "Masukkan Device ID dari list di atas"
            }
            default {
                $targetPort = Read-Host "Masukkan Port Wireless Debugging HP (misal: 44557)"
                if (-not [string]::IsNullOrWhiteSpace($targetPort)) {
                    $promptLabel = if ($subnetPrefix) { "Masukkan angka terakhir IP HP ($subnetPrefix[xxx]) atau full IP" } else { "Masukkan IP HP" }
                    $inputVal = Read-Host $promptLabel
                    $finalIp = Resolve-DeviceIp $inputVal
                    Write-Host "[*] Menghubungkan ke $finalIp`:$targetPort..." -ForegroundColor Cyan
                    adb connect "$finalIp`:$targetPort"
                    $targetDevice = "$finalIp`:$targetPort"
                }
            }
        }
    }
}

# 8. Eksekusi flutter run
$runArgs = @("run")
if (-not [string]::IsNullOrWhiteSpace($targetDevice)) {
    $runArgs += @("-d", $targetDevice)
}
if ($Release) {
    $runArgs += "--release"
}

Write-Host "`n[*] Menjalankan: flutter $($runArgs -join ' ')" -ForegroundColor Green
Write-Host "Tekan 'r' untuk Hot Reload, 'R' untuk Hot Restart, 'q' untuk Quit.`n" -ForegroundColor DarkCyan

& flutter $runArgs
