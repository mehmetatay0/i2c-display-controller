
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity M_MasterController is
  generic (
    GSysClk : integer := 100_000_000;
    GBusClk : integer := 100_000;
    PISlaveAddr   : std_logic_vector(6 downto 0) := "0111111");
  port (
    PIClk         : in std_logic;
    PIOSDA        : inout std_logic;
    PIOSCL        : inout std_logic;
    PIEnable      : in std_logic;
    PIReset       : in std_logic;
    POBusy        : out std_logic
  );
end M_MasterController;

architecture Behavioral of M_MasterController is

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

  signal SAddr             : std_logic_vector(6 downto 0);
  signal SRW               : std_logic;
  signal SDataWr           : std_logic_vector(7 downto 0);
  signal SBusy             : std_logic;
  signal SDataRd           : std_logic_vector(7 downto 0);
  signal SEnable           : std_logic;
  signal SAckError         : std_logic;
  

  type machine is (power_up, initialize);
  signal state : machine := power_up;
  signal clk_counter : integer := 0;
    
begin

  process (PIClk, PIReset)
    
  begin
      if (PIReset = '0') then
        
      elsif (PIClk'EVENT and PIClk = '1') then
        case state is
          when power_up =>
            



          when initialize =>
            

        
          when others =>
            null;
        end case;
      end if;
  end process;

  Master : I2CMaster
  generic map(
    input_clk => GSysClk,
    bus_clk   => GBusClk)

  port map(
    clk       => PIClk,
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