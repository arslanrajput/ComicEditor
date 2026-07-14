# Generate Android upload keystore for Inkwell (Windows).
# Run in PowerShell from the project root:
#   .\scripts\generate-keystore.ps1
#
# You will be prompted for:
#   - Keystore password (remember this!)
#   - Key password (can match keystore password)
#   - Your name, organization, country, etc.

$ErrorActionPreference = "Stop"

$KeytoolCandidates = @(
    "$env:JAVA_HOME\bin\keytool.exe",
    "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe",
    "C:\Program Files\Java\jdk-17\bin\keytool.exe"
)

$Keytool = $KeytoolCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Keytool) {
    Write-Error "keytool not found. Install Android Studio or JDK 17+, or set JAVA_HOME."
    exit 1
}

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$KeystoreDir = Join-Path $ProjectRoot "key"
$Keystore = Join-Path $KeystoreDir "comicEditor_app-keystore.jks"

New-Item -ItemType Directory -Force -Path $KeystoreDir | Out-Null

Write-Host "Using keytool: $Keytool"
Write-Host "Keystore path: $Keystore"
Write-Host ""
Write-Host "After this finishes:"
Write-Host "  1. Copy android\key.properties.example -> android\key.properties"
Write-Host "  2. Fill in storePassword, keyPassword, and storeFile=../key/comicEditor_app-keystore.jks"
Write-Host ""

& $Keytool -genkey -v `
    -keystore $Keystore `
    -alias upload `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Keystore created successfully."
    Write-Host "Next: edit android\key.properties — set storePassword and keyPassword to the passwords you just entered."
    Write-Host "BACK UP key\comicEditor_app-keystore.jks and passwords — you cannot publish updates without them."
}
