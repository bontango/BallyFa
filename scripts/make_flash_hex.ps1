<#
.SYNOPSIS
  Builds the Intel HEX file with the game ROMs for the configuration flash
  (HAS_FLASH_ROM, rtl/common/Flash_ROM.vhd). BallyFA version, after WillFA7.

.DESCRIPTION
  The SD card stays the one source of the game data. This script takes it - an image of
  the whole card (as written by _make_SD.bat) or the 8 KByte slot files - and lays it
  out in the configuration flash, byte for byte the same slots:

      card    sector 660 + n * 16    game n, 8 KByte (SD_Card.vhd)
      flash   080000h + n * 2000h    game n, 8 KByte (Flash_ROM.vhd)

  The EPCS16 of the Cyclone IV / Cyclone 10 boards holds slots 0..191 behind the
  bitstream reserve (080000h..1FFFFFh); Flash_ROM.vhd reports error 8 above. Cyclone II
  has no flash fallback.

  Where the games end: _make_SD.bat writes the games to slot 0..n-1 and a text sector
  "this is SD image v<nnn>" right behind them (image 111: 142 games, the marker in slot
  142). Everything behind the marker is whatever the card held before - not games. The
  script stops at the marker (or after -Games slots), so those slots stay erased in the
  flash and Flash_ROM.vhd reports error 8 for them instead of running old card data.

  Slots that are completely FF or 00 are left out as well. A slot whose 6800 reset vector
  (offset 1FFEh/1FFFh) reads FFFF is written, but flagged.

  THE RESULT CONTAINS COPYRIGHTED GAME ROMS. Write it below output_files\ (ignored by
  git) and never into the released files. variants\<name>\bally_roms.cof expects it at
  output_files\bally_roms.hex; build.ps1 -RomHex does all of that.

.PARAMETER Image
  Image of a BallyFA SD card (raw sectors), e.g. roms\BallyFA_SD_111.img.

.PARAMETER SlotFiles
  The 8 KByte slot files in game order, game 0 first. Instead of -Image.

.PARAMETER Out
  The .hex file to write.

.PARAMETER Games
  How many games the card holds. Default: up to the "this is SD image" marker. Needed
  only for -Image without a marker; at most 192, what fits into the EPCS16 (Slot_Count
  in Flash_ROM.vhd).

.EXAMPLE
  .\make_flash_hex.ps1 -Image "..\..\roms\BallyFA_SD_111.img" -Out ..\variants\hw2_cyclone_10\output_files\bally_roms.hex
#>
param(
    [string]$Image,
    [string[]]$SlotFiles,
    [Parameter(Mandatory = $true)][string]$Out,
    [int]$Games = 0
)

$ErrorActionPreference = 'Stop'

# card layout, see rtl/common/SD_Card.vhd (sectorcount := gamenumber * 16 + 660)
$FirstSector = 660
$SlotBytes   = 8192       # 16 sectors
# flash layout, see rtl/common/Flash_ROM.vhd (Base_Addr, Slot_Bytes, Slot_Count)
$FlashBase   = 0x080000
$FlashEnd    = 0x200000   # EPCS16
$VecOffset   = 0x1FFE     # 6800 reset vector FFFEh in the 8 KByte image

$MaxSlots    = ($FlashEnd - $FlashBase) / $SlotBytes   # 192
$Marker      = [System.Text.Encoding]::ASCII.GetBytes('this is SD image')   # _make_SD.bat, behind the last game

if ($Games -gt $MaxSlots) { throw "$Games games do not fit into the EPCS16 (at most $MaxSlots)." }
if ((-not $Image) -and (-not $SlotFiles)) { throw 'Give -Image or -SlotFiles.' }
if ($Image -and $SlotFiles) { throw 'Give -Image or -SlotFiles, not both.' }

Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Text;
public static class BallyFAFlash {
    public static bool Blank(byte[] d, int off, int len) {
        byte f = d[off];
        if (f != 0xFF && f != 0x00) return false;
        for (int i = 1; i < len; i++) if (d[off + i] != f) return false;
        return true;
    }
    static void Rec(StringBuilder sb, int type, int addr, byte[] d, int off, int len) {
        int sum = len + ((addr >> 8) & 0xFF) + (addr & 0xFF) + type;
        sb.AppendFormat(":{0:X2}{1:X4}{2:X2}", len, addr & 0xFFFF, type);
        for (int i = 0; i < len; i++) { sb.AppendFormat("{0:X2}", d[off + i]); sum += d[off + i]; }
        sb.AppendFormat("{0:X2}\r\n", (-sum) & 0xFF);
    }
    // Intel HEX with type 04 records for the upper address half, absolute addresses.
    public static void Data(StringBuilder sb, int addr, byte[] d, int off, int len) {
        int upper = -1;
        for (int p = 0; p < len; p += 16) {
            int a = addr + p;
            if ((a >> 16) != upper) {
                upper = a >> 16;
                Rec(sb, 4, 0, new byte[] { (byte)(upper >> 8), (byte)upper }, 0, 2);
            }
            Rec(sb, 0, a, d, off + p, Math.Min(16, len - p));
        }
    }
    public static void End(StringBuilder sb) { Rec(sb, 1, 0, new byte[0], 0, 0); }
}
'@

$slotData = New-Object System.Collections.Generic.List[byte[]]
if ($Image) {
    $img = [System.IO.File]::ReadAllBytes((Resolve-Path $Image))
    $found = $false
    for ($n = 0; $n -lt 256; $n++) {
        if ($Games -gt 0 -and $n -ge $Games) { break }
        $off = ($FirstSector * 512) + ($n * $SlotBytes)
        if ($off + $SlotBytes -gt $img.Length) { break }
        # the marker sector ends the games - behind it is old card data
        $isMarker = $true
        for ($i = 0; $i -lt $Marker.Length; $i++) { if ($img[$off + $i] -ne $Marker[$i]) { $isMarker = $false; break } }
        if ($isMarker) {
            $text = [System.Text.Encoding]::ASCII.GetString($img, $off, 32).Split("`r")[0]
            Write-Host ('slot {0,3}: "{1}" - end of the games' -f $n, $text)
            $found = $true
            break
        }
        if ($n -ge $MaxSlots) { throw "The image holds more than $MaxSlots games - they do not fit into the EPCS16." }
        $s = New-Object byte[] $SlotBytes
        [Array]::Copy($img, $off, $s, 0, $SlotBytes)
        $slotData.Add($s)
    }
    if (-not $found -and $Games -eq 0) { throw 'No "this is SD image" marker found - give the number of games with -Games.' }
} else {
    if ($SlotFiles.Count -gt $MaxSlots) { throw "$($SlotFiles.Count) slot files do not fit into the EPCS16 (at most $MaxSlots)." }
    for ($n = 0; $n -lt $SlotFiles.Count; $n++) {
        $s = [System.IO.File]::ReadAllBytes((Resolve-Path $SlotFiles[$n]))
        if ($s.Length -ne $SlotBytes) { throw "$($SlotFiles[$n]) is $($s.Length) bytes, a slot is $SlotBytes." }
        $slotData.Add($s)
    }
}
if ($slotData.Count -eq 0) { throw 'No slot found.' }

$sb = New-Object System.Text.StringBuilder
$written = 0
$warn = 0
for ($n = 0; $n -lt $slotData.Count; $n++) {
    $s = $slotData[$n]
    $addr = $FlashBase + $n * $SlotBytes
    if ([BallyFAFlash]::Blank($s, 0, $SlotBytes)) {
        Write-Host ('slot {0,3}: empty, left out' -f $n) -ForegroundColor DarkGray
        continue
    }
    $vec = ([int]$s[$VecOffset] -shl 8) -bor $s[$VecOffset + 1]
    $line = 'slot {0,3}: {1:X6}  vector {2:X4}' -f $n, $addr, $vec
    if ($vec -eq 0xFFFF) {
        Write-Host ('{0}  - Flash_ROM will report error 8' -f $line) -ForegroundColor Yellow
        $warn++
    }
    [BallyFAFlash]::Data($sb, $addr, $s, 0, $SlotBytes)
    $written++
}
[BallyFAFlash]::End($sb)

if ([System.IO.Path]::IsPathRooted($Out)) { $outFull = $Out }
else { $outFull = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Out)) }
$dir = Split-Path $outFull
if (-not (Test-Path $dir)) { $null = New-Item -ItemType Directory -Path $dir }
[System.IO.File]::WriteAllText($outFull, $sb.ToString(), (New-Object System.Text.ASCIIEncoding))
Write-Host ('{0} games written to {1} (flash 080000h..{2:X6})' -f $written, $outFull, ($FlashBase + $slotData.Count * $SlotBytes - 1))
if ($warn -gt 0) { Write-Host ('{0} slot(s) with reset vector FFFF, see above' -f $warn) -ForegroundColor Yellow }
