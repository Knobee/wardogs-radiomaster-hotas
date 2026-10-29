<#
.SYNOPSIS
  Builds a Joystick Gremlin profile that routes an EdgeTX/RadioMaster radio through
  vJoy for WARDOGS helicopters, and optionally points the game's HOTAS bindings at vJoy.

.DESCRIPTION
  1. Looks up the DirectInput instance GUIDs of the radio and of vJoy device 1 in
     HKCU\...\MediaProperties\PrivateProperties\DirectInput (the same GUIDs Joystick
     Gremlin uses).
  2. Fills in gremlin\TX15.template.xml and gremlin\sa_flares.py and writes them to -OutDir.
  3. With -PatchIni: backs up GameUserSettings.ini and sets the Roll/Pitch/Throttle/Yaw
     bindings to vJoy axes 0/1/2/3, sensitivity 1.0, no deadzone, HOTAS on.
  4. With -GremlinExe: creates a desktop shortcut that starts Gremlin with the profile enabled.

  Plug the radio in (USB Joystick mode) and run joy.cpl once before running this,
  so Windows has registered it.

.EXAMPLE
  .\Install-WardogsHotas.ps1
.EXAMPLE
  .\Install-WardogsHotas.ps1 -PatchIni -GremlinExe "$env:USERPROFILE\Desktop\Gremlin\Joystick.Gremlin.R16\joystick_gremlin.exe"
#>
[CmdletBinding()]
param(
  # USB VID/PID of the radio. Every EdgeTX radio uses 1209:4F54.
  [string]$VidPid = 'VID_1209&PID_4F54',
  [string]$OutDir = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WardogsHotas'),
  [switch]$PatchIni,
  [string]$IniPath = (Join-Path $env:LOCALAPPDATA 'Wardogs\Saved\Config\WindowsClient\GameUserSettings.ini'),
  [string]$GremlinExe
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$diRoot = 'HKCU:\System\CurrentControlSet\Control\MediaProperties\PrivateProperties\DirectInput'
$oemRoot = 'HKCU:\System\CurrentControlSet\Control\MediaProperties\PrivateProperties\Joystick\OEM'

function Get-DirectInputGuid([string]$vidPid) {
  $key = Join-Path $diRoot "$vidPid\Calibration\0"
  if (-not (Test-Path $key)) { return $null }
  $bytes = (Get-ItemProperty $key).GUID
  if (-not $bytes) { return $null }
  ([guid][byte[]]$bytes).ToString()
}

function Get-OemName([string]$vidPid) {
  $key = Join-Path $oemRoot $vidPid
  if (Test-Path $key) { (Get-ItemProperty $key).OEMName } else { $null }
}

$radioGuid = Get-DirectInputGuid $VidPid
if (-not $radioGuid) { throw "No DirectInput entry for $VidPid. Plug the radio in (USB Joystick mode), open joy.cpl once, then retry." }
$vjoyGuid = Get-DirectInputGuid 'VID_1234&PID_BEAD'
if (-not $vjoyGuid) { throw 'No DirectInput entry for vJoy (VID_1234&PID_BEAD). Install vJoy, enable device 1 in "Configure vJoy", then retry.' }
# DirectInput (and therefore Gremlin) reports the cached OEM name, which may be the
# name of a different EdgeTX radio that was plugged in first. That is harmless.
$radioName = Get-OemName $VidPid
if (-not $radioName) { $radioName = 'EdgeTX Joystick' }

Write-Host "Radio : $radioName  {$radioGuid}"
Write-Host "vJoy  : {$vjoyGuid}"

New-Item -ItemType Directory -Force $OutDir | Out-Null
$scriptPath = Join-Path $OutDir 'sa_flares.py'
$profilePath = Join-Path $OutDir 'WardogsHotas.xml'
$utf8 = New-Object System.Text.UTF8Encoding $false

$py = (Get-Content (Join-Path $repo 'gremlin\sa_flares.py') -Raw).Replace('__RADIO_GUID__', $radioGuid).Replace('__RADIO_NAME__', $radioName)
[IO.File]::WriteAllText($scriptPath, $py, $utf8)

$xml = (Get-Content (Join-Path $repo 'gremlin\TX15.template.xml') -Raw)
$xml = $xml.Replace('__RADIO_GUID__', $radioGuid).Replace('__VJOY_GUID__', $vjoyGuid).Replace('__SCRIPT_PATH__', $scriptPath)
$xml = $xml.Replace('__RADIO_NAME__', [Security.SecurityElement]::Escape($radioName))
[IO.File]::WriteAllText($profilePath, $xml, $utf8)
Write-Host "Wrote $profilePath"
Write-Host "Wrote $scriptPath"

if ($PatchIni) {
  if (Get-Process | Where-Object { $_.ProcessName -match 'wardogs' }) { throw 'WARDOGS is running. Close it first - the game rewrites the .ini on exit.' }
  if (-not (Test-Path $IniPath)) { throw "Not found: $IniPath (start the game once so it creates it)" }
  $backup = "$IniPath.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
  Copy-Item $IniPath $backup
  $reader = New-Object System.IO.StreamReader($IniPath, $true)
  $text = $reader.ReadToEnd(); $enc = $reader.CurrentEncoding; $reader.Close()

  # The first field after DeviceIdentifier is the axis index; its obfuscated name may
  # change between game versions, so match it by position rather than by name.
  $axes = [ordered]@{ Roll = 0; Pitch = 1; Throttle = 2; Yaw = 3 }
  foreach ($k in $axes.Keys) {
    $pattern = "(?m)^($k=\(DeviceIdentifier="")[^""]*("",_[a-z]+=)-?\d+"
    if (-not [regex]::IsMatch($text, $pattern)) { throw "Could not find the $k binding in $IniPath - bind any axis to $k in-game once, then retry." }
    $text = [regex]::Replace($text, $pattern, "`${1}1234:BEAD:vJoy Device`${2}$($axes[$k])")
    $text = [regex]::Replace($text, "(?m)^($k=\(.*,Sensitivity=)[\d.]+,DeadZone=[\d.]+\)\s*$", '${1}1.000000,DeadZone=0.000000)')
  }
  $text = [regex]::Replace($text, '(?m)^bUseHOTASHelicopters=\w+', 'bUseHOTASHelicopters=True')
  [IO.File]::WriteAllText($IniPath, $text, $enc)
  Write-Host "Patched $IniPath (backup: $backup)"
}

if ($GremlinExe) {
  if (-not (Test-Path $GremlinExe)) { throw "Not found: $GremlinExe" }
  $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'WARDOGS HOTAS (Gremlin).lnk'
  $shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
  $shortcut.TargetPath = $GremlinExe
  $shortcut.Arguments = "--profile `"$profilePath`" --enable --start-minimized"
  $shortcut.WorkingDirectory = Split-Path $GremlinExe
  $shortcut.Save()
  Write-Host "Created shortcut $lnk"
}
