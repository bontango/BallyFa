# build.ps1 - eine Variante voll compilieren und (falls ReleaseArtifact = 'jic') die .jic erzeugen.
#
#   .\build.ps1 hw2_cyclone_iv_v4
#   .\build.ps1 hw1_cyclone_10 -NoJic
#
# Die Quartus-Version kommt aus FAMILY in der erzeugten .qsf (Cyclone II -> 13.0sp1, sonst
# 22.1std), dieselbe Tabelle wie in check.ps1.
#
# quartus_cpf laeuft mit dem VARIANTENORDNER als Arbeitsverzeichnis - deshalb sind die
# Pfade in Bally.cof relativ dazu (output_files/Bally.sof). Frueher waren sie absolut; die
# .cof der HW2-Cyclone-10-Variante zeigte zuletzt auf einen Ordner, den es nicht mehr gab.
# Cyclone II liefert die .pof direkt aus dem Assembler (USE_CONFIGURATION_DEVICE ON).
#
# -RomImage <SD-Kartenimage>: zusaetzlich die lokale ROM-Fassung (nur HAS_FLASH_ROM,
# also Cyclone IV/10): make_flash_hex.ps1 -> output_files\bally_roms.hex, dann
# quartus_cpf -c bally_roms.cof -> output_files\bally_roms.jic (Bitstream + Spiel-ROMs).
# ENTHAELT URHEBERRECHTLICH GESCHUETZTE ROMS - liegt unter output_files\ (gitignored).
param(
    [Parameter(Mandatory, Position = 0)][string]$Variant,
    [switch]$NoGen,
    [switch]$NoJic,
    [string]$RomImage
)

$ErrorActionPreference = 'Stop'

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot   = Split-Path -Parent $ScriptDir
$VarDir     = Join-Path (Join-Path $RepoRoot 'variants') $Variant
$Project    = 'Bally'

$QuartusBin = [ordered]@{
    'Cyclone II' = 'C:\altera\13.0sp1\quartus\bin64'
    'DEFAULT'    = 'C:\intelFPGA_lite\22.1std\quartus\bin64'
}

if (-not (Test-Path $VarDir)) { throw "unbekannte Variante: $Variant" }
# relativ zum Aufrufer, bevor ins Variantenverzeichnis gewechselt wird
if ($RomImage) { $RomImage = (Resolve-Path $RomImage).Path }

if (-not $NoGen) { & (Join-Path $ScriptDir 'gen_qsf.ps1') -Variants $Variant -Quiet }

$meta   = Import-PowerShellDataFile (Join-Path $VarDir 'variant.psd1')
$family = if ((Get-Content (Join-Path $VarDir "$Project.qsf") -Raw) -match '-name FAMILY\s+"?([^"\r\n]+)"?') { $Matches[1].Trim() } else { '' }
$bin    = if ($QuartusBin.Contains($family)) { $QuartusBin[$family] } else { $QuartusBin['DEFAULT'] }
Write-Host "Baue $Variant - $($meta.Title)  [$bin]" -ForegroundColor Cyan

Push-Location $VarDir
try {
    # KEIN 2>&1 - siehe check.ps1.
    & "$bin\quartus_sh.exe" --flow compile $Project
    if ($LASTEXITCODE -ne 0) { throw "quartus_sh --flow compile ist fehlgeschlagen ($LASTEXITCODE)" }

    $sof = Join-Path $VarDir "output_files\$Project.sof"
    if (-not (Test-Path $sof)) { throw "keine .sof erzeugt: $sof" }
    "  {0}  {1:N0} Byte" -f (Split-Path $sof -Leaf), (Get-Item $sof).Length

    if (-not $NoJic -and $meta.ReleaseArtifact -eq 'jic') {
        & "$bin\quartus_cpf.exe" -c "$Project.cof"
        if ($LASTEXITCODE -ne 0) { throw "quartus_cpf ist fehlgeschlagen ($LASTEXITCODE)" }
        $jic = Join-Path $VarDir "output_files\$Project.jic"
        if (-not (Test-Path $jic)) { throw "keine .jic erzeugt: $jic" }
        "  {0}  {1:N0} Byte" -f (Split-Path $jic -Leaf), (Get-Item $jic).Length
    }
    if ($RomImage) {
        if (-not (Test-Path (Join-Path $VarDir 'bally_roms.cof'))) { throw "$Variant hat keinen Flash-Fallback (keine bally_roms.cof)." }
        $hex = Join-Path $VarDir 'output_files\bally_roms.hex'
        & (Join-Path $ScriptDir 'make_flash_hex.ps1') -Image $RomImage -Out $hex
        & "$bin\quartus_cpf.exe" -c 'bally_roms.cof'
        if ($LASTEXITCODE -ne 0) { throw "quartus_cpf (bally_roms.cof) ist fehlgeschlagen ($LASTEXITCODE)" }
        $rjic = Join-Path $VarDir 'output_files\bally_roms.jic'
        if (-not (Test-Path $rjic)) { throw "keine bally_roms.jic erzeugt" }
        # Kontrolle in der .map: Bitstream ab 0, ROM-Block ab 080000h
        $map = Get-Content (Join-Path $VarDir 'output_files\bally_roms.map')
        if (-not ($map | Where-Object { $_ -match '^Page_0\s+0x00000000' })) { throw 'bally_roms.map: Page_0 beginnt nicht bei 0x00000000' }
        if (-not ($map | Where-Object { $_ -match '0x00080000' })) { throw 'bally_roms.map: kein Hex-Block ab 0x00080000' }
        "  {0}  {1:N0} Byte (MIT Spiel-ROMs, nicht weitergeben)" -f (Split-Path $rjic -Leaf), (Get-Item $rjic).Length
    }
    if ($meta.ReleaseArtifact -eq 'pof') {
        $pof = Join-Path $VarDir "output_files\$Project.pof"
        if (-not (Test-Path $pof)) { throw "keine .pof erzeugt: $pof" }
        "  {0}  {1:N0} Byte" -f (Split-Path $pof -Leaf), (Get-Item $pof).Length
    }
}
finally { Pop-Location }

Write-Host "fertig." -ForegroundColor Green
