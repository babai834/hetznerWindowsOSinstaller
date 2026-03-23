@echo off
REM ============================================================
REM Hetzner Network Fix Script
REM Run this inside Windows if network doesn't work after install
REM ============================================================

echo ============================================
echo  Hetzner Network Configuration Fix
echo ============================================
echo.

set SERVER_IP=37.27.49.125
set GATEWAY=
set DNS1=185.12.64.1
set DNS2=185.12.64.2

REM Auto-detect gateway if not set
if "%GATEWAY%"=="" (
    REM Hetzner gateways are typically the IP with last octet as .1
    REM But for /32 routing, the gateway is provided separately
    REM Common Hetzner gateway patterns:
    for /f "tokens=1-3 delims=." %%a in ("%SERVER_IP%") do (
        set GATEWAY=%%a.%%b.%%c.1
    )
)

echo Server IP: %SERVER_IP%
echo Gateway:   %GATEWAY%
echo DNS:       %DNS1%, %DNS2%
echo.

REM Find the active network adapter
set ADAPTER=
for /f "skip=3 tokens=3,4*" %%a in ('netsh interface show interface') do (
    if "%%a"=="Connected" (
        set "ADAPTER=%%c"
        goto :adapter_found
    )
)

REM Fallback: try common names
for %%n in ("Ethernet" "Ethernet0" "Local Area Connection") do (
    netsh interface show interface name=%%n >nul 2>&1
    if not errorlevel 1 (
        set "ADAPTER=%%~n"
        goto :adapter_found
    )
)

echo [ERROR] No network adapter found!
echo Please check Device Manager for the adapter name.
pause
exit /b 1

:adapter_found
echo Using adapter: %ADAPTER%
echo.

echo Step 1: Removing existing IP configuration...
netsh interface ip set address name="%ADAPTER%" source=dhcp >nul 2>&1
timeout /t 3 /nobreak >nul

echo Step 2: Setting static IP with /32 subnet...
netsh interface ipv4 set address name="%ADAPTER%" static %SERVER_IP% 255.255.255.255

echo Step 3: Adding gateway route...
REM For Hetzner /32 routing, we need to add the gateway as a directly-connected host first
netsh interface ipv4 add route %GATEWAY%/32 "%ADAPTER%" 0.0.0.0 metric=1 >nul 2>&1
netsh interface ipv4 add route 0.0.0.0/0 "%ADAPTER%" %GATEWAY% metric=1 >nul 2>&1

REM Alternative method using route command
route delete 0.0.0.0 >nul 2>&1
route add %GATEWAY% mask 255.255.255.255 0.0.0.0 >nul 2>&1  
route add 0.0.0.0 mask 0.0.0.0 %GATEWAY% >nul 2>&1

echo Step 4: Configuring DNS...
netsh interface ipv4 set dns name="%ADAPTER%" static %DNS1%
netsh interface ipv4 add dns name="%ADAPTER%" %DNS2% index=2

echo Step 5: Enabling ICMP (ping)...
netsh advfirewall firewall add rule name="Allow ICMPv4" protocol=icmpv4 dir=in action=allow >nul 2>&1

echo Step 6: Enabling RDP...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul 2>&1
netsh advfirewall firewall set rule group="Remote Desktop" new enable=yes >nul 2>&1

echo.
echo ============================================
echo  Testing connectivity...
echo ============================================
echo.

ping -n 2 %GATEWAY% >nul 2>&1
if %errorlevel%==0 (
    echo [OK] Gateway %GATEWAY% is reachable
) else (
    echo [WARN] Gateway %GATEWAY% not reachable - this may be normal for /32 routing
)

ping -n 2 %DNS1% >nul 2>&1
if %errorlevel%==0 (
    echo [OK] DNS server %DNS1% is reachable
) else (
    echo [FAIL] DNS server %DNS1% not reachable
)

ping -n 2 google.com >nul 2>&1
if %errorlevel%==0 (
    echo [OK] Internet connectivity working
) else (
    echo [FAIL] No internet - may need ARP entry for gateway
    echo.
    echo Attempting ARP fix...
    REM Get gateway MAC from route table
    arp -s %GATEWAY% 00-00-00-00-00-00 >nul 2>&1
    netsh interface ipv4 add neighbors "%ADAPTER%" %GATEWAY% 00-00-00-00-00-00 >nul 2>&1
)

echo.
echo ============================================
echo  Network configuration applied.
echo  IP: %SERVER_IP%/32
echo  RDP should be available at %SERVER_IP%:3389
echo ============================================
echo.
pause
