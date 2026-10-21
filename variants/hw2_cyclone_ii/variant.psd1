@{
    Name        = 'hw2_cyclone_ii'
    Title       = 'BallyFA HW 2.x mit dem Cyclone II Board (EP2C5T144C8)'
    BoardId     = 1
    HwGen       = 2
    TopEntity   = 'BallyFA_HW2'   # Platinenhuelle top/BallyFA_HW2.vhd
    RtlFamily   = 'cyclone_ii'      # welcher rtl\<familie>\-Ordner
    Options     = @('hw2')           # scripts\files_hw2.tcl
    BinFolder   = 'HW_v2.x'
    ReleasePrefix   = 'BallyFA_2_'   # BallyFA_2_<BoardId><Sub1><Sub2>.pof
    ReleaseArtifact = 'pof'
    Dormant     = $false

    # Keine VIRTUAL_PIN: jede Huelle deklariert nur die Ports, die ihre Platine hat.
    VirtualPins = @()

    Notes       = 'Vorher Ordner ''BallyFA_2x''.'
}
