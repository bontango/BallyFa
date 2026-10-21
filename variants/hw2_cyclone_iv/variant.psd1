@{
    Name        = 'hw2_cyclone_iv'
    Title       = 'BallyFA HW 2.x mit dem Cyclone IV Board (EP4CE6F17C8)'
    BoardId     = 2
    HwGen       = 2
    TopEntity   = 'BallyFA_HW2'   # Platinenhuelle top/BallyFA_HW2.vhd
    RtlFamily   = 'cyclone_iv'      # welcher rtl\<familie>\-Ordner
    Options     = @('hw2')           # scripts\files_hw2.tcl
    BinFolder   = 'hardware_v2.x\Cyclone_IV\FPGA_board_v3.x'   # wie lisy.dev/swrep/BallyFA/software/
    ReleasePrefix   = 'BallyFA_2_'   # BallyFA_2_<BoardId><Sub1><Sub2>.jic
    ReleaseArtifact = 'jic'
    Dormant     = $false

    # Keine VIRTUAL_PIN: jede Huelle deklariert nur die Ports, die ihre Platine hat.
    VirtualPins = @()

    Notes       = 'Vorher Ordner ''BallyFA_2x - Cyclone_IV''.'
}
