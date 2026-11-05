# Установка движка монтажа на Windows 10/11. Повторный запуск безопасен.
#   двойной щелчок по bin\setup.cmd  или  powershell -ExecutionPolicy Bypass -File bin\setup.ps1
#   Python 3.12 (winget)   — окружение engine\.venv с пакетом montage (расшифровка — faster-whisper)
#   ffmpeg (winget Gyan)   — полная сборка: zscale (HDR), libass (сабы), arnndn, loudnorm
#   Inter (OFL)            — шрифт сабов и карточек в папку шрифтов пользователя
# Модель расшифровки (large-v3-turbo, ~1,6 ГБ) скачивается сама при первом `bin/montage transcribe`.
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Engine = Join-Path $Root 'engine'
$Accept = @('--accept-package-agreements', '--accept-source-agreements')

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host 'нет winget: поставьте «Установщик приложений» (App Installer) из Microsoft Store и запустите снова'; exit 1
}

Write-Host '1/4 Python 3.12'
$py = Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'
if (-not (Test-Path $py)) { winget install -e --id Python.Python.3.12 --scope user @Accept }
if (-not (Test-Path $py)) { Write-Host "не нашёл $py — закройте окно, откройте заново и запустите снова"; exit 1 }

Write-Host '2/4 ffmpeg'
$links = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links'
$env:Path = "$env:Path;$links"
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) { winget install -e --id Gyan.FFmpeg @Accept }
$env:Path = "$env:Path;$links"
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) { Write-Host 'ffmpeg не виден — закройте окно, откройте заново и запустите снова'; exit 1 }
$filters = (& ffmpeg -hide_banner -filters 2>$null) -join "`n"
foreach ($f in 'zscale', 'ass', 'loudnorm') {
  if ($filters -notmatch " $f ") { Write-Host "в ffmpeg нет фильтра $f — нужна полная сборка: winget install -e --id Gyan.FFmpeg"; exit 1 }
}

Write-Host '3/4 engine\.venv + montage'
$venv = Join-Path $Engine '.venv'
if (-not (Test-Path $venv)) { & $py -m venv $venv }
$vpy = Join-Path $venv 'Scripts\python.exe'
& $vpy -m pip install -q --upgrade pip
& $vpy -m pip install -q -e $Engine
if ($LASTEXITCODE -ne 0) { Write-Host 'pip не поставил пакет — пришлите этот экран'; exit 1 }

Write-Host '4/4 шрифт Inter'
$fonts = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
New-Item -ItemType Directory -Force -Path $fonts | Out-Null
if (-not (Test-Path (Join-Path $fonts 'Inter-ExtraBold.ttf'))) {
  $tmp = Join-Path $env:TEMP ('inter-' + [guid]::NewGuid())
  New-Item -ItemType Directory -Path $tmp | Out-Null
  Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip' -OutFile "$tmp\inter.zip"
  Expand-Archive -Path "$tmp\inter.zip" -DestinationPath $tmp -Force
  $reg = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
  foreach ($w in 'Regular', 'SemiBold', 'Bold', 'ExtraBold') {
    Copy-Item "$tmp\extras\ttf\Inter-$w.ttf" $fonts -Force
    New-ItemProperty -Path $reg -Name "Inter $w (TrueType)" -Value (Join-Path $fonts "Inter-$w.ttf") -PropertyType String -Force | Out-Null
  }
  Remove-Item -Recurse -Force $tmp
}

New-Item -ItemType Directory -Force -Path (Join-Path $Root 'video\inbox'), (Join-Path $Root 'video\projects') | Out-Null
Write-Host ''
Write-Host 'готово. Проверка: bin/montage --help'
