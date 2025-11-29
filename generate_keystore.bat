@echo off
echo ================================
echo  KEYSTORE GENERATOR
echo  DDS Fire Alarm App
echo ================================
echo.

:: Check if keytool is available
keytool -help >nul 2>&1
if errorlevel 1 (
    echo [ERROR] keytool not found!
    echo Please make sure Java JDK is installed and in PATH.
    echo Download from: https://www.oracle.com/java/technologies/downloads/
    pause
    exit /b 1
)

:: Check if keystore already exists
if exist "upload-keystore.jks" (
    echo [WARNING] Keystore already exists!
    echo Backing up existing keystore to upload-keystore-backup.jks
    copy upload-keystore.jks upload-keystore-backup.jks
    echo.
)

echo Creating keystore for DDS Fire Alarm App...
echo.
echo Please enter the following information:
echo - Keystore password: ddsfirealarm2025
echo - Key password: ddsfirealarm2025
echo - Key alias: upload
echo.
echo For production, use your company's details!
echo.

keytool -genkey -v ^
    -keystore upload-keystore.jks ^
    -keyalg RSA ^
    -keysize 2048 ^
    -validity 10000 ^
    -storepass ddsfirealarm2025 ^
    -keypass ddsfirealarm2025 ^
    -alias upload ^
    -dname "CN=DDS Fire Alarm, OU=Security, O=DDS Solutions, L=Jakarta, ST=Indonesia, C=ID"

if errorlevel 1 (
    echo [ERROR] Failed to generate keystore!
    pause
    exit /b 1
)

echo.
echo [SUCCESS] Keystore generated successfully!
echo.
echo Keystore location: upload-keystore.jks
echo.
echo IMPORTANT:
echo 1. Add upload-keystore.jks to version control ignore
echo 2. Keep your keystore password secure
echo 3. Backup your keystore file safely
echo 4. Do NOT commit keystore to public repositories
echo.

pause