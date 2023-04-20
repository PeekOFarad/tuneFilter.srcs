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

entity au is
    Port (  clk                 : in STD_LOGIC;
            rst                 : in STD_LOGIC;
            en_acc              : in STD_LOGIC;
            en_1st_stage        : in STD_LOGIC;
            en_calc             : in STD_LOGIC;
            rdata_sample        : in signed(c_data_w-1 downto 0);
            rdata_coeff         : in signed(c_data_w-1 downto 0);
            wreg_c              : out signed(c_data_w-1 downto 0)
        );
end au;

architecture rtl of au is
-------------------------------------------------------------------------------------------------
--types------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
type t_state is (idle, init, run);
-------------------------------------------------------------------------------------------------
--signals----------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

--arithmetics
signal mul_pipe_c, mul_pipe_s : signed(c_mul_w-1 downto 0);
signal acc_c, acc_s : signed(c_acc_w-1 downto 0);
signal acc : signed(c_acc_w downto 0);
-------------------------------------------------------------------------------------------------
begin
p_reg: process (clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            mul_pipe_s <= (others => '0');
            acc_s <= (others => '0');
        else
            --arithmetic regiters
            mul_pipe_s <= mul_pipe_c;
            if en_acc = '1' then --accumulator enable
                acc_s <= acc_c;
                mul_pipe_s <= mul_pipe_c;
            else
                acc_s <= (others => '0');
                mul_pipe_s <= (others => '0');
            end if;
        end if;
    end if;
end process;

p_mul: mul_pipe_c <=    rdata_sample * rdata_coeff when en_calc = '1' else
                        (others => '0');

p_acc: process(en_1st_stage, acc_s, mul_pipe_s)
begin
    if en_1st_stage = '1' then -- subtract wreg1_ss of a2 and a3 products
        acc <= resize(acc_s, c_acc_w + 1) - resize(mul_pipe_s, c_acc_w + 1);
    else      
        acc <= resize(acc_s, c_acc_w + 1) + resize(mul_pipe_s, c_acc_w + 1);
    end if;
end process;

--saturation
p_acc_overflow: acc_c <=    ('0'&(c_acc_w-2 downto 0 => '1')) --positive saturation
                            when ((acc(c_acc_w) = '0') AND (acc(c_acc_w-1) /= '0')) else
                            ('1'&(c_acc_w-2 downto 0 => '0')) --negative saturation
                            when ((acc(c_acc_w) = '1') AND (acc(c_acc_w-1) /= '1')) else
                            acc(c_acc_w-1 downto 0);

p_wreg: wreg_c <=   ('0'&(c_data_w-2 downto 0 => '1')) --positive saturation
            when ((acc(c_acc_w) = '0') AND (acc(c_acc_w-1 downto c_wreg_high) /= 0)) else
            ('1'&(c_data_w-2 downto 0 => '0')) --negative saturation
            when ((acc(c_acc_w) = '1') AND (acc(c_acc_w-1 downto c_wreg_high) /= c_neg_one)) else
            acc(c_wreg_high downto c_wreg_low);


end rtl;
