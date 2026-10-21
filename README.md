# BallyFA

VHDL-Nachbau der **Bally -17/-35 MPU** (6800-CPU, zwei 6821-PIAs, 5101-CMOS-RAM) auf einem
Altera/Intel FPGA – mit SD-Karte für die Spiel-ROMs, EEPROM/FRAM für die Einstellungen,
Münzprüfer und bei HW 2.x einem USB-Anschluss (lisy_api / MPF beta).
Hardware und Hintergrund: <https://lisy.dev/>

## Varianten

Acht Varianten = vier FPGA-Boards × zwei Basisplatinen.

| Variante | Basisplatine | FPGA-Board | Device | Quartus | Anzeige | Release |
|---|---|---|---|---|---|---|
| `hw1_cyclone_ii` | HW 1.x | Cyclone II | `EP2C5T144C8` | 13.0sp1 | `1.23` | `bin/HW_v1.x/BallyFA_123.pof` |
| `hw1_cyclone_iv` | HW 1.x | Cyclone IV | `EP4CE6F17C8` | 22.1 | `2.23` | `bin/HW_v1.x/BallyFA_223.jic` |
| `hw1_cyclone_iv_v4` | HW 1.x | Cyclone IV v4.x | `EP4CE6E22C8` | 22.1 | `3.23` | `bin/HW_v1.x/BallyFA_323.jic` |
| `hw1_cyclone_10` | HW 1.x | Cyclone 10 | `10CL006YE144C8G` | 22.1 | `4.23` | `bin/HW_v1.x/Bally_423.jic` |
| `hw2_cyclone_ii` | HW 2.x | Cyclone II | `EP2C5T144C8` | 13.0sp1 | `2 1.23` | `bin/HW_v2.x/BallyFA_2_123.pof` |
| `hw2_cyclone_iv` | HW 2.x | Cyclone IV | `EP4CE6F17C8` | 22.1 | `2 2.23` | `bin/HW_v2.x/BallyFA_2_223.jic` |
| `hw2_cyclone_iv_v4` | HW 2.x | Cyclone IV v4.x | `EP4CE6E22C8` | 22.1 | `2 3.23` | `bin/HW_v2.x/BallyFA_2_323.jic` |
| `hw2_cyclone_10` | HW 2.x | Cyclone 10 | `10CL006YE144C8G` | 22.1 | `2 4.23` | `bin/HW_v2.x/BallyFA_2_423.jic` |

Die Releases in `bin/` stammen noch aus den alten Projektordnern. Das nächste Release aus
diesem Baum heißt einheitlich `BallyFA_[2_]<Board><Sub1><Sub2>`.

Alle Varianten teilen **einen** Kern (`top/Bally_core.vhd`) und einen Quellbaum. Was die
Basisplatine ausmacht, steht in einer dünnen Platinenhülle:

- `top/BallyFA_HW1.vhd`: LED_1/LED_2, Eingänge direkt
- `top/BallyFA_HW2.vhd`: 4049-Inverter vor sechs Eingängen, LEDs auf anderen Pins,
  USB über `lisy_api`

Was das FPGA-Board ausmacht, sind das Device, die Pinlagen und die Ziffer `BOARD_ID`.

Die angezeigte Version (Display 1 beim Booten) ist `[2] BOARD_ID . SW_SUB1 SW_SUB2`. Die
führende 2 erscheint nur bei HW 2.x. `SW_SUB1`/`SW_SUB2` stehen an genau einer Stelle,
nämlich in `rtl/common/version_pkg.vhd`. Ein Release ändert dort eine Ziffer, und alle acht
Boards folgen.

## Layout

```
top/Bally_core.vhd     der gemeinsame Kern (früher Bally.vhd)
top/BallyFA_HW1.vhd    Platinenhülle HW 1.x  (TOP_LEVEL_ENTITY der hw1_*-Varianten)
top/BallyFA_HW2.vhd    Platinenhülle HW 2.x  (TOP_LEVEL_ENTITY der hw2_*-Varianten)
rtl/common/            20 gemeinsame Module + version_pkg.vhd + Bally.sdc
rtl/cyclone_ii/        Megafunctions U2andU6 M6810 SM5101 R5101 (Cyclone II, Quartus 13.0)
rtl/cyclone_iv/        dieselben vier für Cyclone IV E
rtl/cyclone_10/        dieselben vier für Cyclone 10 LP
rom/elektra.hex        Vorbelegung von U2andU6 (zur Laufzeit von der SD-Karte überschrieben)
variants/<name>/       variant.psd1, device.tcl, pins.tcl, variant_pkg.vhd,
                       Bally.qpf, [Bally.cof]  +  Bally.qsf (GENERIERT)
scripts/               gen_qsf.ps1, check.ps1, build.ps1, release.ps1, baseline.csv
bin/                   ausgelieferte .pof/.jic je Basisplatine + Changelog.txt
docs/                  WORKFLOW.md
```

**`variants/<name>/Bally.qsf` niemals von Hand ändern.** Sie wird aus den Fragmenten in
`scripts/` und `variants/<name>/` erzeugt. Quartus schreibt selbst hinein, sobald das Projekt
in der IDE offen ist. Deshalb wird sie vor jedem Build neu erzeugt.

## Build

```powershell
powershell -File scripts\gen_qsf.ps1 -Check          # .qsf aktuell?
powershell -File scripts\check.ps1                   # alle 8 Varianten synthetisieren
powershell -File scripts\check.ps1 -Fit              # + Fitter und Timing
powershell -File scripts\build.ps1 hw2_cyclone_10    # voller Flow inkl. .jic
powershell -File scripts\release.ps1 -Note "..."     # bauen, nach bin\ legen, Changelog
```

Toolchain:

- Quartus Prime **22.1std.2 Lite** (`C:\intelFPGA_lite\22.1std`) für Cyclone IV und Cyclone 10
- Quartus **13.0sp1 Web Edition** (`C:\altera\13.0sp1`) für Cyclone II

Die Skripte wählen die Version anhand der FAMILY. Wie man hier arbeitet und was wohin
gehört, steht in [docs/WORKFLOW.md](docs/WORKFLOW.md).

## Repository-Hinweis

Dieser Baum ist am 21.10.2026 aus acht flachen Projektordnern entstanden: `BallyFA`,
`BallyFA - Cyclone_IV`, `BallyFA - Cyclone_IV_v4.x`, `BallyFA - Cyclone_10`, `BallyFA_2x`,
`BallyFA_2x - Cyclone_IV`, `BallyFA_2x - Cyclone_IV_v4.x` und
`FPGA_source_alt\BallyFA_HW2.x_Cyclone_10`. Keiner davon hatte ein Git, die Historie beginnt
also hier.

Die alten Ordner liegen weiterhin daneben, außerdem als ZIP unter
`..\Archive\BallyFA_Varianten_vor_Sourcebaum_2026-10-21.zip`. **Von dort nicht mehr bauen
und nicht committen.**

`origin` ist <https://github.com/bontango/BallyFa>. Gearbeitet wird auf `main`. `master` wird
per Fast-Forward auf denselben Stand gehalten, weil es auf GitHub der Default-Branch ist. Die
drei älteren GitHub-Commits (flacher Stand bis Dezember 2021) sind über einen Merge mit der
Strategie „ours“ als Vorfahren eingebunden. Ihre Dateien stehen nur noch in der Historie.

## Dritte

Die 6800-CPU (`cpu68.vhd`) und die Ausgangsbasis stammen aus Grant Searles „Multicomp“ bzw.
Doug Gillilands Port. `SPI_Master.vhd`, `uart_rx.vhd` und `uart_tx.vhd` stammen von
nandland.com. Die Megafunctions unter `rtl/<familie>/` sind vom Intel MegaWizard erzeugt.
