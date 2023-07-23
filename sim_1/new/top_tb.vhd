library IEEE, work;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;
use work.tuneFilter_pkg.all;
use work.master_bfm_pkg.all;

entity top_tb is
end;

architecture bench of top_tb is

  component top
    Port (  clk                 : in STD_LOGIC;
            rst                 : in STD_LOGIC;
            RQ                  : in STD_LOGIC;
            CFG                 : in STD_LOGIC;
            input               : in std_logic_vector(c_data_w-1 downto 0);
            -- waddr_coeff         : in std_logic_vector(c_coeff_addr_w-1 downto 0);
            waddr_coeff         : in std_logic_vector(9 downto 0);
            GNT                 : out STD_LOGIC;
            RDY                 : out STD_LOGIC;
            output              : out std_logic_vector(c_data_w-1 downto 0)
        );
  end component;

  signal clk, rst, RQ, CFG : STD_LOGIC;
  signal input : std_logic_vector(c_data_w-1 downto 0);
  signal GNT, RDY : STD_LOGIC;
  signal output : std_logic_vector(c_data_w-1 downto 0);
  --signal waddr_coeff : std_logic_vector(c_coeff_addr_w-1 downto 0);
  signal waddr_coeff : std_logic_vector(9 downto 0);

begin
-------------------------------------------------------------------------------------------------
--CLOCK------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
clocking: process
begin
  loop
    clk <= '0', '1' after clk_period / 2;
    wait for clk_period;
  end loop;
  wait;
end process;

-- reset: process
-- begin
--   loop
--     rst   <= '1', '0' after 5 *clk_period;
--   wait for 
  
-- end process;


uut: top 
  port map ( 
    clk    => clk,
    rst    => rst,
    RQ     => RQ,
    CFG    => CFG,
    input  => input,
    waddr_coeff => waddr_coeff,
    GNT    => GNT,
    RDY    => RDY,
    output => output
  );

bfm: entity work.master_bfm(behavioral)
  port map ( 
    rst         => rst,
    --link signals
    GNT         => GNT,   
    RDY         => RDY,   
    master_in   => output,
    RQ          => RQ,
    CFG         => CFG,
    waddr_coeff => waddr_coeff,
    master_out  => input
  );
end;
