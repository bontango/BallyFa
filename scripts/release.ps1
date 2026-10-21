# release.ps1 - Varianten bauen, die Artefakte nach bin\<FPGA-Board>\ legen, Changelog fortschreiben.
#
#   .\release.ps1 -Note "kurz, was diese Version aendert"
#   .\release.ps1 -Note "..." -Variants hw2_cyclone_10
#   .\release.ps1 -Note "..." -Force        vorhandene Datei ueberschreiben
#
# Die Versionsziffern kommen aus rtl\common\version_pkg.vhd (SW_SUB1/SW_SUB2) und
# variants\<n>\variant.psd1 (BoardId, ReleasePrefix). Ein Release aendert genau EINE Ziffer
# in version_pkg.vhd, alle acht Boards folgen.
#
# bin\ ist wie bei WillFA7 nach FPGA-Board geordnet (BinFolder in variant.psd1), die
# Basisplatine steht im Dateinamen:
#   bin\Cyclone_II\                  BallyFA_1xx.pof    BallyFA_2_1xx.pof
#   bin\Cyclone_IV\FPGA_board_v3.x\  BallyFA_2xx.jic    BallyFA_2_2xx.jic   (EP4CE6F17)
#   bin\Cyclone_IV\FPGA_board_v4.x\  BallyFA_3xx.jic    BallyFA_2_3xx.jic   (EP4CE6E22)
#   bin\cyclone_10\                  BallyFA_4xx.jic    BallyFA_2_4xx.jic
#   (HW 1.x: BallyFA_<BoardId><Sub1><Sub2>, HW 2.x: BallyFA_2_<BoardId><Sub1><Sub2>)
#
# -RomImage <SD-Kartenimage>: fuer die Varianten mit Flash-Fallback zusaetzlich
# <Name>_roms.jic daneben (Bitstream + Spiel-ROMs, siehe build.ps1). Diese Dateien sind
# gitignored und gehen nie zu GitHub (Urheberrecht); sie stehen nicht im Changelog.
param(
    [Parameter(Mandatory)][string]$Note,
    [string[]]$Variants,
    [switch]$Force,
    [string]$RomImage
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir
$VarRoot   = Join-Path $RepoRoot 'variants'
$BinRoot   = Join-Path $RepoRoot 'bin'
$Project   = 'Bally'

$verSrc = Get-Content (Join-Path $RepoRoot 'rtl\common\version_pkg.vhd') -Raw
if ($verSrc -notmatch 'SW_SUB1\s*:\s*std_logic_vector\(3 downto 0\)\s*:=\s*x"([0-9A-Fa-f])"') { throw 'SW_SUB1 nicht in version_pkg.vhd gefunden' }
$sub1 = $Matches[1]
if ($verSrc -notmatch 'SW_SUB2\s*:\s*std_logic_vector\(3 downto 0\)\s*:=\s*x"([0-9A-Fa-f])"') { throw 'SW_SUB2 nicht in version_pkg.vhd gefunden' }
$sub2 = $Matches[1]

$dirs = Get-ChildItem $VarRoot -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'variant.psd1') }
if ($Variants) { $dirs = $dirs | Where-Object { $Variants -contains $_.Name } }
else {
    $dirs = $dirs | Where-Object {
        $m = Import-PowerShellDataFile (Join-Path $_.FullName 'variant.psd1')
        -not $m.Dormant
    }
}
if (-not $dirs) { throw 'keine Varianten zu releasen' }

# Erst alle Zielnamen pruefen, dann bauen - sonst bricht ein Release nach drei von acht
# Varianten ab und hinterlaesst einen halben Stand in bin\.
$plan = @()
foreach ($dir in $dirs) {
    $meta = Import-PowerShellDataFile (Join-Path $dir.FullName 'variant.psd1')
    $target = Join-Path $BinRoot $meta.BinFolder
    $dest = Join-Path $target ("{0}{1}{2}{3}.{4}" -f $meta.ReleasePrefix, $meta.BoardId, $sub1, $sub2, $meta.ReleaseArtifact)
    if ((Test-Path $dest) -and -not $Force) {
        throw "$dest gibt es schon. Version in rtl\common\version_pkg.vhd hochziehen oder -Force benutzen."
    }
    $plan += [pscustomobject]@{ Dir = $dir; Meta = $meta; Target = $target; Dest = $dest }
}

$done = @()
foreach ($p in $plan) {
    if (-not (Test-Path $p.Target)) { New-Item -ItemType Directory $p.Target | Out-Null }
    $withRoms = $RomImage -and (Test-Path (Join-Path $p.Dir.FullName 'bally_roms.cof'))
    if ($withRoms) { & (Join-Path $ScriptDir 'build.ps1') $p.Dir.Name -RomImage $RomImage }
    else           { & (Join-Path $ScriptDir 'build.ps1') $p.Dir.Name }
    $src = Join-Path $p.Dir.FullName "output_files\$Project.$($p.Meta.ReleaseArtifact)"
    if (-not (Test-Path $src)) { throw "Artefakt fehlt: $src" }
    Copy-Item $src $p.Dest -Force
    if ($withRoms) {
        $rdest = $p.Dest -replace '\.jic$', '_roms.jic'
        Copy-Item (Join-Path $p.Dir.FullName 'output_files\bally_roms.jic') $rdest -Force
    }

    $sha = (Get-FileHash $p.Dest -Algorithm SHA256).Hash.Substring(0, 16)
    $hwPrefix = if ($p.Meta.HwGen -eq 2) { '2_' } else { '' }
    $done += [pscustomobject]@{
        Variant = $p.Dir.Name
        Version = "{0}{1}.{2}{3}" -f $hwPrefix, $p.Meta.BoardId, $sub1, $sub2
        File    = '{0}\{1}' -f $p.Meta.BinFolder, (Split-Path $p.Dest -Leaf)
        Sha     = $sha
    }
}

# Kopfzeile im gewachsenen Stil von bin\Changelog.txt ("-- Version 1.23 -(2.23 & 3.23)- <Text>"),
# darunter je Variante eine Nachweiszeile mit Artefakt und Pruefsumme. Die fehlte bisher -
# deshalb liess sich 2_323.jic (02.12.2024) nicht mehr eindeutig einem Quellstand zuordnen.
$log   = Join-Path $BinRoot 'Changelog.txt'
$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
$lines = @('', "-- Version x.$sub1$sub2 (alle Boards) $Note", "   $stamp")
foreach ($d in ($done | Sort-Object Variant)) {
    $lines += "   {0,-18} {1,-8} {2,-44} sha256:{3}" -f $d.Variant, $d.Version, $d.File, $d.Sha
}
Add-Content -Path $log -Value $lines -Encoding UTF8

$done | Format-Table -AutoSize
Write-Host "In $log fortgeschrieben." -ForegroundColor Green
Write-Host "Nicht vergessen: in VARIANTEN.md eintragen, welche Variante tatsaechlich auf Hardware getestet wurde." -ForegroundColor Yellow
