@{
    Name        = 'hw1_cyclone_10'
    Title       = 'BallyFA HW 1.x mit dem Cyclone 10 Board (10CL006YE144C8G)'
    BoardId     = 4
    HwGen       = 1
    TopEntity   = 'BallyFA_HW1'   # Platinenhuelle top/BallyFA_HW1.vhd
    RtlFamily   = 'cyclone_10'      # welcher rtl\<familie>\-Ordner
    Options     = @('hw1')           # scripts\files_hw1.tcl
    BinFolder   = 'HW_v1.x'
    ReleasePrefix   = 'BallyFA_'   # BallyFA_<BoardId><Sub1><Sub2>.jic
    ReleaseArtifact = 'jic'
    Dormant     = $false

    # Keine VIRTUAL_PIN: jede Huelle deklariert nur die Ports, die ihre Platine hat.
    VirtualPins = @()

    Notes       = 'Vorher Ordner ''BallyFA - Cyclone_10''.'
}
