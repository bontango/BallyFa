@{
    Name        = 'hw1_cyclone_ii'
    Title       = 'BallyFA HW 1.x mit dem Cyclone II Board (EP2C5T144C8)'
    BoardId     = 1
    HwGen       = 1
    TopEntity   = 'BallyFA_HW1_cii'   # Platinenhuelle top/BallyFA_HW1_cii.vhd (ohne FLASH-Pins)
    RtlFamily   = 'cyclone_ii'      # welcher rtl\<familie>\-Ordner
    Options     = @('hw1_cii')       # scripts\files_hw1_cii.tcl
    BinFolder   = 'Cyclone_II'   # wie WillFA7: bin\ nach FPGA-Board, Basisplatine steht im Dateinamen
    ReleasePrefix   = 'BallyFA_'   # BallyFA_<BoardId><Sub1><Sub2>.pof
    ReleaseArtifact = 'pof'
    Dormant     = $false

    # Keine VIRTUAL_PIN: jede Huelle deklariert nur die Ports, die ihre Platine hat.
    VirtualPins = @()

    Notes       = 'Vorher Ordner ''BallyFA''.'
}
