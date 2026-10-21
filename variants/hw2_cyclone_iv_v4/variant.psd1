@{
    Name        = 'hw2_cyclone_iv_v4'
    Title       = 'BallyFA HW 2.x mit dem Cyclone IV v4.x Board (EP4CE6E22C8N)'
    BoardId     = 3
    HwGen       = 2
    TopEntity   = 'BallyFA_HW2'   # Platinenhuelle top/BallyFA_HW2.vhd
    RtlFamily   = 'cyclone_iv'      # welcher rtl\<familie>\-Ordner
    Options     = @('hw2')           # scripts\files_hw2.tcl
    BinFolder   = 'Cyclone_IV\FPGA_board_v4.x'   # wie WillFA7: bin\ nach FPGA-Board, Basisplatine steht im Dateinamen
    ReleasePrefix   = 'BallyFA_2_'   # BallyFA_2_<BoardId><Sub1><Sub2>.jic
    ReleaseArtifact = 'jic'
    Dormant     = $false

    # Keine VIRTUAL_PIN: jede Huelle deklariert nur die Ports, die ihre Platine hat.
    VirtualPins = @()

    Notes       = 'Vorher Ordner ''BallyFA_2x - Cyclone_IV_v4.x''.'
}
