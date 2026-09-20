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

# 2. Deteksi IP aktif & subnet komputer tempat project dijalankan
function Get-HostNetworkInfo {
    try {
        $s = New-Object System.Net.Sockets.UdpClient
        $s.Connect("8.8.8.8", 53)
        $detectedIp = $s.Client.LocalEndPoint.Address.ToString()
        $s.Close()
        if ($detectedIp -match "^(\d+\.\d+\.\d+\.)") {
            return [PSCustomObject]@{ Subnet = $matches[1]; HostIp = $detectedIp }
        }
    } catch {}

    try {
        $route = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1
        if ($route) {
            $ipObj = Get-NetIPAddress -InterfaceIndex $route.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($ipObj -and $ipObj.IPAddress -match "^(\d+\.\d+\.\d+\.)") {
                return [PSCustomObject]@{ Subnet = $matches[1]; HostIp = $ipObj.IPAddress }
            }
        }
    } catch {}

    return [PSCustomObject]@{ Subnet = "192.168.18."; HostIp = "192.168.18.5" }
}

$netInfo = Get-HostNetworkInfo
$computerIp = $netInfo.HostIp
$subnetPrefix = $netInfo.Subnet

# 3. Manajemen devices.json (List Perangkat)
$devicesFilePath = Join-Path $PSScriptRoot "devices.json"

function Get-SavedDevices {
    if (Test-Path $devicesFilePath) {
        try {
            $content = Get-Content $devicesFilePath -Raw -Encoding UTF8
            return @(ConvertFrom-Json $content)
        } catch {}
    }
    # Default preset jika belum ada file
    $defaultList = @(
        [PSCustomObject]@{
            name = "Samsung Galaxy A07"
            ip = "$($subnetPrefix)26"
            port = "44557"
        }
    )
    Save-Devices $defaultList
    return $defaultList
}

function Save-Devices($devList) {
    try {
        $json = ConvertTo-Json @($devList) -Depth 5
        Set-Content -Path $devicesFilePath -Value $json -Encoding UTF8
    } catch {}
}

function Resolve-DeviceIp([string]$rawInput, [string]$fallbackOctet = "26") {
    if ([string]::IsNullOrWhiteSpace($rawInput)) {
        return "$subnetPrefix$fallbackOctet"
    }
    $trimmed = $rawInput.Trim()
    if ($trimmed -match "^\d+\.\d+\.\d+\.\d+$") {
        return $trimmed
    }
    $cleanOctet = $trimmed.TrimStart('.')
    return "$subnetPrefix$cleanOctet"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       CASHBOOK APP RUNNER              " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
if (-not [string]::IsNullOrWhiteSpace($computerIp)) {
    Write-Host "[i] IP Komputer ini : $computerIp" -ForegroundColor DarkGray
    Write-Host "[i] Subnet Jaringan : $subnetPrefix*" -ForegroundColor DarkGray
}

# 4. Clean jika diminta
if ($Clean) {
    Write-Host "`n[*] Membersihkan cache build (flutter clean)..." -ForegroundColor Yellow
    flutter clean
    Write-Host "[*] Mengambil dependencies (flutter pub get)..." -ForegroundColor Yellow
    flutter pub get
}

# 5. Mode Pairing Wi-Fi Debugging
if ($Pair) {
    Write-Host "`n--- Wi-Fi ADB Pairing ---" -ForegroundColor Magenta
    $inputOctet = Read-Host "Masukkan angka terakhir IP HP ($subnetPrefix[xxx]) atau full IP [26]"
    $pairIp = Resolve-DeviceIp $inputOctet "26"
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

# 6. Cek Perangkat yang Sedang Aktif di ADB
Write-Host "`n[*] Memeriksa koneksi ADB yang aktif..." -ForegroundColor Gray
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

# 7. Pemilihan Target Device
$targetDevice = $Device

# Jika Device dipassing angka 1, 2, dll -> ambil dari devices.json
if ($targetDevice -match "^\d+$") {
    $savedDevs = Get-SavedDevices
    $idx = [int]$targetDevice - 1
    if ($idx -ge 0 -and $idx -lt $savedDevs.Count) {
        $d = $savedDevs[$idx]
        $p = if (-not [string]::IsNullOrWhiteSpace($Port)) { $Port } else { $d.port }
        $targetDevice = "$($d.ip):$p"
        Write-Host "[*] Menghubungkan ke $($d.name) ($targetDevice)..." -ForegroundColor Cyan
        adb connect $targetDevice
    }
}

if ([string]::IsNullOrWhiteSpace($targetDevice)) {
    # Jika sudah ada perangkat ADB yang terhubung langsung
    if ($attachedDevices.Count -ge 1) {
        Write-Host "`n[+] Terdeteksi $($attachedDevices.Count) perangkat ADB aktif:" -ForegroundColor Green
        for ($i = 0; $i -lt $attachedDevices.Count; $i++) {
            Write-Host "  [$($i + 1)] $($attachedDevices[$i].Id) ($($attachedDevices[$i].Info))" -ForegroundColor Green
        }
        
        if ($attachedDevices.Count -eq 1) {
            $confirm = Read-Host "Langsung jalankan di $($attachedDevices[0].Id)? (Y/n)"
            if ([string]::IsNullOrWhiteSpace($confirm) -or $confirm -match "^[Yy]") {
                $targetDevice = $attachedDevices[0].Id
            }
        } else {
            $pilihan = Read-Host "Pilih nomor perangkat (1-$($attachedDevices.Count)) [1]"
            $selectedIdx = if ([string]::IsNullOrWhiteSpace($pilihan)) { 0 } else { [int]$pilihan - 1 }
            if ($selectedIdx -ge 0 -and $selectedIdx -lt $attachedDevices.Count) {
                $targetDevice = $attachedDevices[$selectedIdx].Id
            }
        }
    }
}

# Jika belum ada targetDevice yang dipilih, tampilkan Menu Utama dengan List Device
if ([string]::IsNullOrWhiteSpace($targetDevice)) {
    $savedDevices = Get-SavedDevices
    
    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host "        PILIH TARGET PERANGKAT          " -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    
    Write-Host "Daftar Perangkat Android Tersimpan (Wi-Fi):" -ForegroundColor Cyan
    for ($i = 0; $i -lt $savedDevices.Count; $i++) {
        $sd = $savedDevices[$i]
        Write-Host "  [$($i + 1)] $($sd.name) - $($sd.ip):$($sd.port)" -ForegroundColor White
    }
    $newIdx = $savedDevices.Count + 1
    Write-Host "  [$newIdx] + Tambah Perangkat Android Baru" -ForegroundColor Magenta
    
    Write-Host "`nTarget Platform Lain:" -ForegroundColor Gray
    Write-Host "  [W] Windows Desktop" -ForegroundColor White
    Write-Host "  [C] Chrome (Web)" -ForegroundColor White
    Write-Host "  [F] Tampilkan semua device Flutter (flutter devices)" -ForegroundColor White
    
    $pilihan = Read-Host "`nPilih [1-$newIdx / W / C / F] (Default: 1)"
    if ([string]::IsNullOrWhiteSpace($pilihan)) { $pilihan = "1" }
    
    switch -Regex ($pilihan) {
        "^[Ww]" { $targetDevice = "windows" }
        "^[Cc]" { $targetDevice = "chrome" }
        "^[Ff]" {
            flutter devices
            $targetDevice = Read-Host "Masukkan Device ID dari list di atas"
        }
        "^\d+$" {
            $selectedNum = [int]$pilihan
            if ($selectedNum -le $savedDevices.Count) {
                # Memilih dari list tersimpan
                $chosen = $savedDevices[$selectedNum - 1]
                Write-Host "`n--> Memilih: $($chosen.name) ($($chosen.ip))" -ForegroundColor Green
                
                $inputPort = Read-Host "Masukkan Port Wireless Debugging [$($chosen.port)] (Enter jika sama)"
                $activePort = if ([string]::IsNullOrWhiteSpace($inputPort)) { $chosen.port } else { $inputPort.Trim() }
                
                # Update port jika berubah agar diingat
                if ($activePort -ne $chosen.port) {
                    $chosen.port = $activePort
                    Save-Devices $savedDevices
                    Write-Host "[i] Port baru ($activePort) disimpan ke daftar." -ForegroundColor DarkGray
                }
                
                $targetDevice = "$($chosen.ip):$activePort"
                Write-Host "[*] Menghubungkan ADB ke $targetDevice..." -ForegroundColor Cyan
                adb connect $targetDevice
            } elseif ($selectedNum -eq $newIdx) {
                # Tambah perangkat baru
                Write-Host "`n--- Tambah Perangkat Android Baru ---" -ForegroundColor Magenta
                $newName = Read-Host "Nama Perangkat (misal: Samsung A07 Baru)"
                if ([string]::IsNullOrWhiteSpace($newName)) { $newName = "Android Device" }
                
                $newOctet = Read-Host "IP / Angka Terakhir IP ($subnetPrefix[xxx]) [26]"
                $newIp = Resolve-DeviceIp $newOctet "26"
                
                $newPort = Read-Host "Port Wireless Debugging (misal: 44557)"
                if ([string]::IsNullOrWhiteSpace($newPort)) { $newPort = "44557" }
                
                # Simpan ke daftar
                $savedDevices += [PSCustomObject]@{
                    name = $newName
                    ip = $newIp
                    port = $newPort
                }
                Save-Devices $savedDevices
                Write-Host "[+] Perangkat '$newName' ($newIp`:$newPort) berhasil disimpan!" -ForegroundColor Green
                
                $targetDevice = "$newIp`:$newPort"
                Write-Host "[*] Menghubungkan ADB ke $targetDevice..." -ForegroundColor Cyan
                adb connect $targetDevice
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
