$env:JAVA_HOME='C:\Program Files\Microsoft\jdk-21.0.10.7-hotspot'
$env:FLUTTER_ROOT='C:\Users\Admin\flutter\flutter'
$env:PATH="$env:JAVA_HOME\bin;$env:FLUTTER_ROOT\bin;$env:PATH"
$define=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('PAYI_API_BASE_URL=http://127.0.0.1:5088/api'))
Set-Location 'C:\Users\Admin\Desktop\PAYI\payi_mobile\android'
.\gradlew.bat --no-daemon :app:assembleDebug "-Pdart-defines=$define"
