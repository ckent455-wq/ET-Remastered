param([Parameter(Mandatory=$true)][string]$Plan,[switch]$ValidateOnly,[switch]$NoLaunch)
$ErrorActionPreference='Stop'
$updatePlan=Get-Content -LiteralPath $Plan -Raw -Encoding UTF8 | ConvertFrom-Json
$updateRoot=[IO.Path]::GetFullPath((Split-Path -Parent $Plan))
$resultPath=Join-Path $updateRoot 'result.json'
$updateLog=Join-Path $updateRoot 'install.log'
$copiedFiles=New-Object 'System.Collections.Generic.List[string]'
$backedFiles=New-Object 'System.Collections.Generic.List[string]'
$backupRoot=$null
function Record-Result([bool]$Success,[string]$Message) {
 $report=@{ok=$Success;message=$Message;version=$updatePlan.version} | ConvertTo-Json
 [IO.File]::WriteAllText($resultPath,$report,[Text.Encoding]::UTF8)
 try { [IO.File]::AppendAllText($updateLog,((Get-Date).ToString('s')+' '+$Message+[Environment]::NewLine),[Text.Encoding]::UTF8) } catch { }
}
try {
 $archivePath=[IO.Path]::GetFullPath([string]$updatePlan.archive)
 $targetRoot=[IO.Path]::GetFullPath([string]$updatePlan.target).TrimEnd('\','/')
 if ($targetRoot -eq [IO.Path]::GetPathRoot($targetRoot).TrimEnd('\','/')) { throw 'Installation folder cannot be a drive root.' }
 if (-not (Test-Path -LiteralPath (Join-Path $targetRoot 'FarFromHome.exe') -PathType Leaf) -or -not (Test-Path -LiteralPath (Join-Path $targetRoot 'FarFromHome.pck') -PathType Leaf)) { throw 'Target must be an existing portable Far From Home installation.' }
 if ([string]$updatePlan.version -notmatch '^\d{1,6}\.\d{1,6}\.\d{1,6}$') { throw 'Invalid release version.' }
 if ([string]$updatePlan.sha256 -notmatch '^[a-fA-F0-9]{64}$') { throw 'Missing archive checksum.' }
 if ((Get-Item -LiteralPath $archivePath).Length -ne [long]$updatePlan.size) { throw 'Archive download is incomplete.' }
 if ((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash -ne [string]$updatePlan.sha256) { throw 'Archive checksum mismatch.' }
 Add-Type -AssemblyName System.IO.Compression.FileSystem
 $stageRoot=Join-Path $updateRoot ('stage-'+[guid]::NewGuid().ToString('N'))
 New-Item -ItemType Directory -Path $stageRoot | Out-Null
 $expectedPrefix='FarFromHome-'+$updatePlan.version+'/'
 $zip=[IO.Compression.ZipFile]::OpenRead($archivePath)
 $packageFiles=New-Object 'System.Collections.Generic.List[string]'
 $seen=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
 $expandedTotal=[long]0
 try {
  foreach ($entry in $zip.Entries) {
   $name=$entry.FullName.Replace('\','/')
   if (-not $name.StartsWith($expectedPrefix,[StringComparison]::Ordinal)) { throw 'Unexpected package folder.' }
   $relative=$name.Substring($expectedPrefix.Length)
   if ($relative -eq '') { continue }
   if ($relative.Contains(':') -or $relative.StartsWith('/') -or ($relative.Split('/') -contains '..') -or ($relative.Split('/') -contains '.')) { throw 'Unsafe path in archive.' }
   if ($relative.EndsWith('/')) { continue }
   if ((($entry.ExternalAttributes -shr 16) -band 61440) -eq 40960) { throw 'Links are not allowed in update packages.' }
   if (-not $seen.Add($relative)) { throw 'Duplicate path in archive.' }
   $allowedRoot=$relative -match '^(FarFromHome\.exe|FarFromHome\.pck|build-info\.json|README\.md|CREDITS\.md|[a-zA-Z0-9_.-]+\.dll)$'
   $allowedLicense=$relative -match '^LICENSES/[a-zA-Z0-9_.-]+\.txt$'
   if (-not ($allowedRoot -or $allowedLicense)) { throw ('Unexpected update file: '+$relative) }
   $expandedTotal+=$entry.Length
   if ($entry.Length -gt 1073741824 -or $expandedTotal -gt 2147483648) { throw 'Update package is too large.' }
   $destination=[IO.Path]::GetFullPath((Join-Path $stageRoot $relative))
   if (-not $destination.StartsWith($stageRoot+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Path escapes the staging folder.' }
   [IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
   [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$destination,$false)
   $packageFiles.Add($relative)
  }
 } finally { $zip.Dispose() }
 $info=Get-Content -LiteralPath (Join-Path $stageRoot 'build-info.json') -Raw -Encoding UTF8 | ConvertFrom-Json
 if ($info.game -ne 'Far From Home' -or $info.version -ne $updatePlan.version -or $info.platform -ne 'Windows x86_64') { throw 'Build information does not match this release.' }
 foreach ($required in @('FarFromHome.exe','FarFromHome.pck')) {
  $digest=[string]$info.sha256.$required
  if ($digest -notmatch '^[a-fA-F0-9]{64}$' -or (Get-FileHash -LiteralPath (Join-Path $stageRoot $required) -Algorithm SHA256).Hash -ne $digest) { throw ('Build file checksum mismatch: '+$required) }
 }
 # Reject junctions/symlinks in the install tree before any copying.
 foreach ($relative in $packageFiles) {
  $probe=Join-Path $targetRoot $relative
  while ($probe -and $probe.Length -ge $targetRoot.Length) {
   if ((Test-Path -LiteralPath $probe) -and ((Get-Item -LiteralPath $probe -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Installation paths cannot contain links or junctions.' }
   if ($probe -eq $targetRoot) { break }
   $probe=Split-Path -Parent $probe
  }
 }
 if ($ValidateOnly) { Record-Result $true 'Update package validated; installation not changed.'; exit 0 }
 $oldProcess=Get-Process -Id ([int]$updatePlan.pid) -ErrorAction SilentlyContinue
 if ($oldProcess) { $oldProcess | Wait-Process -Timeout 60 }
 $backupRoot=Join-Path $targetRoot ('.ffh-update-backup-'+[guid]::NewGuid().ToString('N'))
 New-Item -ItemType Directory -Path $backupRoot | Out-Null
 # Copy the complete backup before replacing any installed file.
 foreach ($relative in $packageFiles) {
  $original=Join-Path $targetRoot $relative
  if (Test-Path -LiteralPath $original -PathType Leaf) {
   $backup=Join-Path $backupRoot $relative
   [IO.Directory]::CreateDirectory((Split-Path -Parent $backup)) | Out-Null
   Copy-Item -LiteralPath $original -Destination $backup
   $backedFiles.Add($relative)
  }
 }
 foreach ($relative in $packageFiles) {
  $destination=Join-Path $targetRoot $relative
  [IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
  $copiedFiles.Add($relative)
  Copy-Item -LiteralPath (Join-Path $stageRoot $relative) -Destination $destination -Force
 }
 foreach ($required in @('FarFromHome.exe','FarFromHome.pck')) {
  if ((Get-FileHash -LiteralPath (Join-Path $targetRoot $required) -Algorithm SHA256).Hash -ne [string]$info.sha256.$required) { throw 'Installed file verification failed.' }
 }
 Record-Result $true ('Updated to '+$updatePlan.version+'. Previous build saved in '+$backupRoot)
 if (-not $NoLaunch) { Start-Process -FilePath (Join-Path $targetRoot 'FarFromHome.exe') -WorkingDirectory $targetRoot -WindowStyle Normal | Out-Null }
} catch {
 $failure=$_.Exception.Message
 $rollbackErrors=New-Object 'System.Collections.Generic.List[string]'
 foreach ($relative in $copiedFiles) {
  $destination=Join-Path $targetRoot $relative
  try {
   if ($backedFiles.Contains($relative)) {
    $backup=Join-Path $backupRoot $relative
    $alreadyOriginal=(Test-Path -LiteralPath $destination -PathType Leaf) -and ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash)
    if (-not $alreadyOriginal) { Copy-Item -LiteralPath $backup -Destination $destination -Force }
   } elseif (Test-Path -LiteralPath $destination -PathType Leaf) { Remove-Item -LiteralPath $destination -Force }
  } catch { $rollbackErrors.Add($relative+': '+$_.Exception.Message) }
 }
 if ($rollbackErrors.Count -eq 0) { Record-Result $false ('Update failed; previous files restored. '+$failure) }
 else { Record-Result $false ('Update failed. Restore remaining files from '+$backupRoot+'. '+($rollbackErrors -join '; ')+'. '+$failure) }
 if (-not $ValidateOnly -and -not $NoLaunch -and (Test-Path -LiteralPath (Join-Path $targetRoot 'FarFromHome.exe') -PathType Leaf)) { Start-Process -FilePath (Join-Path $targetRoot 'FarFromHome.exe') -WorkingDirectory $targetRoot -WindowStyle Normal | Out-Null }
 exit 1
}
