$javaHome = "C:\Program Files\Java\jdk-21"

# Set JAVA_HOME
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, [System.EnvironmentVariableTarget]::User)

# Add Java to PATH
$path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
$newPath = "$javaHome\bin;$path"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::User)

Write-Host "Java environment variables have been set up successfully!"
Write-Host "JAVA_HOME: $javaHome"
Write-Host "Please restart your terminal for the changes to take effect." 