# One-shot Android release signing setup for Inkwell (Windows).
# Creates upload keystore, writes android/key.properties, saves a local backup file.
#
# Usage (from project root):
#   .\scripts\setup-release-signing.ps1
#
# Optional: pass your own password (must be 6+ chars):
#   .\scripts\setup-release-signing.ps1 -Password "MySecurePass123"

param(
    [string]$Password = ""
)

$ErrorActionPreference = "Stop"

$KeytoolCandidates = @(
    "$env:JAVA_HOME\bin\keytool.exe",
    "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe",
    "C:\Program Files\Java\jdk-17\bin\keytool.exe"
)

$Keytool = $KeytoolCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Keytool) {
    Write-Error "keytool not found. Install Android Studio or set JAVA_HOME."
    exit 1
}

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$KeyDir = Join-Path $ProjectRoot "key"
$Keystore = Join-Path $KeyDir "comicEditor_app-keystore.jks"
$KeyProperties = Join-Path $ProjectRoot "android\key.properties"
$CredentialsFile = Join-Path $KeyDir "SIGNING_CREDENTIALS.txt"

New-Item -ItemType Directory -Force -Path $KeyDir | Out-Null

if ([string]::IsNullOrWhiteSpace($Password)) {
    $chars = (48..57) + (65..90) + (97..122)
    $Password = -join ($chars | Get-Random -Count 24 | ForEach-Object { [char]$_ })
}

if ($Password.Length -lt 6) {
    Write-Error "Password must be at least 6 characters."
    exit 1
}

if (Test-Path $Keystore) {
    $backup = "$Keystore.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $Keystore $backup -Force
    Remove-Item $Keystore -Force
    Write-Host "Backed up previous keystore to: $backup"
}

Write-Host "Using keytool: $Keytool"
Write-Host "Creating keystore: $Keystore"

& $Keytool -genkeypair -v `
    -keystore $Keystore `
    -alias upload `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -storepass $Password `
    -keypass $Password `
    -dname "CN=Inkwell, OU=Mobile, O=DevPlus Systems, L=US, ST=US, C=US"

if ($LASTEXITCODE -ne 0) {
    Write-Error "keytool failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

$keyPropertiesContent = @"
storePassword=$Password
keyPassword=$Password
keyAlias=upload
storeFile=../key/comicEditor_app-keystore.jks
"@

[System.IO.File]::WriteAllText($KeyProperties, $keyPropertiesContent.TrimEnd() + "`n")

$credentialsContent = @"
INKWELL ANDROID UPLOAD KEY — KEEP PRIVATE
=========================================

Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Keystore: key/comicEditor_app-keystore.jks
Alias: upload
Store password: $Password
Key password: $Password

BACK UP this file and the .jks file offline. You need both for every Play Store update.
Never commit these to git (already in .gitignore).

Build release bundle:
  cd $ProjectRoot
  flutter build appbundle --release
"@

[System.IO.File]::WriteAllText($CredentialsFile, $credentialsContent.TrimEnd() + "`n")

Write-Host ""
Write-Host "Release signing configured."
Write-Host "  android/key.properties  — written"
Write-Host "  key/SIGNING_CREDENTIALS.txt — password backup (save offline!)"
Write-Host ""
Write-Host "Next: flutter build appbundle --release"
