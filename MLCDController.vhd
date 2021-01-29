-- github.com/mehmetatay0
-- Written for I2C Com

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

entity MLCDController is
generic (
    GSysClk     :   integer := 100  -- Ex: 50ms * 100MHz -> 50.000 * 100Hz
);
port (
    PISysClk    :   in std_logic;
    POBusy      :   out std_logic;
    PIOSDA        : inout std_logic;
    PIOSCL        : inout std_logic;
    PIEnable      : in std_logic;
    PIReset       : in std_logic;
    PIWriteData   : in std_logic_vector(7 downto 0)
);
end MLCDController;

architecture Behavioral of MLCDController is

component I2CMaster is
generic (
    input_clk : integer := 100_000_000;
    bus_clk   : integer := 100_000);
port (
    clk       : in std_logic;
    reset_n   : in std_logic;
    ena       : in std_logic;
    addr      : in std_logic_vector(6 downto 0);
    rw        : in std_logic;
    data_wr   : in std_logic_vector(7 downto 0);
    busy      : out std_logic;
    ack_error : buffer std_logic;
    data_rd   : out std_logic_vector(7 downto 0);
    sda       : inout std_logic;
    scl       : inout std_logic);
end component;

-- for Master

  signal SAddr             : std_logic_vector(6 downto 0);
  signal SRW               : std_logic;
  signal SDataWr           : std_logic_vector(7 downto 0);
  signal SBusy             : std_logic;
  signal SDataRd           : std_logic_vector(7 downto 0);
  signal SEnable           : std_logic;
  signal SAckError         : std_logic;
  signal SBusyPrev         : std_logic;
  signal busy_cnt          : integer;


-- for init
type machine is (
    PowerUp,
    For_Wait,
    Initialize,
    setRamAddress,
    writeData,
    Send,
    I2CSend,
    Idle
    );
    
signal state : machine := PowerUp;
signal wait_State : machine := Initialize;
signal ready_state : integer := 0;
signal init_state : integer := 0;
signal after_state : integer := 0;
signal SClockCounter : integer := 0;
signal POLCDData     : std_logic_vector(7 downto 0);   -- Data included 4-Bit interface for I2C Com 
signal WaitValue : integer := 0;

begin

process (PISysClk)
begin
    if PISysClk'event and PISysClk = '1' then
        case state is
            when PowerUp =>
                POBusy <= '1';          -- wait time that more than 15ms, I selected it 50ms
                if (SClockCounter < (50000 * GSysClk - 1)) then       -- 50ms wait 
                    SClockCounter <= SClockCounter + 1;
                else

                    SClockCounter <= 0;
                    state <= Initialize;
                end if;
            
            when For_Wait => 
                POBusy <= '1';          
                if (SClockCounter < (WaitValue * GSysClk - 1)) then   
                    SClockCounter <= SClockCounter + 1;
                else

                    SClockCounter <= 0;
                    state <= wait_State;
                end if;


            when Initialize =>
                POBusy <= '1';
                wait_State <= Initialize;
            case init_state is
                when 0 =>            -- function set
                    POLCDData <= "00111100";
                    state <= I2CSend;
                    after_state <= 1; 
                    WaitValue <= 5000;
                when 1 =>  -- 5ms wait (more than 4.1ms wait)
                    POLCDData <= "00001000";
                    state <= I2CSend;
                    after_state <= 2;
                    WaitValue <= 10;
                when 2 => -- function set
                    POLCDData <= "00111100";
                    state <= I2CSend;
                    after_state <= 3;
                    WaitValue <= 100;
                when 3 =>  -- 100us wait 
                    POLCDData <= "00001000";
                    state <= I2CSend;
                    after_state <= 4;
                    WaitValue <= 10;
                when 4 => -- function set
                    POLCDData <= "00111100";
                    state <= I2CSend;
                    after_state <= 5;
                    WaitValue <= 50;
                when 5 =>  -- 50us wait 
                    POLCDData <= "00001000";
                    state <= I2CSend;
                    after_state <= 6;
                    WaitValue <= 10;
                when 6 => -- function set - str 1
                    POLCDData <= "00101100";    
                    state <= I2CSend;
                    after_state <= 7;  
                    WaitValue <= 50;
                when 7 =>  -- 50us wait 
                    POLCDData <= "00001000";
                    state <= I2CSend;
                    after_state <= 8;
                    WaitValue <= 10;
                when 8 =>   -- function set - str 2
                    POLCDData <= "00101100";    
                    state <= I2CSend;
                    after_state <= 9;
                    WaitValue <= 10;
                when 9 =>  -- 10us wait 
                    POLCDData <= "00001000";
                    state <= I2CSend;
                    after_state <= 10;
                    WaitValue <= 10;
                when 10 => -- function set - str 3 
                    POLCDData <= "10001100";  -- N:1 F:1
                    state <= I2CSend;
                    after_state <= 11;
                    WaitValue <= 50;
                when 11 =>  -- 50us wait 
                    POLCDData <= "00001000";
                    state <= I2CSend;
                    after_state <= 12;
                    WaitValue <= 10;
                when 12 => -- function set - str 4
                    POLCDData <= "00001100";
                    state <= I2CSend;
                    after_state <= 13;
                    WaitValue <= 10;
                when 13 =>  -- 10us wait 
                    POLCDData <= "00001000";
                    state <= I2CSend;
                    after_state <= 14;
                    WaitValue <= 10;     
                when 14 => -- function set - str 5 
                    POLCDData <= "11001100";    -- Display ON/OFF - D - C - B
                    state <= I2CSend;
                    WaitValue <= 50;
                    after_state <= 15;
                when 15 =>  -- 50us wait 
                    POLCDData <= "00001000";
                    state <= I2CSend;
                    after_state <= 16;
                    WaitValue <= 10;
                when 16 => -- function set - str 6  
                    POLCDData <= "00001100";
                    state <= I2CSend;
                    after_state <= 17;
                    WaitValue <= 10;
                when 17 =>  -- 10us wait 
                    POLCDData <= "00001000";
                    state <= I2CSend;
                    after_state <= 18;
                    WaitValue <= 10;
                when 18 => -- function set - str 7
                    POLCDData <= "00011100";    -- Display clear
                    state <= I2CSend;
                    after_state <= 19;
                    WaitValue <= 2000;
                when 19 =>  -- 2ms wait
                    POLCDData <= "00001000";
                    state <= I2CSend;
                    after_state <= 20;
                    WaitValue <= 10;
                when 20 => -- function set - str 8
                    POLCDData <= "00001100";
                    state <= I2CSend;
                    after_state <= 21;
                    WaitValue <= 10;
                when 21 =>  -- 10us wait 
                    POLCDData <= "00001000";
                    state <= I2CSend;
                    after_state <= 22;
                    WaitValue <= 10;
                when 22 => -- function set - str 9
                    POLCDData <= "01111100";  -- Entry mode set
                    state <= I2CSend;
                    after_state <= 23;
                    WaitValue <= 50;
                when 23 =>  -- 50us wait 
                    POLCDData <= "00001000";
                    after_state <= 24;
                    state <= I2CSend;
                    WaitValue <= 10;
                when 24 =>
                    POBusy <= '0';
                    init_state <= 0;
                    state <= writeData;
                when others => null;
                end case;

            when I2CSend =>     -- Data Send for Initialize
                SBusyPrev <= SBusy;

                if (SBusyPrev = '0' and SBusy = '1') then
                busy_cnt <= busy_cnt + 1;
                end if;
                case busy_cnt is
                when 0 =>
                    SEnable <= '1';
                    SAddr   <= "0111111";   --Slave Address
                    SRW     <= '0';             --write
                    SDataWr <= POLCDData;
                when 1 =>
                    SEnable <= '0';
                    if (SBusy = '0') then
                    busy_cnt <= 0;
                    SBusyPrev <= '0';
                    state <= For_Wait;
                    init_state <= after_state;
                    end if;
                when others => null;
                end case;
            
            when setRamAddress =>
                

            when writeData =>
                wait_State <= writeData;
                case ready_state is
                    when 0 =>
                        POLCDData <= "01011001";    -- for e = 0 
                        state <= Send;
                        WaitValue <= 100;
                        ready_state <= 1;
                    when 1 =>
                        POLCDData <= "01011101";        -- Data Upper
                        state <= Send;
                        WaitValue <= 100;
                        ready_state <= 2;
                    when 2 =>
                        POLCDData <= "01011001";
                        state <= Send;
                        WaitValue <= 100;
                        ready_state <= 3;
                    when 3 =>
                        POLCDData <= "00001101";        -- Data Low
                        state <= Send;
                        WaitValue <= 100;
                        ready_state <= 4;
                    when 4 =>
                        POLCDData <= "00001001";
                        state <= Send;
                        WaitValue <= 100;
                        ready_state <= 5;
                    when 5 =>                   -- for out the state
                        state <= Idle;
                        
                    when others =>
                        null;
                end case;
                

            when Send =>
                SBusyPrev <= SBusy;

                if (SBusyPrev = '0' and SBusy = '1') then
                busy_cnt <= busy_cnt + 1;
                end if;
                case busy_cnt is
                when 0 =>
                    SEnable <= '1';
                    SAddr   <= "0111111";   -- Slave Address
                    SRW     <= '0';             --write
                    SDataWr <= POLCDData;
                when 1 =>
                    SEnable <= '0';
                    if (SBusy = '0') then
                    busy_cnt <= 0;
                    SBusyPrev <= '0';
                    state <= For_Wait;
                    end if;
                when others => null;
                end case;

            when Idle =>
                null;
            
            when others =>
                null;
            
        end case;
    end if;
end process;

 Master : I2CMaster
  generic map(
    input_clk => 100_000_000,   -- 100MHz
    bus_clk   => 100_000)       -- 100kHz

  port map(
    clk       => PISysClk,
    reset_n   => PIReset,
    ena       => SEnable,
    addr      => SAddr,
    rw        => SRW,
    data_wr   => SDataWr,
    busy      => SBusy,
    data_rd   => SDataRd,
    ack_error => SAckError,
    sda       => PIOSDA,
    scl       => PIOSCL
  );

end Behavioral;