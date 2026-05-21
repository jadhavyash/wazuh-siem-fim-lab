# Wazuh FIM Test Script — triggers Rule 554 (add), 550 (modify), 553 (delete)
# Run as Administrator after configuring ossec.conf
# Author: Yash Jadhav

$TestDir = "C:\Users\$env:USERNAME\Test"
if (-not (Test-Path $TestDir)) { New-Item -ItemType Directory -Path $TestDir | Out-Null }

Write-Host "[*] FIM Test started — watch Wazuh Dashboard for alerts" -ForegroundColor Yellow

# Test 1: Create files (Rule 554 — Level 9 HIGH)
Write-Host "`n[1] Creating files..."
1..3 | ForEach-Object {
    "FIM Test file $_ created $(Get-Date)" | Out-File "$TestDir\testfile_$_.txt"
    Write-Host "    Created: testfile_$_.txt"; Start-Sleep 2
}

# Test 2: Modify files (Rule 550 — Level 7)
Write-Host "`n[2] Modifying files..."
1..3 | ForEach-Object {
    "MODIFIED $(Get-Date)" | Add-Content "$TestDir\testfile_$_.txt"
    Write-Host "    Modified: testfile_$_.txt"; Start-Sleep 2
}

# Test 3: Delete files (Rule 553 — Level 7)
Write-Host "`n[3] Deleting files..."
Get-ChildItem $TestDir | ForEach-Object {
    Remove-Item $_.FullName -Force
    Write-Host "    Deleted: $($_.Name)"; Start-Sleep 2
}

Write-Host "`n[OK] Done. Check: Wazuh Dashboard > Endpoint Security > FIM" -ForegroundColor Green
