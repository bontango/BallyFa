@{
    Name        = 'hw1_cyclone_iv'
    Title       = 'BallyFA HW 1.x mit dem Cyclone IV Board (EP4CE6F17C8)'
    BoardId     = 2
    HwGen       = 1
    TopEntity   = 'BallyFA_HW1'   # Platinenhuelle top/BallyFA_HW1.vhd
    RtlFamily   = 'cyclone_iv'      # welcher rtl\<familie>\-Ordner
    Options     = @('hw1')           # scripts\files_hw1.tcl
    BinFolder   = 'Cyclone_IV\FPGA_board_v3.x'   # wie WillFA7: bin\ nach FPGA-Board, Basisplatine steht im Dateinamen
    ReleasePrefix   = 'BallyFA_'   # BallyFA_<BoardId><Sub1><Sub2>.jic
    ReleaseArtifact = 'jic'
    Dormant     = $false

    # Keine VIRTUAL_PIN: jede Huelle deklariert nur die Ports, die ihre Platine hat.
    VirtualPins = @()

    Notes       = 'Vorher Ordner ''BallyFA - Cyclone_IV''.'
}
