-- from http://www.lothar-miller.de/s9y/categories/45-SPI-Master
-- Hier ist eine einfache SPI-Master-Implementierung in VHDL z.B. für FPGAs. 
-- Die Übertragung findet im Mode 0 statt (CPOL=0, CPHA=0). 
-- Die Protokolllänge und die Baudrate sind generisch einstellbar. 
-- An den Port TX_Data werden die 8 zu übertragenden Bits angelegt. 
-- Danach wird mit TX_Start die Übertragung gestartet. 
-- Erst wird SS aktiviert und dann die 8 Datenbits über das Schieberegister tx_reg an MOSI 
-- ausgegeben und gleichzietig der Datenstrom von MISO in das Schieberegister rx_reg eingelesen.
-- Nach der Übertragung wird SS deaktivert, und danach TX_Done solange aktiviert, 
-- bis TX_Start inaktiv wird.
-- Die empfangenen Daten sind jetzt am Port RX_Data abholbereit.
--
-- bontango 08.2020
-- added flag: do_not_disable_SS
-- bontango 03.2021
-- added flag: do_not_enable_SS

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity SPI_Master is  -- SPI-Modus 0: CPOL=0, CPHA=0
    Generic ( Quarz_Taktfrequenz : integer   := 50000000;  -- Hertz 
              SPI_Taktfrequenz   : integer   :=  1000000;  -- Hertz / zur Berechnung des Reload-Werts für Taktteiler
              Laenge             : integer   :=   8        -- Maximale Anzahl der zu übertragenden Bits
             ); 
    Port ( TX_Data  : in  STD_LOGIC_VECTOR (Laenge-1 downto 0); -- Sendedaten
           RX_Data  : out STD_LOGIC_VECTOR (Laenge-1 downto 0); -- Empfangsdaten
           MOSI     : out STD_LOGIC;                           
           MISO     : in  STD_LOGIC;
           SCLK     : out STD_LOGIC;
           SS       : out STD_LOGIC;
           TX_Start : in  STD_LOGIC;
           TX_Done  : out STD_LOGIC;
           clk      : in  STD_LOGIC;
			  do_not_disable_SS : in STD_LOGIC;
			  do_not_enable_SS : in STD_LOGIC
         );
end SPI_Master;

architecture Behavioral of SPI_Master is
  signal   delay       : integer range 0 to (Quarz_Taktfrequenz/(2*SPI_Taktfrequenz));
  constant clock_delay : integer := (Quarz_Taktfrequenz/(2*SPI_Taktfrequenz))-1;
  
  type   spitx_states is (spi_stx,spi_txactive,spi_etx);
  signal spitxstate    : spitx_states := spi_stx;

  signal spiclk    : std_logic;
  signal spiclklast: std_logic;

  signal bitcounter    : integer range 0 to Laenge; -- wenn bitcounter = Laenge --> alle Bits uebertragen
  signal tx_reg        : std_logic_vector(Laenge-1 downto 0) := (others=>'0');
  signal rx_reg        : std_logic_vector(Laenge-1 downto 0) := (others=>'0');

begin
  ------ Verwaltung --------
  process begin 
     wait until rising_edge(CLK);
     if(delay>0) then delay <= delay-1;
     else             delay <= clock_delay;  
     end if;
     spiclklast <= spiclk;
     case spitxstate is
       when spi_stx =>
             if do_not_disable_SS = '0' then
						SS          <= '1'; -- slave select disabled
				 end if;		
             TX_Done     <= '0';
             bitcounter  <= Laenge;
             spiclk      <= '0'; -- SPI-Modus 0
             if(TX_Start = '1') then 
                spitxstate <= spi_txactive; 
					 if do_not_enable_SS = '0' then	
						SS         <= '0';
					 end if;                
                delay      <= clock_delay; 
             end if;

       when spi_txactive =>  -- Daten aus tx_reg uebertragen
             if (delay=0) then -- shift
                spiclk <= not spiclk;
                if (bitcounter=0) then -- alle Bits uebertragen -> deselektieren
                   spiclk     <= '0';  -- SPI-Modus 0
                   spitxstate <= spi_etx;
                end if;
                if(spiclk='1') then    -- SPI-Modus 0
                   bitcounter <= bitcounter-1;  
                end if;  
             end if;

       when spi_etx =>
             if do_not_disable_SS = '0' then	
					SS      <= '1'; -- disable Slave Select 
				end if;	
             TX_Done <= '1';
             if(TX_Start = '0') then -- Handshake: warten, bis Start-Flag geloescht
               spitxstate <= spi_stx;
             end if;
     end case;
  end process;   
  
  ---- Empfangsschieberegister -----
  process begin 
     wait until rising_edge(CLK);
     if (spiclk='1' and  spiclklast='0') then -- SPI-Modus 0
        rx_reg <= rx_reg(rx_reg'left-1 downto 0) & MISO;
     end if;
  end process;   
     
  ---- Sendeschieberegister -------
  process begin 
     wait until rising_edge(CLK);
     if (spitxstate=spi_stx) then   -- Zurücksetzen, wenn SS inaktiv
        tx_reg <= TX_Data;
     end if;
     if (spiclk='0' and  spiclklast='1') then -- SPI-Modus 0
        tx_reg <= tx_reg(tx_reg'left-1 downto 0) & tx_reg(0);
     end if;
  end process;   

  SCLK    <= spiclk;
  MOSI    <= tx_reg(tx_reg'left);
  RX_Data <= rx_reg;
  
end Behavioral;