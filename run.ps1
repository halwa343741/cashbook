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

# 4. Auto-Discovery Perangkat di Jaringan (mDNS + Saved Devices)
function Discover-NetworkDevices {
    $foundList = @()
    $savedDevs = Get-SavedDevices
    
    # 4a. Pindai via ADB mDNS services (Otomatis mendeteksi IP & Port HP aktif di Wi-Fi)
    $mdnsRaw = adb mdns services 2>$null
    if ($mdnsRaw) {
        foreach ($line in $mdnsRaw) {
            # Format: <instance_name>\t<service_name>\t<ip:port>
            if ($line -match "([^\s]+)\s+(_adb[^\s]+)\s+([0-9\.]+):(\d+)") {
                $mIp = $matches[3]
                $mPort = $matches[4]
                $addr = "$mIp`:$mPort"
                
                # Cek apakah sudah ada di list hasil scan
                if (-not ($foundList | Where-Object { $_.Ip -eq $mIp })) {
                    # Cari nama dari saved devices jika ada
                    $matchedSaved = $savedDevs | Where-Object { $_.ip -eq $mIp }
                    $friendlyName = if ($matchedSaved) { $matchedSaved.name } else { "Android Device ($mIp)" }
                    
                    # Update port di saved devices jika portnya berubah
                    if ($matchedSaved -and $matchedSaved.port -ne $mPort) {
                        $matchedSaved.port = $mPort
                        Save-Devices $savedDevs
                    }
                    
                    $foundList += [PSCustomObject]@{
                        Name = $friendlyName
                        Ip = $mIp
                        Port = $mPort
                        Address = $addr
                        Status = "Terdeteksi Otomatis di Wi-Fi"
                    }
                }
            }
        }
    }
    
    # 4b. Tambahkan perangkat dari devices.json jika belum terdeteksi lewat mDNS
    foreach ($sd in $savedDevs) {
        if (-not ($foundList | Where-Object { $_.Ip -eq $sd.ip })) {
            $foundList += [PSCustomObject]@{
                Name = $sd.name
                Ip = $sd.ip
                Port = $sd.port
                Address = "$($sd.ip):$($sd.port)"
                Status = "Tersimpan di devices.json"
            }
        }
    }
    
    return $foundList
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       CASHBOOK APP RUNNER              " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
if (-not [string]::IsNullOrWhiteSpace($computerIp)) {
    Write-Host "[i] IP Komputer ini : $computerIp" -ForegroundColor DarkGray
    Write-Host "[i] Subnet Jaringan : $subnetPrefix*" -ForegroundColor DarkGray
}

# 5. Clean jika diminta
if ($Clean) {
    Write-Host "`n[*] Membersihkan cache build (flutter clean)..." -ForegroundColor Yellow
    flutter clean
    Write-Host "[*] Mengambil dependencies (flutter pub get)..." -ForegroundColor Yellow
    flutter pub get
}

# 6. Mode Pairing Wi-Fi Debugging
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

# 7. Cek Perangkat yang Sedang Aktif di ADB
Write-Host "`n[*] Memeriksa koneksi ADB..." -ForegroundColor Gray
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

# 8. Tentukan Target Device
$targetDevice = $Device

# Jika Device dipassing nomor index (misal: .\run.ps1 -Device 1)
if ($targetDevice -match "^\d+$") {
    $devList = Discover-NetworkDevices
    $idx = [int]$targetDevice - 1
    if ($idx -ge 0 -and $idx -lt $devList.Count) {
        $d = $devList[$idx]
        $p = if (-not [string]::IsNullOrWhiteSpace($Port)) { $Port } else { $d.Port }
        $targetDevice = "$($d.Ip):$p"
        Write-Host "[*] Menghubungkan ke $($d.Name) ($targetDevice)..." -ForegroundColor Cyan
        adb connect $targetDevice
    }
}

# Jika belum ada target, tampilkan daftar perangkat otomatis dari jaringan
if ([string]::IsNullOrWhiteSpace($targetDevice)) {
    Write-Host "[*] Memindai perangkat Android di jaringan Wi-Fi lokal..." -ForegroundColor Gray
    $availableDevices = Discover-NetworkDevices
    
    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host "        PILIH TARGET PERANGKAT          " -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    
    Write-Host "Perangkat Android di Jaringan (Wi-Fi):" -ForegroundColor Cyan
    for ($i = 0; $i -lt $availableDevices.Count; $i++) {
        $dev = $availableDevices[$i]
        $statusTag = if ($dev.Status -match "Otomatis") { "[Online]" } else { "[Offline/Tersimpan]" }
        $color = if ($dev.Status -match "Otomatis") { "Green" } else { "White" }
        Write-Host "  [$($i + 1)] $($dev.Name) - $($dev.Address) $statusTag" -ForegroundColor $color
    }
    
    $newIdx = $availableDevices.Count + 1
    Write-Host "  [$newIdx] + Input IP Manual / Tambah Perangkat" -ForegroundColor Magenta
    
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
            if ($selectedNum -le $availableDevices.Count) {
                $chosen = $availableDevices[$selectedNum - 1]
                Write-Host "`n--> Memilih: $($chosen.Name) ($($chosen.Address))" -ForegroundColor Green
                
                # Jika port sudah terdeteksi otomatis via mDNS, tanyakan konfirmasi / langsung pakai
                $inputPort = Read-Host "Port Wireless Debugging [$($chosen.Port)] (Enter untuk pakai)"
                $activePort = if ([string]::IsNullOrWhiteSpace($inputPort)) { $chosen.Port } else { $inputPort.Trim() }
                
                # Perbarui port jika ada perubahan
                $savedDevs = Get-SavedDevices
                $matchedInSaved = $savedDevs | Where-Object { $_.ip -eq $chosen.Ip }
                if ($matchedInSaved -and $matchedInSaved.port -ne $activePort) {
                    $matchedInSaved.port = $activePort
                    Save-Devices $savedDevs
                }
                
                $targetDevice = "$($chosen.Ip):$activePort"
                Write-Host "[*] Menghubungkan ADB ke $targetDevice..." -ForegroundColor Cyan
                adb connect $targetDevice
            } elseif ($selectedNum -eq $newIdx) {
                Write-Host "`n--- Tambah Perangkat Android Baru ---" -ForegroundColor Magenta
                $newName = Read-Host "Nama Perangkat (misal: Samsung A07 Baru)"
                if ([string]::IsNullOrWhiteSpace($newName)) { $newName = "Android Device" }
                
                $newOctet = Read-Host "IP / Angka Terakhir IP ($subnetPrefix[xxx]) [26]"
                $newIp = Resolve-DeviceIp $newOctet "26"
                
                $newPort = Read-Host "Port Wireless Debugging (misal: 44557)"
                if ([string]::IsNullOrWhiteSpace($newPort)) { $newPort = "44557" }
                
                # Simpan ke daftar
                $savedDevs = Get-SavedDevices
                $savedDevs += [PSCustomObject]@{
                    name = $newName
                    ip = $newIp
                    port = $newPort
                }
                Save-Devices $savedDevs
                Write-Host "[+] Perangkat '$newName' ($newIp`:$newPort) berhasil disimpan!" -ForegroundColor Green
                
                $targetDevice = "$newIp`:$newPort"
                Write-Host "[*] Menghubungkan ADB ke $targetDevice..." -ForegroundColor Cyan
                adb connect $targetDevice
            }
        }
    }
}

# 9. Eksekusi flutter run
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
