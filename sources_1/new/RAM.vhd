-------------------------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/10/2023 10:02:35 AM
-- Design Name: 
-- Module Name: control - Behavioral
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
-------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.tuneFilter_pkg.all;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ram is
    Port (  clk             : in STD_LOGIC;
            we_sample_mem   : in STD_LOGIC;
            we_coeff_mem    : in STD_LOGIC;
            raddr_sample    : in unsigned(c_len_cnt_section+c_len_cnt_sample-1 downto 0);
            waddr_sample    : in unsigned(c_len_cnt_section+c_len_cnt_sample-1 downto 0);
            raddr_coeff     : in unsigned(c_coeff_addr_w-1 downto 0);     
            waddr_coeff     : in unsigned(c_coeff_addr_w-1 downto 0);
            wdata_sample    : in signed(c_data_w-1 downto 0);
            wdata_coeff     : in signed(c_data_w-1 downto 0);
            rdata_coeff     : out signed(c_data_w-1 downto 0);
            rdata_sample    : out signed(c_data_w-1 downto 0)
        );
end ram;

architecture rtl of ram is
-------------------------------------------------------------------------------------------------
--signals----------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--SRAM
--TODO: create generic entity and add two instances
signal sample_mem : t_sample_mem;
signal coeff_mem : t_coeff_mem;
-------------------------------------------------------------------------------------------------
--attributes-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
attribute ram_style : string;
attribute ram_style of sample_mem : signal is "block";
attribute ram_style of coeff_mem : signal is "block"; 
-------------------------------------------------------------------------------------------------
begin

--sample memory write
p_sample_memory: process (clk)
begin
    if rising_edge(clk) then
        if we_sample_mem = '1' then
            sample_mem(to_integer(waddr_sample)) <= wdata_sample; --write
        end if;
        rdata_sample <= sample_mem(to_integer(raddr_sample)); --read
    end if;
end process;
--coefficient memory write
p_coeff_memory: process (clk, we_coeff_mem, wdata_coeff, waddr_coeff)
begin
    if rising_edge(clk) then
        if we_coeff_mem = '1' then
            coeff_mem(to_integer(waddr_coeff)) <= wdata_coeff; --write
        end if;
        rdata_coeff <= coeff_mem(to_integer(raddr_coeff)); --read
    end if;
end process;

end rtl;
