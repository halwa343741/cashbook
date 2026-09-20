# Cashbook Runner Script
param(
    [string]$Device = "",
    [string]$Ip = "192.168.18.26",
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

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       CASHBOOK APP RUNNER              " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# 2. Clean jika diminta
if ($Clean) {
    Write-Host "[*] Membersihkan cache build (flutter clean)..." -ForegroundColor Yellow
    flutter clean
    Write-Host "[*] Mengambil dependencies (flutter pub get)..." -ForegroundColor Yellow
    flutter pub get
}

# 3. Mode Pairing Wi-Fi Debugging
if ($Pair) {
    Write-Host "`n--- Wi-Fi ADB Pairing ---" -ForegroundColor Magenta
    $pairIp = Read-Host "Masukkan IP HP [$Ip]"
    if ([string]::IsNullOrWhiteSpace($pairIp)) { $pairIp = $Ip }
    $pairPort = Read-Host "Masukkan Pairing Port (misal: 41245)"
    $pairCode = Read-Host "Masukkan 6-digit Pairing Code (misal: 532222)"
    
    Write-Host "[*] Melakukan pairing ke $pairIp`:$pairPort..." -ForegroundColor Cyan
    adb pair "$pairIp`:$pairPort" $pairCode
    
    $connectPort = Read-Host "`nMasukkan Port Sambungan Wireless Debugging utama (di bawah IP address)"
    if (-not [string]::IsNullOrWhiteSpace($connectPort)) {
        $Port = $connectPort
        $Ip = $pairIp
    }
}

# 4. Hubungkan ke Wi-Fi ADB jika Port diberikan
if (-not [string]::IsNullOrWhiteSpace($Port)) {
    Write-Host "[*] Menghubungkan ke $Ip`:$Port..." -ForegroundColor Cyan
    adb connect "$Ip`:$Port"
}

# 5. Cek Perangkat Terhubung
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

# 6. Tentukan Target Device
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
        Write-Host "`n[!] Tidak ada perangkat Android terhubung." -ForegroundColor Yellow
        Write-Host "Pilih target yang ingin dijalankan:"
        Write-Host "  [1] Hubungkan Android Samsung via Wi-Fi" -ForegroundColor Cyan
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
                $targetPort = Read-Host "Masukkan Port Wireless Debugging Samsung [$Port]"
                if ([string]::IsNullOrWhiteSpace($targetPort)) { $targetPort = $Port }
                if (-not [string]::IsNullOrWhiteSpace($targetPort)) {
                    $targetIp = Read-Host "Masukkan IP Samsung [$Ip]"
                    if ([string]::IsNullOrWhiteSpace($targetIp)) { $targetIp = $Ip }
                    adb connect "$targetIp`:$targetPort"
                    $targetDevice = "$targetIp`:$targetPort"
                }
            }
        }
    }
}

# 7. Eksekusi flutter run
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
