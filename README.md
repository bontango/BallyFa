# BallyFA

VHDL re-creation of the **Bally -17/-35 MPU** (6800 CPU, two 6821 PIAs, 5101 CMOS RAM) on an
Altera/Intel FPGA – with an SD card for the game ROMs, EEPROM/FRAM for the settings, a coin
validator and, on HW 2.x, a USB port (lisy_api / MPF beta).
Hardware and background: <https://lisy.dev/>

## User manuals

**Read online:** <https://bontango.github.io/BallyFa/>

- [BallyFA user manual (English)](https://bontango.github.io/BallyFa/BallyFA_user_manual.html)
- [BallyFA Bedienungsanleitung (Deutsch)](https://bontango.github.io/BallyFa/BallyFA_Bedienungsanleitung.html)
- [BallyFA manuel d'utilisation (Français)](https://bontango.github.io/BallyFa/BallyFA_manuel_utilisateur.html)

## Variants

Eight variants = four FPGA boards × two base boards.

| Variant | Base board | FPGA board | Device | Quartus | Display | ROMs from flash | Release |
|---|---|---|---|---|---|---|---|
| `hw1_cyclone_ii` | HW 1.x | Cyclone II | `EP2C5T144C8` | 13.0sp1 | `1.30` | – | `bin/hardware_v1.x/Cyclone_II/BallyFA_130.pof` |
| `hw1_cyclone_iv` | HW 1.x | Cyclone IV | `EP4CE6F17C8` | 22.1 | `2.30` | yes | `bin/hardware_v1.x/Cyclone_IV/FPGA_board_v3.x/BallyFA_230.jic` |
| `hw1_cyclone_iv_v4` | HW 1.x | Cyclone IV v4.x | `EP4CE6E22C8` | 22.1 | `3.30` | yes | `bin/hardware_v1.x/Cyclone_IV/FPGA_board_v4.x/BallyFA_330.jic` |
| `hw1_cyclone_10` | HW 1.x | Cyclone 10 | `10CL006YE144C8G` | 22.1 | `4.30` | yes | `bin/hardware_v1.x/Cyclone_10/BallyFA_430.jic` |
| `hw2_cyclone_ii` | HW 2.x | Cyclone II | `EP2C5T144C8` | 13.0sp1 | `2 1.30` | – | `bin/hardware_v2.x/Cyclone_II/BallyFA_2_130.pof` |
| `hw2_cyclone_iv` | HW 2.x | Cyclone IV | `EP4CE6F17C8` | 22.1 | `2 2.30` | yes | `bin/hardware_v2.x/Cyclone_IV/FPGA_board_v3.x/BallyFA_2_230.jic` |
| `hw2_cyclone_iv_v4` | HW 2.x | Cyclone IV v4.x | `EP4CE6E22C8` | 22.1 | `2 3.30` | yes | `bin/hardware_v2.x/Cyclone_IV/FPGA_board_v4.x/BallyFA_2_330.jic` |
| `hw2_cyclone_10` | HW 2.x | Cyclone 10 | `10CL006YE144C8G` | 22.1 | `2 4.30` | yes | `bin/hardware_v2.x/Cyclone_10/BallyFA_2_430.jic` |

The x.23 releases in `bin/` still come from the old project folders; x.30 is the first one
built from this tree.

### Game ROMs from the configuration flash (since x.30, Cyclone IV/10)

If no SD card answers at power-up, BallyFA loads the selected game from the configuration
flash (EPCS16) instead of the card. The game is selected with S1, as before.
The flash holds the games of the card byte for byte from address 080000h, 8 KByte each.
There is room for 192 games; card image 111 has 142.

- When booting from flash, display 4 shows the slot number during the boot message.
- If the slot is empty or above 191, an 8 appears in front, the SD LED blinks 8 times and
  the CPU does not start.
- Cyclone II has no flash fallback.

**The releases in `bin/` contain no game ROMs.** The ROMs are protected by copyright. A
`.jic` with ROMs is built locally from an SD card image:

```powershell
powershell -File scripts\build.ps1 hw2_cyclone_10 -RomImage <path>\BallyFA_SD_111.img
#  -> variants\hw2_cyclone_10\output_files\bally_roms.jic
```

`*_roms.jic`/`*_roms.hex` are gitignored.

All variants share **one** core (`top/Bally_core.vhd`) and one source tree. The core also
contains the differences between the base boards (generic `HW_GEN`: 4049 inverters in front
of six inputs, and USB via `lisy_api` on HW 2.x). The four board shells only declare the
ports of their board:

- `top/BallyFA_HW1.vhd` and `top/BallyFA_HW2.vhd`: Cyclone IV/10, with the four flash pins
- `top/BallyFA_HW1_cii.vhd` and `top/BallyFA_HW2_cii.vhd`: Cyclone II, without flash pins

What makes up an FPGA board is the device, the pin locations and the digit `BOARD_ID`.

The version shown (display 1 at boot) is `[2] BOARD_ID . SW_SUB1 SW_SUB2`. The leading 2
appears on HW 2.x only. `SW_SUB1`/`SW_SUB2` live in exactly one place,
`rtl/common/version_pkg.vhd`. A release changes one digit there, and all eight boards
follow.

## Layout

```
top/Bally_core.vhd     the shared core (formerly Bally.vhd)
top/BallyFA_HW*.vhd    board shells (TOP_LEVEL_ENTITY), _cii = Cyclone II without flash pins
rtl/common/            21 shared modules (incl. Flash_ROM) + version_pkg.vhd + Bally.sdc
rtl/cyclone_ii/        megafunctions U2andU6 M6810 SM5101 R5101 (Cyclone II, Quartus 13.0)
rtl/cyclone_iv/        the same four for Cyclone IV E
rtl/cyclone_10/        the same four for Cyclone 10 LP
variants/<name>/       variant.psd1, device.tcl, pins.tcl, variant_pkg.vhd,
                       Bally.qpf, [Bally.cof, bally_roms.cof]  +  Bally.qsf (GENERATED)
scripts/               gen_qsf.ps1, check.ps1, build.ps1, release.ps1, make_flash_hex.ps1, baseline.csv
bin/                   released .pof/.jic as on lisy.dev/swrep/BallyFA/software/:
                       hardware_v1.x/ and hardware_v2.x/, below each Cyclone_II/,
                       Cyclone_IV/FPGA_board_v3.x/ (F17), Cyclone_IV/FPGA_board_v4.x/ (E22),
                       Cyclone_10/; plus Changelog.txt
docs/                  user manuals (HTML: en/de/fr) + index.html for GitHub Pages, WORKFLOW.md
```

**Never edit `variants/<name>/Bally.qsf` by hand.** It is generated from the fragments in
`scripts/` and `variants/<name>/`. Quartus writes into it on its own as soon as the project
is open in the IDE. That is why it is regenerated before every build.

## Build

```powershell
powershell -File scripts\gen_qsf.ps1 -Check          # .qsf up to date?
powershell -File scripts\check.ps1                   # synthesize all 8 variants
powershell -File scripts\check.ps1 -Fit              # + fitter and timing
powershell -File scripts\build.ps1 hw2_cyclone_10    # full flow incl. .jic
powershell -File scripts\release.ps1 -Note "..."     # build, copy to bin\, changelog
                                                     # (-RomImage <img>: additional local *_roms.jic)
```

Toolchain:

- Quartus Prime **22.1std.2 Lite** (`C:\intelFPGA_lite\22.1std`) for Cyclone IV and Cyclone 10
- Quartus **13.0sp1 Web Edition** (`C:\altera\13.0sp1`) for Cyclone II

The scripts pick the version from the FAMILY. How to work here and what goes where is
described in [docs/WORKFLOW.md](docs/WORKFLOW.md).

## Repository note

This tree was created on 21.10.2026 from eight flat project folders: `BallyFA`,
`BallyFA - Cyclone_IV`, `BallyFA - Cyclone_IV_v4.x`, `BallyFA - Cyclone_10`, `BallyFA_2x`,
`BallyFA_2x - Cyclone_IV`, `BallyFA_2x - Cyclone_IV_v4.x` and
`FPGA_source_alt\BallyFA_HW2.x_Cyclone_10`. None of them had a Git repository, so the
history starts here.

The old folders are still next to it, and also as a ZIP in
`..\Archive\BallyFA_Varianten_vor_Sourcebaum_2026-10-21.zip`. **Do not build or commit from
there any more.**

`origin` is <https://github.com/bontango/BallyFa>. There is only the branch `main`, which is
also the default branch on GitHub. The former branch `master` was deleted on 21.10.2026; its
state is fully contained in `main`. The three older GitHub commits (flat state up to
December 2021) are included as ancestors through a merge with the strategy "ours". Their
files exist only in the history.

## Third party

The 6800 CPU (`cpu68.vhd`) and the starting point come from Grant Searle's "Multicomp" and
Doug Gilliland's port. `SPI_Master.vhd`, `uart_rx.vhd` and `uart_tx.vhd` come from
nandland.com. The megafunctions under `rtl/<family>/` are generated by the Intel MegaWizard.
