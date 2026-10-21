@{
    Name        = 'hw1_cyclone_ii'
    Title       = 'BallyFA HW 1.x mit dem Cyclone II Board (EP2C5T144C8)'
    BoardId     = 1
    HwGen       = 1
    TopEntity   = 'BallyFA_HW1'   # Platinenhuelle top/BallyFA_HW1.vhd
    RtlFamily   = 'cyclone_ii'      # welcher rtl\<familie>\-Ordner
    Options     = @('hw1')           # scripts\files_hw1.tcl
    BinFolder   = 'HW_v1.x'
    ReleasePrefix   = 'BallyFA_'   # BallyFA_<BoardId><Sub1><Sub2>.pof
    ReleaseArtifact = 'pof'
    Dormant     = $false

    # Keine VIRTUAL_PIN: jede Huelle deklariert nur die Ports, die ihre Platine hat.
    VirtualPins = @()

    Notes       = 'Vorher Ordner ''BallyFA''.'
}
