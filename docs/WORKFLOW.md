# Arbeiten im BallyFA-Sourcebaum

## Was ändern → wo

| Ich will … | Datei |
|---|---|
| Logik ändern, die alle Boards betrifft | `top/Bally_core.vhd`, `rtl/common/*.vhd` |
| etwas ändern, das nur Basisplatine HW 1.x bzw. HW 2.x betrifft | `top/BallyFA_HW1.vhd` / `top/BallyFA_HW2.vhd` |
| ein neues Modul aufnehmen | Datei nach `rtl/common/`, Zeile in `scripts/files_common.tcl`. Nur bei einer Basisplatine: `scripts/files_hw<n>.tcl` |
| eine Version releasen | **eine** Ziffer in `rtl/common/version_pkg.vhd`, danach `scripts\release.ps1 -Note "..."` |
| einen Pin verlegen | `variants/<n>/pins.tcl` |
| einen Port zu einer Platine hinzufügen | Hülle (`top/BallyFA_HW<n>.vhd`), bei Bedarf Kern, **und** `pins.tcl` **jeder** Variante dieser Platine |
| ein Assignment für alle Boards (Pull-up, IO-Standard, …) | `scripts/common_header.tcl` |
| Device oder Quartus-Version eines Boards | `variants/<n>/device.tcl` |
| eine Megafunction neu generieren | in **jedem** `rtl/<familie>/` mit derselben Entity und Portliste; `init_file` relativ `../../rom/…` |
| ein neues FPGA-Board | neuen Ordner `variants/<n>/` (am besten einen bestehenden kopieren), dazu `BOARD_ID`, `pins.tcl`, `device.tcl` und `variant.psd1`; anschließend eine Zeile in `scripts/baseline.csv` |

## Regeln

- **`variants/<n>/Bally.qsf` ist generiert.** Was Quartus in der IDE hineinschreibt, ist
  beim nächsten `check.ps1`/`build.ps1` wieder weg (die Skripte melden es mit
  „außerhalb von gen_qsf verändert“). Willst du eine Einstellung behalten, gehört sie in ein
  Fragment.
- **Pfade sind relativ zu `variants/<n>/`**: `../../rtl/…`, `../../top/…`,
  `init_file => "../../rom/…"`. Die `.qip` sind ortsunabhängig, sie bleiben unverändert.
- **Kein `SEARCH_PATH`.** Jede Datei steht genau einmal in einer Liste.
- **Instanzname `core` nicht ändern.** `rtl/common/Bally.sdc` verweist auf
  `Bally_core:core|cpu_clk_gen:clock_gen|clk_out`. Ändert sich der Name, bricht die
  Constraint stumm.
- **Eingänge im Kern haben HW-1.x-Polarität.** Die HW-2.x-Hülle invertiert die sechs
  4049-Eingänge, bevor sie den Kern erreichen. Im Kern deshalb **kein** `not` vor `CV_CH`,
  `ZERO_CROSS`, `S33`, `U10_PB`, `U10_CA1`, `U11_CB1` ergänzen.
- **Kein VIRTUAL_PIN.** Die Cyclone-II-Varianten bauen mit Quartus 13.0sp1, und dort wirkt
  VIRTUAL_PIN nicht. Ports, die nur eine Platine hat, gehören in deren Hülle.
- PowerShell 5.1: **kein `2>&1` auf `quartus_*.exe`**. Git-Bash: **kein `sed -i`** auf
  Dateien dieses Baums, sonst ist CRLF kaputt.

## Prüfen

```powershell
powershell -File scripts\check.ps1 -Fit
```

Abnahmekriterium sind die **Synthese-Zahlen** (Comb / Reg / Memory aus `map.rpt`) gegen
`scripts\baseline.csv`. Die Fitter-LE-Zahl wird nur mitgeführt. Der Slack wird mit einer
Toleranz von 1,5 ns geprüft. Ändern sich die Zahlen absichtlich, wird die Baseline
nachgezogen und die Änderung in der Note-Spalte begründet.

Die Varianten einer Familie zeigen nicht exakt dieselben Comb-Zahlen. Die Boot-Anzeige
enthält `BOARD_ID` als Konstante, und die optimiert je Wert ein paar LUTs anders. Verglichen
wird deshalb jede Variante mit ihrer eigenen Baseline.

Ein sauberer Build heißt nicht, dass die Variante in Hardware funktioniert. Was tatsächlich
getestet ist, steht in `VARIANTEN.md`.
