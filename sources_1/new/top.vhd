----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 02/10/2023 10:02:35 AM
-- Design Name:
-- Module Name: top - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tuneFilter_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity top is
  Port (    clk                 : in STD_LOGIC;
            rst                 : in STD_LOGIC;
            RQ                  : in STD_LOGIC;
            CFG                 : in STD_LOGIC;
            input               : in std_logic_vector(c_data_w-1 downto 0);
            GNT                 : out STD_LOGIC;
            RDY                 : out STD_LOGIC;
            output              : out std_logic_vector(c_data_w-1 downto 0));
end entity top;

architecture structural of top is

signal wdata_sample   : signed(c_data_w-1 downto 0);
signal wdata_coeff    : signed(c_data_w-1 downto 0);
signal rdata_sample   : signed(c_data_w-1 downto 0);
signal rdata_coeff    : signed(c_data_w-1 downto 0);
signal wreg_c         : signed(c_data_w-1 downto 0);
signal output_int     : signed(c_data_w-1 downto 0);
signal waddr_sample   : unsigned(c_len_cnt_section+c_len_cnt_sample-1 downto 0);
signal raddr_sample   : unsigned(c_len_cnt_section+c_len_cnt_sample-1 downto 0);
signal waddr_coeff    : unsigned(c_len_cnt_section+c_len_cnt_coeff-1 downto 0);
signal raddr_coeff    : unsigned(c_len_cnt_section+c_len_cnt_coeff-1 downto 0);
signal we_sample_mem, we_coeff_mem, en_1st_stage, en_acc : std_logic;

begin

output <= std_logic_vector(output_int);

i0_control: entity work.control(rtl)
  Port map(
    clk => clk,
    rst => rst,
    RQ => RQ,
    CFG => CFG,
    input => signed(input),
    rdata_sample => rdata_sample,
    wreg_c => wreg_c,
    GNT => GNT,
    RDY => RDY,
    we_sample_mem => we_sample_mem,
    we_coeff_mem => we_coeff_mem,
    en_1st_stage => en_1st_stage,
    en_acc => en_acc,
    raddr_sample => raddr_sample,
    waddr_sample => waddr_sample,
    raddr_coeff => raddr_coeff,
    waddr_coeff => waddr_coeff,
    wdata_sample => wdata_sample,
    wdata_coeff => wdata_coeff,
    output => output_int
  );

i0_AU: entity work.au(rtl)
  port map (
    clk => clk,
    rst => rst,
    en_acc => en_acc,
    en_1st_stage => en_1st_stage,
    rdata_sample => rdata_sample,
    rdata_coeff => rdata_coeff,
    wreg_c => wreg_c
  );

-- i0_RAM: entity work.ram(rtl)
--   port map (
--     clk => clk,            
--     we_sample_mem => we_sample_mem,
--     we_coeff_mem => we_coeff_mem,        
--     raddr_sample => raddr_sample,
--     waddr_sample => waddr_sample,
--     wdata_sample => wdata_sample,
--     raddr_coeff => raddr_coeff,
--     waddr_coeff => waddr_coeff,
--     wdata_coeff => wdata_coeff,
--     rdata_coeff => rdata_coeff,
--     rdata_sample => rdata_sample
--   );

i0_RAM:  entity work.g_ram(rtl)
    generic map (
      c_addr_w  => c_len_cnt_section+c_len_cnt_sample,
      c_len_mem => c_len_sample_mem
    )
    port map (
      clk   => clk,
      we    => we_sample_mem,
      raddr => raddr_sample,
      waddr => waddr_sample,
      rdata => rdata_sample,
      wdata => wdata_sample
    );

i1_RAM:  entity work.g_ram(rtl)
    generic map (
      c_addr_w  => c_len_cnt_section+c_len_cnt_coeff,
      c_len_mem => c_len_coeff_mem
    )
    port map (
      clk   => clk,
      we    => we_coeff_mem,
      raddr => raddr_coeff,
      waddr => waddr_coeff,
      rdata => rdata_coeff,
      wdata => wdata_coeff
    );

end architecture structural;
