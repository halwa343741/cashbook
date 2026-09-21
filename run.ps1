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

# 0. Hentikan proses yang sedang berjalan sebelumnya (jika ada)
Write-Host "[*] Memeriksa & menghentikan proses yang sedang berjalan..." -ForegroundColor Yellow

# Hentikan aplikasi Cashbook Desktop jika sedang terbuka
$cashbookProcs = Get-Process -Name "cashbook" -ErrorAction SilentlyContinue
if ($cashbookProcs) {
    Write-Host "  -> Menutup proses aplikasi Cashbook Desktop..." -ForegroundColor DarkYellow
    $cashbookProcs | Stop-Process -Force -ErrorAction SilentlyContinue
}

# Hentikan background flutter/dart tools yang menggantung (mencegah startup lock)
try {
    $dartProcs = Get-CimInstance Win32_Process -Filter "Name = 'dart.exe'" -ErrorAction SilentlyContinue
    foreach ($p in $dartProcs) {
        if ($p.CommandLine -and $p.CommandLine -match "flutter_tools") {
            Write-Host "  -> Menghentikan background Flutter tool (PID $($p.ProcessId))..." -ForegroundColor DarkYellow
            Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
        }
    }
} catch {}

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
                    try {
                        if ($matchedSaved -and ($matchedSaved.PSObject.Properties.Match('port').Count -gt 0)) {
                            if ($matchedSaved.port -ne $mPort) {
                                $matchedSaved.port = $mPort
                                Save-Devices $savedDevs
                            }
                        }
                    } catch {}
                    
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
            Write-Host "`n[*] Mengambil daftar perangkat dari Flutter..." -ForegroundColor Cyan
            $flutterDevices = @()
            $rawDevices = flutter devices 2>$null
            foreach ($line in $rawDevices) {
                if ($line -match '^\s*([^•]+?)\s+•\s+([^•]+?)\s+•\s+([^•]+?)\s+•\s*(.*)$') {
                    $flutterDevices += [PSCustomObject]@{
                        Name     = $matches[1].Trim()
                        Id       = $matches[2].Trim()
                        Platform = $matches[3].Trim()
                        Info     = $matches[4].Trim()
                    }
                }
            }

            if ($flutterDevices.Count -gt 0) {
                Write-Host "`n--- Perangkat Flutter Terdeteksi ---" -ForegroundColor Yellow
                for ($k = 0; $k -lt $flutterDevices.Count; $k++) {
                    $fd = $flutterDevices[$k]
                    Write-Host "  [$($k + 1)] $($fd.Name) [$($fd.Platform)]" -ForegroundColor Green
                    Write-Host "      ID: $($fd.Id)" -ForegroundColor DarkGray
                }
                
                # Default preferensi perangkat mobile / wireless jika ada
                $defaultFIdx = 1
                for ($k = 0; $k -lt $flutterDevices.Count; $k++) {
                    if ($flutterDevices[$k].Platform -match "android|ios" -or $flutterDevices[$k].Name -match "wireless|mobile") {
                        $defaultFIdx = $k + 1
                        break
                    }
                }

                $fPick = Read-Host "`nPilih nomor perangkat [1-$($flutterDevices.Count)] (Default: $defaultFIdx)"
                if ([string]::IsNullOrWhiteSpace($fPick)) { $fPick = "$defaultFIdx" }
                
                if ($fPick -match "^\d+$" -and [int]$fPick -ge 1 -and [int]$fPick -le $flutterDevices.Count) {
                    $selectedDev = $flutterDevices[[int]$fPick - 1]
                    $targetDevice = $selectedDev.Id
                    Write-Host "--> Memilih: $($selectedDev.Name) ($targetDevice)`n" -ForegroundColor Green
                } else {
                    $targetDevice = $fPick.Trim()
                }
            } else {
                Write-Host "[!] Tidak ada perangkat Flutter terdeteksi atau gagal parsing." -ForegroundColor Yellow
                flutter devices
                $targetDevice = Read-Host "Masukkan Device ID secara manual"
            }
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

# Package name aplikasi (sesuai applicationId di build.gradle)
# Mode Debug menggunakan .dev agar TIDAK MENGHAPUS aplikasi Production yang sudah terpasang di HP!
$packageName = if ($Release) { "com.tanory.cashbook" } else { "com.tanory.cashbook.dev" }

$isAndroidTarget = (
    -not [string]::IsNullOrWhiteSpace($targetDevice) -and
    $targetDevice -ne "windows" -and
    $targetDevice -ne "chrome" -and
    $targetDevice -ne "edge"
)

# Khusus Android: Hanya install & jalankan di User 0 (Primary User)
if ($isAndroidTarget) {
    $runArgs += "--device-user=0"
}

# Bersihkan total (Fresh Install):
# Otomatis untuk Debug (.dev). Untuk Release (Production), hanya jika switch -Clean diberikan agar data riil tidak hilang.
$shouldClean = if ($Release) { $Clean.IsPresent } else { $true }

if ($isAndroidTarget -and $shouldClean) {
    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "   BERSIHKAN dan PASANG ULANG (FRESH INSTALL)" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "[*] Package: $packageName" -ForegroundColor DarkGray
    Write-Host "[*] Device : $targetDevice" -ForegroundColor DarkGray
    Write-Host "[*] Target : User 0 (Primary User only)`n" -ForegroundColor DarkGray

    Write-Host "[1/3] Force-stop aplikasi lama..." -ForegroundColor Yellow
    adb -s $targetDevice shell am force-stop $packageName 2>$null
    Start-Sleep -Milliseconds 500

    Write-Host "[2/3] Clear cache dan data aplikasi..." -ForegroundColor Yellow
    $clearResult = adb -s $targetDevice shell pm clear $packageName 2>&1
    if ($clearResult -match "Success") {
        Write-Host "      -> Cache dan data berhasil dihapus." -ForegroundColor Green
    } else {
        Write-Host "      -> Cache sudah bersih." -ForegroundColor DarkYellow
    }

    Write-Host "[3/3] Uninstall aplikasi lama dari semua user profile..." -ForegroundColor Yellow
    # Deteksi semua user di perangkat (User 0, 95 (Dual Messenger), 999 (Dual App), dsb.)
    $usersOutput = adb -s $targetDevice shell pm list users 2>$null
    $allUserIds = @()
    if ($usersOutput) {
        $allUserIds = [regex]::Matches($usersOutput, 'UserInfo\{(\d+):') | ForEach-Object { $_.Groups[1].Value }
    }
    if (-not $allUserIds -or $allUserIds.Count -eq 0) {
        $allUserIds = @("0", "95", "999", "10", "11", "12")
    }

    foreach ($uId in $allUserIds) {
        if ($uId -ne "0") {
            Write-Host "      -> Membersihkan dari User Profile $uId (Dual App / Work Profile)..." -ForegroundColor DarkYellow
        }
        adb -s $targetDevice shell pm uninstall --user $uId $packageName 2>$null
    }

    $uninstallResult = adb -s $targetDevice uninstall $packageName 2>&1
    if ($uninstallResult -match "Success") {
        Write-Host "      -> Aplikasi berhasil diuninstall total." -ForegroundColor Green
    } else {
        Write-Host "      -> Aplikasi bersih / tidak terpasang." -ForegroundColor DarkYellow
    }

    Write-Host "`n[OK] Siap install fresh hanya ke User 0!`n" -ForegroundColor Green

    # Jalankan background watcher untuk mencopot instalasi otomatis pada user non-0 (Dual Messenger Samsung)
    $cleanupScript = {
        param($dev, $pkg)
        Start-Sleep -Seconds 12
        for ($i = 0; $i -lt 10; $i++) {
            $usersRaw = adb -s $dev shell pm list users 2>$null
            $otherUsers = [regex]::Matches($usersRaw, 'UserInfo\{(\d+):') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -ne "0" }
            foreach ($u in $otherUsers) {
                $chk = adb -s $dev shell pm list packages --user $u $pkg 2>$null
                if ($chk -match $pkg) {
                    adb -s $dev shell pm uninstall --user $u $pkg 2>$null
                }
            }
            Start-Sleep -Seconds 5
        }
    }
    Start-Job -ScriptBlock $cleanupScript -ArgumentList $targetDevice, $packageName | Out-Null
}

Write-Host "[*] Menjalankan: flutter $($runArgs -join ' ')" -ForegroundColor Green
Write-Host "Tekan 'r' Hot Reload, 'R' Hot Restart, 'q' Quit.`n" -ForegroundColor DarkCyan

try {
    & flutter $runArgs
} finally {
    Get-Job | Stop-Job -ErrorAction SilentlyContinue
    Get-Job | Remove-Job -ErrorAction SilentlyContinue
}
