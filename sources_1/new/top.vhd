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
  Port (    clk, rst, RQ, CFG   : in STD_LOGIC;
            input               : in std_logic_vector(c_data_w-1 downto 0);
            GNT, RDY            : out STD_LOGIC;
            output              : out std_logic_vector(c_data_w-1 downto 0));
end entity top;

architecture structural of top is

signal  wdata_sample, wdata_coeff, rdata_sample, rdata_coeff,
        wreg_c : std_logic_vector(c_data_w-1 downto 0);
signal  waddr_sample, raddr_sample
        : std_logic_vector(c_len_cnt_section+c_len_cnt_sample-1 downto 0);
signal waddr_coeff, raddr_coeff : std_logic_vector(c_len_cnt_section+c_len_cnt_coeff-1 downto 0);
signal we_sample_mem, we_coeff_mem, en_1st_stage, en_acc : std_logic;

begin

i0_control: entity work.control(rtl)
  Port map(
    clk => clk,
    rst => rst,
    RQ => RQ,
    CFG => CFG,
    input => input,
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
    output => output
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

i0_RAM: entity work.ram(rtl)
  port map (
    clk => clk,            
    we_sample_mem => we_sample_mem,
    we_coeff_mem => we_coeff_mem,        
    raddr_sample => raddr_sample,
    waddr_sample => waddr_sample,
    wdata_sample => wdata_sample,
    raddr_coeff => raddr_coeff,
    waddr_coeff => waddr_coeff,
    wdata_coeff => wdata_coeff,
    rdata_coeff => rdata_coeff,
    rdata_sample => rdata_sample
  );

end architecture structural;
