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
    PIReset       : in std_logic
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
    data_rd   : out std_logic_vector(7 downto 0);
    ack_error : buffer std_logic;
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
    Initialize,
    Ready,
    Send,
    I2CSend
    );

signal state : machine := PowerUp;
signal after_state : machine := PowerUp;
signal SClockCounter : integer := 0;
signal POLCDData     : std_logic_vector(7 downto 0);   -- Data included 4-Bit interface for I2C Com 
signal ReadyCheck : std_logic := '0';

-- DEBUG
attribute mark_debug : string;
attribute mark_debug of POLCDData : signal is "1";
attribute mark_debug of SEnable : signal is "1";
attribute mark_debug of ReadyCheck : signal is "1";


-- DEBUG END

begin

process (PISysClk)
begin
    if PISysClk'event and PISysClk = '1' then
        case state is
            when PowerUp =>
                POBusy <= '1';          -- wait time that more than 15ms, I selected it 50ms
                if (SClockCounter < (50000000 * GSysClk - 1)) then       -- 50ms wait ** 1000 added for test
                    SClockCounter <= SClockCounter + 1;
                else
                    -- 
                    SEnable <= '1';
                    SAddr   <= "0111111";
                    --
                    SClockCounter <= 0;
                    state <= Initialize;
                end if;

            when Initialize =>
                POBusy <= '1';
                SClockCounter <= SClockCounter + 1;

                if SClockCounter < (10 * GSysClk) then      -- function set
                    POLCDData <= "00110100";
                    state <= I2CSend;
                elsif SClockCounter < (5000 * GSysClk)  then  -- 5ms wait (more than 4.1ms wait)
                    POLCDData <= (others => '0');
                    state <= I2CSend;
                elsif SClockCounter < (5010 * GSysClk) then -- function set
                    POLCDData <= "00110100";
                    state <= I2CSend;
                elsif SClockCounter < (5110 * GSysClk)  then  -- 100us wait 
                    POLCDData <= (others => '0');
                    state <= I2CSend;
                elsif SClockCounter < (5120 * GSysClk) then -- function set
                    POLCDData <= "00110100";
                    state <= I2CSend;
                elsif SClockCounter < (5170 * GSysClk)  then  -- 50us wait 
                    POLCDData <= (others => '0');
                    state <= I2CSend;
                elsif SClockCounter < (5180 * GSysClk) then -- function set - str 1
                    POLCDData <= "00100100";
                    state <= I2CSend;
                elsif SClockCounter < (5230 * GSysClk)  then  -- 50us wait 
                    POLCDData <= (others => '0');
                    state <= I2CSend;
                elsif SClockCounter < (5240 * GSysClk) then -- function set - str 2
                    POLCDData <= "00100100";
                    state <= I2CSend;
                elsif SClockCounter < (5250 * GSysClk)  then  -- 10us wait 
                    POLCDData <= (others => '0');
                    state <= I2CSend;
                elsif SClockCounter < (5260 * GSysClk) then -- function set - str 3 - N:1 F:1
                    POLCDData <= "11000100";
                    state <= I2CSend;
                elsif SClockCounter < (5310 * GSysClk)  then  -- 50us wait 
                    POLCDData <= (others => '0');
                    state <= I2CSend;
                elsif SClockCounter < (5320 * GSysClk) then -- function set - str 4
                    POLCDData <= "00000100";
                    state <= I2CSend;
                elsif SClockCounter < (5330 * GSysClk)  then  -- 10us wait 
                    POLCDData <= (others => '0');
                    state <= I2CSend;
                elsif SClockCounter < (5340 * GSysClk) then -- function set - str 5     -- Display ON/OFF
                    POLCDData <= "11110100";
                    state <= I2CSend;
                elsif SClockCounter < (5390 * GSysClk)  then  -- 50us wait 
                    POLCDData <= (others => '0');
                    state <= I2CSend;
                elsif SClockCounter < (5400 * GSysClk) then -- function set - str 6
                    POLCDData <= "00000100";
                    state <= I2CSend;
                elsif SClockCounter < (5410 * GSysClk)  then  -- 10us wait 
                    POLCDData <= (others => '0');
                    state <= I2CSend;
                elsif SClockCounter < (5420 * GSysClk) then -- function set - str 7
                    POLCDData <= "00010100";
                    state <= I2CSend;
                elsif SClockCounter < (7420 * GSysClk)  then  -- 2ms wait
                    POLCDData <= (others => '0');
                    state <= I2CSend;
                elsif SClockCounter < (7430 * GSysClk) then -- function set - str 8
                    POLCDData <= "00000100";
                    state <= I2CSend;
                elsif SClockCounter < (7440 * GSysClk)  then  -- 10us wait 
                    POLCDData <= (others => '0');
                    state <= I2CSend;
                elsif SClockCounter < (7450 * GSysClk) then -- function set - str 9
                    POLCDData <= "00100100";
                    state <= I2CSend;
                elsif SClockCounter < (7500 * GSysClk)  then  -- 50us wait 
                    POLCDData <= (others => '0');
                    state <= I2CSend;
                else
                    SClockCounter <= 0;
                    POBusy <= '0';
                    state <= Ready;
                end if;

            when I2CSend =>
                -- SBusyPrev <= SBusy;

                -- if (SBusyPrev = '0' and SBusy = '1') then
                -- busy_cnt <= busy_cnt + 1;
                -- end if;
                -- case busy_cnt is
                -- when 0 =>
                    -- SEnable <= '1';
                    -- SAddr   <= "0111111";
                    SRW     <= '0';             --write
                    SDataWr <= POLCDData;
                -- when 1 =>
                    --SEnable <= '0';
                    if (SBusy = '0') then
                    -- busy_cnt <= 0;
                    -- SBusyPrev <= '0';
                    state <= Initialize;
                    end if;
                -- when others => null;
                -- end case;

            when Ready =>
                ReadyCheck <= '1';


            when Send =>
                

            
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
