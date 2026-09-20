# Cashbook Runner Script
param(
    [string]$Device = "",
    [string]$LastOctet = "26",
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

# 2. Deteksi Subnet Wi-Fi lokal (misal: 192.168.18.)
$wifiIp = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi*" -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress
if ($wifiIp -match "^(\d+\.\d+\.\d+\.)") {
    $subnetPrefix = $matches[1]
} else {
    $subnetPrefix = "192.168.18."
}

# Helper untuk menyusun IP lengkap dari input user (cukup angka terakhir / full IP)
function Resolve-DeviceIp([string]$rawInput, [string]$defaultOctet = "26") {
    if ([string]::IsNullOrWhiteSpace($rawInput)) {
        return "$subnetPrefix$defaultOctet"
    }
    $trimmed = $rawInput.Trim()
    # Jika sudah merupakan format full IP (misal: 192.168.18.26)
    if ($trimmed -match "^\d+\.\d+\.\d+\.\d+$") {
        return $trimmed
    }
    # Jika hanya angka terakhir (misal: 26 atau .26)
    $cleanOctet = $trimmed.TrimStart('.')
    return "$subnetPrefix$cleanOctet"
}

# Inisialisasi IP aktif
if ([string]::IsNullOrWhiteSpace($Ip)) {
    $currentIp = Resolve-DeviceIp $LastOctet $LastOctet
} else {
    $currentIp = Resolve-DeviceIp $Ip $LastOctet
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       CASHBOOK APP RUNNER              " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[i] Subnet Wi-Fi aktif : $subnetPrefix* (Default HP: $currentIp)" -ForegroundColor DarkGray

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
    $inputOctet = Read-Host "Masukkan ujung IP HP ($subnetPrefix[xxx]) [26]"
    $pairIp = Resolve-DeviceIp $inputOctet "26"
    $pairPort = Read-Host "Masukkan Pairing Port 5-digit (misal: 41245)"
    $pairCode = Read-Host "Masukkan 6-digit Pairing Code (misal: 532222)"
    
    Write-Host "[*] Melakukan pairing ke $pairIp`:$pairPort..." -ForegroundColor Cyan
    adb pair "$pairIp`:$pairPort" $pairCode
    
    $connectPort = Read-Host "`nMasukkan Port Sambungan Wireless Debugging utama (di bawah IP address)"
    if (-not [string]::IsNullOrWhiteSpace($connectPort)) {
        $Port = $connectPort
        $currentIp = $pairIp
    }
}

# 5. Hubungkan ke Wi-Fi ADB jika Port diberikan lewat parameter / pairing
if (-not [string]::IsNullOrWhiteSpace($Port)) {
    Write-Host "[*] Menghubungkan ke $currentIp`:$Port..." -ForegroundColor Cyan
    adb connect "$currentIp`:$Port"
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
        # Tidak ada device ADB terhubung, tampilkan menu cepat
        Write-Host "`n[!] Belum ada perangkat Android terhubung via ADB." -ForegroundColor Yellow
        Write-Host "Pilih target yang ingin dijalankan:"
        Write-Host "  [1] Sambungkan Samsung via Wi-Fi (Cukup masukkan Port & Ujung IP)" -ForegroundColor Cyan
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
                $targetPort = Read-Host "Masukkan Port Wireless Debugging Samsung (misal: 44557)"
                if (-not [string]::IsNullOrWhiteSpace($targetPort)) {
                    $inputOctet = Read-Host "Masukkan angka terakhir IP Samsung ($subnetPrefix[xxx]) [26]"
                    $targetIp = Resolve-DeviceIp $inputOctet "26"
                    Write-Host "[*] Menghubungkan ke $targetIp`:$targetPort..." -ForegroundColor Cyan
                    adb connect "$targetIp`:$targetPort"
                    $targetDevice = "$targetIp`:$targetPort"
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
