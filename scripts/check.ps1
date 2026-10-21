# check.ps1 - alle aktiven Varianten bauen und gegen scripts\baseline.csv halten.
#
#   .\check.ps1              nur Synthese (quartus_map), schnell
#   .\check.ps1 -Fit         + Fitter + Timing-Analyse (Ressourcen und Slack)
#   .\check.ps1 -Full        voller Flow, erzeugt auch die .sof
#   .\check.ps1 -Variants hw2_cyclone_10
#   .\check.ps1 -All         auch Varianten mit Dormant = $true
#   .\check.ps1 -NoBaseline  nur messen, nicht vergleichen
#   .\check.ps1 -NoGen       die .qsf nicht vorher neu erzeugen
#
# Exit 0 = sauber, 1 = Buildfehler, 2 = Abweichung von der Baseline.
#
# ABNAHMEKRITERIUM sind die SYNTHESE-Zahlen aus map.rpt: Total combinational functions,
# Total registers, Total memory bits. Die sind eine Eigenschaft des Designs.
# Die LE-Zahl des FITTERS taugt NICHT dafuer - sie schwankt schon dann, wenn sich an der
# Platzierung etwas aendert (ein zusaetzlicher VIRTUAL_PIN reicht). Sie wird nur
# mitgefuehrt. Slack ist ebenfalls platzierungsabhaengig und wird mit Toleranz geprueft.
param(
    [string[]]$Variants,
    [switch]$Fit,
    [switch]$Full,
    [switch]$All,
    [switch]$NoBaseline,
    [switch]$NoGen
)

$ErrorActionPreference = 'Stop'

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot   = Split-Path -Parent $ScriptDir
$VarRoot    = Join-Path $RepoRoot 'variants'
$Project    = 'Bally'

# Quartus-Version je FPGA-Familie (FAMILY aus der erzeugten .qsf). Cyclone II kennt nur
# 13.0sp1; Cyclone IV E und Cyclone 10 LP bauen mit 22.1std - auch die F17-Variante, die bis
# 10.2026 mit 13.0sp1 gebaut wurde. DEFAULT gilt, wenn nichts passt. quartus_sh liegt nicht
# im PATH; C:\intelFPGA\23.1std ist auf dieser Maschine nur der Programmer.
$QuartusBin = [ordered]@{
    'Cyclone II' = 'C:\altera\13.0sp1\quartus\bin64'
    'DEFAULT'    = 'C:\intelFPGA_lite\22.1std\quartus\bin64'
}

function Get-QuartusBin([string]$Family) {
    foreach ($key in $QuartusBin.Keys) {
        if ($key -eq 'DEFAULT') { continue }
        if ($Family -eq $key) { return $QuartusBin[$key] }
    }
    return $QuartusBin['DEFAULT']
}

# Gemessene Streuung des Slack bei byte-gleichen Quellen liegt ueber 1 ns, deshalb
# Toleranz statt Gleichheit - plus ein absoluter Boden.
#
# Der Boden ist PROJEKTSPEZIFISCH. Verglichen wird der schlechteste Slack ueber alle
# Analysearten, und das ist bei BallyFA ein HOLD-Wert auf clk_out (der durch 100 geteilte
# CPU-Takt aus cpu_clk_gen, ein Ripple-Takt): Cyclone IV/10 um +0,1 ns, Cyclone II
# NEGATIV (-1,7 / -1,8 ns, Slow Model Hold 'clk_out') - und das schon im alten Stand vor
# dem Umbau, siehe VARIANTEN.md. Der Boden meldet deshalb nur, wenn eine Variante NEU unter
# ihn faellt; eine Variante, deren Baseline schon darunter liegt, wird nur ueber die
# Toleranz gegen ihre Baseline geprueft.
$SlackTolerance = 1.5
$SlackFloor     = 0.05

if (-not $NoGen) { & (Join-Path $ScriptDir 'gen_qsf.ps1') -Quiet }

function Get-FirstNumber([string]$Text) {
    # "4,273 / 6,272 ( 68 % )" -> 4273
    if ($Text -match '([\d,]+)') { return [int]($Matches[1] -replace ',', '') }
    return $null
}

function Get-ReportValue([string]$Path, [string]$Label) {
    if (-not (Test-Path $Path)) { return $null }
    $m = Select-String -Path $Path -Pattern ("^;\s+" + [regex]::Escape($Label) + "\s+;\s+(.*?)\s*;") | Select-Object -First 1
    if (-not $m) { return $null }
    return Get-FirstNumber $m.Matches[0].Groups[1].Value
}

function Get-SynthNumbers([string]$MapPath) {
    return [pscustomobject]@{
        Comb = Get-ReportValue $MapPath 'Total combinational functions'
        Reg  = Get-ReportValue $MapPath 'Total registers'
        Mem  = Get-ReportValue $MapPath 'Total memory bits'
    }
}

function Get-WorstSlack([string]$StaSummary) {
    # Das .summary-Format ist stabiler als die Tabellen der .sta.rpt:
    #   Type  : Slow 1200mV 85C Model Hold 'clk_50'
    #   Slack : 0.402
    if (-not (Test-Path $StaSummary)) { return $null }
    $worst = $null
    foreach ($line in Get-Content $StaSummary) {
        if ($line -match '^Slack\s+:\s+(-?\d+(?:\.\d+)?)') {
            $v = [double]$Matches[1]
            if ($null -eq $worst -or $v -lt $worst) { $worst = $v }
        }
    }
    return $worst
}

function Get-Messages([string]$Dir) {
    # Zeilennummern und Dateipfade wegwerfen - sonst meldet jeder Vergleich eine
    # Aenderung, sobald sich im Top-Level eine Zeile verschoben hat.
    #
    # Gezaehlt werden nur map/fit/sta - die asm.rpt gibt es nur nach einem vollen Flow
    # (build.ps1), und eine liegengebliebene wuerde mitgezaehlt.
    # 113007/113009/113015 ("elektra.hex" byte- statt wortadressiert bzw. "too wide ... wrapping")
    # erscheinen nur, wenn Quartus die Init-Datei NEU einliest; liegt sie schon in db\,
    # fehlen sie. Gemessen
    # 21.10.2026: derselbe Quellstand ergab je nach db-Zustand 37 oder 27 Meldungen.
    $volatile = @('113007', '113009', '113015')
    $ids = @()
    foreach ($f in @("$Project.map.rpt", "$Project.fit.rpt", "$Project.sta.rpt")) {
        $p = Join-Path $Dir $f
        if (-not (Test-Path $p)) { continue }
        foreach ($m in Select-String -Path $p -Pattern '^\s*(Critical Warning|Warning) \((\d+)\):') {
            if ($volatile -contains $m.Matches[0].Groups[2].Value) { continue }
            $ids += $m.Matches[0].Groups[2].Value
        }
    }
    return $ids
}

# --- Varianten einsammeln ---------------------------------------------------
$dirs = Get-ChildItem $VarRoot -Directory | Where-Object { Test-Path (Join-Path $_.FullName "$Project.qpf") }
if ($Variants) { $dirs = $dirs | Where-Object { $Variants -contains $_.Name } }
if (-not $All -and -not $Variants) {
    $dirs = $dirs | Where-Object {
        $m = Import-PowerShellDataFile (Join-Path $_.FullName 'variant.psd1')
        -not $m.Dormant
    }
}
if (-not $dirs) { throw "keine Varianten gefunden" }

# --- Baseline ---------------------------------------------------------------
$base = @{}
$baseFile = Join-Path $ScriptDir 'baseline.csv'
if (-not $NoBaseline -and (Test-Path $baseFile)) {
    Import-Csv $baseFile -Delimiter ';' | ForEach-Object { $base[$_.Variant] = $_ }
}

$mode = if ($Full) { 'full' } elseif ($Fit) { 'fit' } else { 'map' }
Write-Host "Modus: $mode" -ForegroundColor Cyan

$rows  = @()
$anyFail  = $false
$anyDrift = $false

foreach ($dir in $dirs) {
    $qsf    = Join-Path $dir.FullName "$Project.qsf"
    $family = if ((Get-Content $qsf -Raw) -match '-name FAMILY\s+"?([^"\r\n]+)"?') { $Matches[1].Trim() } else { '?' }
    $device = if ((Get-Content $qsf -Raw) -match '-name DEVICE\s+(\S+)')           { $Matches[1] }        else { '?' }

    $bin = Get-QuartusBin $family
    Write-Host ("  {0,-20} {1,-14} {2}" -f $dir.Name, $family, $bin)

    $status = 'OK'
    $firstError = ''
    Push-Location $dir.FullName
    try {
        $steps = switch ($mode) {
            'map'  { @('quartus_map') }
            'fit'  { @('quartus_map', 'quartus_fit', 'quartus_sta') }
            'full' { @('quartus_sh') }
        }
        foreach ($step in $steps) {
            # KEIN 2>&1: Windows PowerShell 5.1 verpackt jede stderr-Zeile eines nativen
            # Programms in einen ErrorRecord und setzt $? auf false, auch bei Exitcode 0.
            # Quartus schreibt dort eine harmlose TBBmalloc-Notiz hin. stdout genuegt -
            # die "Error (...)"-Zeilen stehen ohnehin auch dort.
            $out = if ($step -eq 'quartus_sh') {
                & "$bin\quartus_sh.exe" --flow compile $Project
            } else {
                & "$bin\$step.exe" $Project
            }
            if ($LASTEXITCODE -ne 0) {
                $status = "FAILED ($step)"
                $firstError = ($out | Where-Object { $_ -match '^\s*Error \(' } | Select-Object -First 1)
                $anyFail = $true
                break
            }
        }
    }
    finally { Pop-Location }

    $outDir = Join-Path $dir.FullName 'output_files'
    $row = [ordered]@{
        Variant = $dir.Name; Device = $device; Status = $status
        Comb = ''; Reg = ''; Memory = ''; LEfit = ''; Slack = ''; Delta = ''; Meldungen = ''
    }

    if ($status -eq 'OK') {
        $n = Get-SynthNumbers (Join-Path $outDir "$Project.map.rpt")
        $row.Comb = $n.Comb; $row.Reg = $n.Reg; $row.Memory = $n.Mem
        $row.LEfit = Get-ReportValue (Join-Path $outDir "$Project.fit.rpt") 'Total logic elements'
        $msgs = Get-Messages $outDir
        $row.Meldungen = $msgs.Count

        $slack = $null
        if ($mode -ne 'map') {
            $slack = Get-WorstSlack (Join-Path $outDir "$Project.sta.summary")
            if ($null -ne $slack) { $row.Slack = '{0:0.000}' -f $slack }
        }

        if ($base.ContainsKey($dir.Name)) {
            $b = $base[$dir.Name]
            $d = @()
            if ($n.Comb -ne [int]$b.Comb) { $d += "Comb {0}->{1}" -f $b.Comb, $n.Comb }
            if ($n.Reg  -ne [int]$b.Reg)  { $d += "Reg {0}->{1}"  -f $b.Reg,  $n.Reg }
            if ($n.Mem  -ne [int]$b.Mem)  { $d += "Mem {0}->{1}"  -f $b.Mem,  $n.Mem }
            if ($null -ne $slack -and $b.Slack) {
                $bs = [double]$b.Slack
                if ([Math]::Abs($slack - $bs) -gt $SlackTolerance) { $d += "Slack {0:0.000}->{1:0.000}" -f $bs, $slack }
                if ($slack -lt $SlackFloor -and $bs -ge $SlackFloor) { $d += "Slack unter {0} ns" -f $SlackFloor }
            }
            if ($b.Meldungen -and $msgs.Count -ne [int]$b.Meldungen) { $d += "Meldungen {0}->{1}" -f $b.Meldungen, $msgs.Count }
            if ($d) { $row.Delta = ($d -join ', '); $anyDrift = $true }
        } else {
            $row.Delta = 'keine Baseline'
        }
    } elseif ($firstError) {
        $row.Delta = $firstError
    }

    $rows += [pscustomobject]$row
}

Write-Host ""
$rows | Format-Table -AutoSize
Write-Host ""

if ($anyFail)  { Write-Host "Buildfehler." -ForegroundColor Red;    exit 1 }
if ($anyDrift) { Write-Host "Abweichung von der Baseline. Wenn sie beabsichtigt ist: scripts\baseline.csv nachziehen UND die Note-Spalte begruenden." -ForegroundColor Yellow; exit 2 }
Write-Host "Alle Varianten sauber." -ForegroundColor Green
