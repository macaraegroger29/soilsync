$zipPath = "C:\Users\jao\Downloads\commandlinetools-win-14742923_latest.zip"
$extractPath = "C:\AndroidSDK"
$cmdlineToolsPath = "$extractPath\cmdline-tools\latest"

# 1. Create target directory
if (!(Test-Path $extractPath)) { New-Item -ItemType Directory -Path $extractPath | Out-Null }

# 2. Extract to a temp directory first to rearrange correctly
$tempDir = "$extractPath\temp_extract"
if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
New-Item -ItemType Directory -Path $tempDir | Out-Null

Write-Host "Extracting zip file..."
Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

Write-Host "Moving files to the correct directory structure..."
if (!(Test-Path "$extractPath\cmdline-tools")) { New-Item -ItemType Directory -Path "$extractPath\cmdline-tools" | Out-Null }
if (Test-Path $cmdlineToolsPath) { Remove-Item -Recurse -Force $cmdlineToolsPath }
Rename-Item -Path "$tempDir\cmdline-tools" -NewName "latest"
Move-Item -Path "$tempDir\latest" -Destination "$extractPath\cmdline-tools\"

Remove-Item -Recurse -Force $tempDir

# 3. Install required SDK components
$sdkmanager = "$cmdlineToolsPath\bin\sdkmanager.bat"

Write-Host "Accepting licenses..."
"y`ny`ny`ny`ny`ny`ny`ny`ny`ny`n" | Out-File -FilePath "C:\AndroidSDK\y.txt" -Encoding ascii
cmd.exe /c "$sdkmanager --licenses < C:\AndroidSDK\y.txt"

Write-Host "Installing platform-tools, platforms;android-34, build-tools;34.0.0..."
cmd.exe /c "$sdkmanager `"platform-tools`" `"platforms;android-34`" `"build-tools;34.0.0`" < C:\AndroidSDK\y.txt"

Write-Host "Accepting licenses again just in case..."
cmd.exe /c "$sdkmanager --licenses < C:\AndroidSDK\y.txt"

# 4. Configure Flutter
Write-Host "Configuring Flutter to use the new Android SDK..."
$flutter = "C:\Users\jao\projects\flutter\bin\flutter.bat"
& $flutter config --android-sdk $extractPath

Write-Host "Setup complete!"
