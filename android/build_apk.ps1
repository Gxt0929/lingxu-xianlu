# Lingxu Xianlu APK build script (manual aapt2/d8 pipeline, no Gradle)
# All output ASCII to avoid PowerShell 5.1 encoding issues.
param()
$ErrorActionPreference = 'Stop'

$root    = 'd:\demogame1\demo1'
$andr    = Join-Path $root 'android'
$bt      = Join-Path $andr 'sdk\android-13'   # build-tools r33.0.2 + platform-33 merged
$build   = Join-Path $andr 'build'
$dist    = Join-Path $root 'dist'

$KS      = Join-Path $andr 'lingxu.keystore'
$KS_PASS = 'Lingxu@2026'
$KS_ALIAS= 'lingxu'

Write-Host '[1/8] prepare dirs'
New-Item -ItemType Directory -Force -Path $build, $dist | Out-Null

Write-Host '[2/8] sync assets'
New-Item -ItemType Directory -Force -Path (Join-Path $andr 'assets\fonts') | Out-Null
Copy-Item (Join-Path $root 'index.html') (Join-Path $andr 'assets\index.html') -Force
Copy-Item (Join-Path $root 'fonts\ZhiMangXing-Regular.ttf') (Join-Path $andr 'assets\fonts\ZhiMangXing-Regular.ttf') -Force

Write-Host '[3/8] aapt2 compile resources'
& "$bt\aapt2.exe" compile --dir (Join-Path $andr 'res') -o (Join-Path $build 'res.zip')
if ($LASTEXITCODE -ne 0) { throw "aapt2 compile failed" }

Write-Host '[4/8] aapt2 link'
& "$bt\aapt2.exe" link `
    -o (Join-Path $build 'base.apk') `
    -I (Join-Path $bt 'android.jar') `
    --manifest (Join-Path $andr 'AndroidManifest.xml') `
    --min-sdk-version 21 --target-sdk-version 33 `
    --auto-add-overlay `
    -A (Join-Path $andr 'assets') `
    (Join-Path $build 'res.zip')
if ($LASTEXITCODE -ne 0) { throw "aapt2 link failed" }

Write-Host '[5/8] javac'
$classes = Join-Path $build 'classes'
New-Item -ItemType Directory -Force -Path $classes | Out-Null
& javac --release 11 -encoding UTF-8 -classpath (Join-Path $bt 'android.jar') -d $classes (Join-Path $andr 'java\com\lingxu\xianlu\MainActivity.java')
if ($LASTEXITCODE -ne 0) { throw "javac failed" }

Write-Host '[6/8] d8 dex'
# JDK 9+ removed -Djava.ext.dirs (old d8.bat relies on it); call d8.jar directly
& java -cp "$bt\lib\d8.jar" com.android.tools.r8.D8 --release --min-api 21 --lib (Join-Path $bt 'android.jar') --output $build (Get-ChildItem $classes -Recurse -Filter *.class | ForEach-Object { $_.FullName })
if ($LASTEXITCODE -ne 0) { throw "d8 failed" }
if (-not (Test-Path (Join-Path $build 'classes.dex'))) { throw "classes.dex missing" }

Write-Host '[7/8] add classes.dex into apk + zipalign'
python (Join-Path $andr 'add_dex.py') (Join-Path $build 'base.apk') (Join-Path $build 'classes.dex') (Join-Path $build 'unaligned.apk')
if ($LASTEXITCODE -ne 0) { throw "add dex failed" }
& "$bt\zipalign.exe" -f 4 (Join-Path $build 'unaligned.apk') (Join-Path $build 'aligned.apk')
if ($LASTEXITCODE -ne 0) { throw "zipalign failed" }

Write-Host '[8/8] keystore + sign'
if (-not (Test-Path $KS)) {
    & keytool -genkeypair -keystore $KS -alias $KS_ALIAS -keyalg RSA -keysize 2048 `
        -validity 10950 -storepass $KS_PASS -keypass $KS_PASS `
        -dname 'CN=Lingxu Xianlu, OU=Lingxu, O=Lingxu, L=Beijing, ST=Beijing, C=CN'
    if ($LASTEXITCODE -ne 0) { throw "keytool failed" }
}
$signed = Join-Path $dist 'lingxu-xianlu.apk'
# apksigner.bat also uses removed -Djava.ext.dirs on old toolchains; use -jar form
& java -jar "$bt\lib\apksigner.jar" sign --ks $KS --ks-key-alias $KS_ALIAS --ks-pass "pass:$KS_PASS" --key-pass "pass:$KS_PASS" --min-sdk-version 21 --out $signed (Join-Path $build 'aligned.apk')
if ($LASTEXITCODE -ne 0) { throw "apksigner failed" }

& java -jar "$bt\lib\apksigner.jar" verify --print-certs $signed
if ($LASTEXITCODE -ne 0) { throw "verify failed" }
Write-Host "DONE: $signed"
