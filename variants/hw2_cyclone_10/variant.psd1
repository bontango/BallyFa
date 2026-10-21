@{
    Name        = 'hw2_cyclone_10'
    Title       = 'BallyFA HW 2.x mit dem Cyclone 10 Board (10CL006YE144C8G)'
    BoardId     = 4
    HwGen       = 2
    TopEntity   = 'BallyFA_HW2'   # Platinenhuelle top/BallyFA_HW2.vhd
    RtlFamily   = 'cyclone_10'      # welcher rtl\<familie>\-Ordner
    Options     = @('hw2')           # scripts\files_hw2.tcl
    BinFolder   = 'HW_v2.x'
    ReleasePrefix   = 'BallyFA_2_'   # BallyFA_2_<BoardId><Sub1><Sub2>.jic
    ReleaseArtifact = 'jic'
    Dormant     = $false

    # Keine VIRTUAL_PIN: jede Huelle deklariert nur die Ports, die ihre Platine hat.
    VirtualPins = @()

    Notes       = 'Vorher Ordner ''FPGA_source_alt\BallyFA_HW2.x_Cyclone_10''.'
}
