# BallyFA

VHDL-Nachbau der **Bally -17/-35 MPU** (6800-CPU, zwei 6821-PIAs, 5101-CMOS-RAM) auf einem
Altera/Intel FPGA – mit SD-Karte für die Spiel-ROMs, EEPROM/FRAM für die Einstellungen,
Münzprüfer und bei HW 2.x einem USB-Anschluss (lisy_api / MPF beta).
Hardware und Hintergrund: <https://lisy.dev/>

## Varianten

Acht Varianten = vier FPGA-Boards × zwei Basisplatinen.

| Variante | Basisplatine | FPGA-Board | Device | Quartus | Anzeige | ROMs aus dem Flash | Release |
|---|---|---|---|---|---|---|---|
| `hw1_cyclone_ii` | HW 1.x | Cyclone II | `EP2C5T144C8` | 13.0sp1 | `1.30` | – | `bin/hardware_v1.x/Cyclone_II/BallyFA_130.pof` |
| `hw1_cyclone_iv` | HW 1.x | Cyclone IV | `EP4CE6F17C8` | 22.1 | `2.30` | ja | `bin/hardware_v1.x/Cyclone_IV/FPGA_board_v3.x/BallyFA_230.jic` |
| `hw1_cyclone_iv_v4` | HW 1.x | Cyclone IV v4.x | `EP4CE6E22C8` | 22.1 | `3.30` | ja | `bin/hardware_v1.x/Cyclone_IV/FPGA_board_v4.x/BallyFA_330.jic` |
| `hw1_cyclone_10` | HW 1.x | Cyclone 10 | `10CL006YE144C8G` | 22.1 | `4.30` | ja | `bin/hardware_v1.x/Cyclone_10/BallyFA_430.jic` |
| `hw2_cyclone_ii` | HW 2.x | Cyclone II | `EP2C5T144C8` | 13.0sp1 | `2 1.30` | – | `bin/hardware_v2.x/Cyclone_II/BallyFA_2_130.pof` |
| `hw2_cyclone_iv` | HW 2.x | Cyclone IV | `EP4CE6F17C8` | 22.1 | `2 2.30` | ja | `bin/hardware_v2.x/Cyclone_IV/FPGA_board_v3.x/BallyFA_2_230.jic` |
| `hw2_cyclone_iv_v4` | HW 2.x | Cyclone IV v4.x | `EP4CE6E22C8` | 22.1 | `2 3.30` | ja | `bin/hardware_v2.x/Cyclone_IV/FPGA_board_v4.x/BallyFA_2_330.jic` |
| `hw2_cyclone_10` | HW 2.x | Cyclone 10 | `10CL006YE144C8G` | 22.1 | `2 4.30` | ja | `bin/hardware_v2.x/Cyclone_10/BallyFA_2_430.jic` |

Die x.23-Releases in `bin/` stammen noch aus den alten Projektordnern, x.30 ist das erste aus
diesem Baum.

### Spiel-ROMs aus dem Konfigurationsflash (seit x.30, Cyclone IV/10)

Antwortet beim Start keine SD-Karte, lädt BallyFA das gewählte Spiel aus dem
Konfigurationsflash (EPCS16) statt von der Karte. Die Spielwahl erfolgt wie bisher über S1.
Im Flash liegen die Spiele der Karte byte-gleich ab Adresse 080000h, je 8 KByte. Platz ist für 192 Spiele; das Kartenimage 111 hat 142.

- Beim Flash-Boot zeigt Display 4 während der Bootmeldung die Slotnummer.
- Ist der Slot leer oder liegt er über 191, steht vorne eine 8, die SD-LED blinkt 8-mal und
  die CPU startet nicht.
- Cyclone II hat keinen Flash-Fallback.

**Die Releases in `bin/` enthalten keine Spiel-ROMs.** Die ROMs sind urheberrechtlich
geschützt. Eine `.jic` mit ROMs baut man lokal aus einem SD-Kartenimage:

```powershell
powershell -File scripts\build.ps1 hw2_cyclone_10 -RomImage <Pfad>\BallyFA_SD_111.img
#  -> variants\hw2_cyclone_10\output_files\bally_roms.jic
```

`*_roms.jic`/`*_roms.hex` sind gitignored.

Alle Varianten teilen **einen** Kern (`top/Bally_core.vhd`) und einen Quellbaum. Der Kern
enthält auch die Unterschiede der Basisplatinen (Generic `HW_GEN`: 4049-Inverter vor sechs
Eingängen und USB über `lisy_api` bei HW 2.x). Die vier Platinenhüllen deklarieren nur die
Ports der jeweiligen Platine:

- `top/BallyFA_HW1.vhd` und `top/BallyFA_HW2.vhd`: Cyclone IV/10, mit den vier Flash-Pins
- `top/BallyFA_HW1_cii.vhd` und `top/BallyFA_HW2_cii.vhd`: Cyclone II, ohne Flash-Pins
Was das FPGA-Board ausmacht, sind das Device, die Pinlagen und die Ziffer `BOARD_ID`.

Die angezeigte Version (Display 1 beim Booten) ist `[2] BOARD_ID . SW_SUB1 SW_SUB2`. Die
führende 2 erscheint nur bei HW 2.x. `SW_SUB1`/`SW_SUB2` stehen an genau einer Stelle,
nämlich in `rtl/common/version_pkg.vhd`. Ein Release ändert dort eine Ziffer, und alle acht
Boards folgen.

## Layout

```
top/Bally_core.vhd     der gemeinsame Kern (früher Bally.vhd)
top/BallyFA_HW*.vhd   Platinenhüllen (TOP_LEVEL_ENTITY), _cii = Cyclone II ohne Flash-Pins
rtl/common/            21 gemeinsame Module (inkl. Flash_ROM) + version_pkg.vhd + Bally.sdc
rtl/cyclone_ii/        Megafunctions U2andU6 M6810 SM5101 R5101 (Cyclone II, Quartus 13.0)
rtl/cyclone_iv/        dieselben vier für Cyclone IV E
rtl/cyclone_10/        dieselben vier für Cyclone 10 LP
rom/elektra.hex        Vorbelegung von U2andU6 (zur Laufzeit von der SD-Karte überschrieben)
variants/<name>/       variant.psd1, device.tcl, pins.tcl, variant_pkg.vhd,
                       Bally.qpf, [Bally.cof, bally_roms.cof]  +  Bally.qsf (GENERIERT)
scripts/               gen_qsf.ps1, check.ps1, build.ps1, release.ps1, make_flash_hex.ps1, baseline.csv
bin/                   ausgelieferte .pof/.jic wie auf lisy.dev/swrep/BallyFA/software/:
                       hardware_v1.x/ und hardware_v2.x/, darunter je Cyclone_II/,
                       Cyclone_IV/FPGA_board_v3.x/ (F17), Cyclone_IV/FPGA_board_v4.x/ (E22),
                       Cyclone_10/; dazu Changelog.txt
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
                                                     # (-RomImage <img>: zusaetzlich lokale *_roms.jic)
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

`origin` ist <https://github.com/bontango/BallyFa>. Es gibt nur den Branch `main`, er ist auch
der Default-Branch auf GitHub. Der frühere Branch `master` wurde am 21.10.2026 gelöscht; sein
Stand ist vollständig in `main` enthalten. Die drei älteren GitHub-Commits (flacher Stand bis Dezember 2021) sind über einen Merge mit der
Strategie „ours“ als Vorfahren eingebunden. Ihre Dateien stehen nur noch in der Historie.

## Dritte

Die 6800-CPU (`cpu68.vhd`) und die Ausgangsbasis stammen aus Grant Searles „Multicomp“ bzw.
Doug Gillilands Port. `SPI_Master.vhd`, `uart_rx.vhd` und `uart_tx.vhd` stammen von
nandland.com. Die Megafunctions unter `rtl/<familie>/` sind vom Intel MegaWizard erzeugt.
