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

entity control is
    Port (  clk, rst, RQ, CFG   : in STD_LOGIC;
            input,
            rdata_sample,
            wreg_c              : in std_logic_vector(c_data_w-1 downto 0);
            GNT, RDY,
            we_sample_mem,
            we_coeff_mem,
            en_1st_stage,
            en_acc              : out STD_LOGIC;
            raddr_sample,
            waddr_sample : out std_logic_vector(c_len_cnt_section+c_len_cnt_sample-1 downto 0);        
            raddr_coeff,
            waddr_coeff : out std_logic_vector(c_len_cnt_section+c_len_cnt_coeff-1 downto 0);
            wdata_sample,
            wdata_coeff,
            output              : out std_logic_vector(c_data_w-1 downto 0)
        );
end control;

architecture rtl of control is
-------------------------------------------------------------------------------------------------
--types------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
type t_state is (idle, init, run);
-------------------------------------------------------------------------------------------------
--signals----------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--SRAM
--read and write signals
signal wdata_sample_int, wdata_coeff_int, rdata_sample_int
    : signed(c_data_w-1 downto 0);

signal waddr_sample_int, raddr_sample_int
    : unsigned(c_len_cnt_section+c_len_cnt_sample-1 downto 0);

signal waddr_coeff_int, raddr_coeff_int
    : unsigned(c_len_cnt_section+c_len_cnt_coeff-1 downto 0);

--internal memory
signal wreg_c_int, wreg0_s, wreg1_s : signed(c_data_w-1 downto 0);

--FSM
signal state, next_state : t_state := idle;
--enable and control signals
signal  RQ_s, CFG_s, GNT_c, RDY_c, en_cnt_coeff, en_cnt_section, en_section_end, en_init,
        en_old_delay, en_new_delay, en_result : std_logic;
--counters
signal cnt_coeff_c, cnt_coeff_s :  unsigned(c_len_cnt_coeff-1 downto 0);
signal cnt_sample :  unsigned(c_len_cnt_sample-1 downto 0);
signal cnt_section_c, cnt_section_s : unsigned(c_len_cnt_section-1 downto 0);
-------------------------------------------------------------------------------------------------
begin
p_signal_asignment:
--sample memory
raddr_sample <= std_logic_vector(raddr_sample_int);
rdata_sample_int <= signed(rdata_sample);
waddr_sample <= std_logic_vector(waddr_sample_int);
wdata_sample <= std_logic_vector(wdata_sample_int);
--coefficient memory
raddr_coeff <= std_logic_vector(raddr_coeff_int);
waddr_coeff <= std_logic_vector(waddr_coeff_int);
wdata_coeff <= std_logic_vector(wdata_coeff_int);
wreg_c_int <= signed(wreg_c);

p_reg: process (clk, rst)
begin
    if rising_edge(clk) then
        --SYNCHRONOUS RESET
        if rst = '1' then
            wreg0_s <= (others => '0');
            wreg1_s <= (others => '0');
            state <= idle;
            output <= (others => '0');
            GNT <= '0';
            RDY <= '0';
            RQ_s <= '0';
            CFG_s <= '0';
            cnt_coeff_s <= (others => '0');
            cnt_section_s <= (others => '0');
        else
            --FSM
            state <= next_state;
            --output registers
            if RDY_c = '1' then --temporary output
                output <= std_logic_vector(wreg1_s);
            end if;
            --granted signal - data recieved
            if GNT_c = '1' then
                GNT <= '1';
            elsif RQ_s = '0' then
                GNT <= '0';
            end if;
            --ready signal - output data valid
            if RDY_c = '1' then
                RDY <= '1';
            elsif RQ_s = '1' then
                RDY <= '0';
            end if;
            --data sync ddff
            RQ_s <= RQ;
            CFG_s <= CFG; 
            --counter register
            cnt_coeff_s <= cnt_coeff_c;
            cnt_section_s <= cnt_section_c;
            --internal memory registers
            if en_new_delay = '1' AND en_init = '0' then
                wreg0_s <= wreg_c_int; --stores 1st section result
            end if;
            if en_init = '0' then
                --TODO: use enable signals to split combinational and sequential?
                if en_old_delay = '1' then
                    wreg1_s <= rdata_sample_int; --stores old delay
                elsif en_result = '1' then
                    wreg1_s <= wreg_c_int; --stores section result
                end if;
            end if;
        end if;
    end if;
end process;

p_counters: process (en_cnt_coeff, en_section_end, en_cnt_section, cnt_coeff_s, cnt_section_s)
begin
    cnt_coeff_c <= (others => '0');
    cnt_section_c <= (others => '0');
    cnt_sample <= (others => '0');
    --coefficient memory counter
    if en_cnt_coeff = '1' then
        if en_section_end = '1' then
            cnt_coeff_c <= (others => '0');
        else
            cnt_coeff_c <= cnt_coeff_s + 1;
        end if;
    end if;
    --section counter
    if en_cnt_section = '1' then
        if en_section_end = '1' then --if at the end of the section, increment
            cnt_section_c <= cnt_section_s + 1;
        else
            cnt_section_c <= cnt_section_s;
        end if;
    end if;
    --sample memory mux
    case (cnt_coeff_s) is --TODO implementovat jako funkci v pkg?
        when "000" => cnt_sample <= to_unsigned(0,c_len_cnt_sample);
        when "001" => cnt_sample <= to_unsigned(1,c_len_cnt_sample);
        when "010" => cnt_sample <= to_unsigned(2,c_len_cnt_sample);
        when "011" => cnt_sample <= to_unsigned(1,c_len_cnt_sample);
        when "100" => cnt_sample <= to_unsigned(2,c_len_cnt_sample);
        when others => null; 
    end case;
end process;


p_fsm: process (state, RQ_s, CFG_s, input, cnt_sample, cnt_coeff_s,cnt_section_s, wreg0_s,
                wreg1_s)
begin
    --handshake
    GNT_c <= '0';
    RDY_c <= '0';
    --write enables
    we_sample_mem <= '0';
    we_coeff_mem <= '0';
    --counter enables
    en_cnt_coeff <= '0';
    en_cnt_section <= '0';
    en_section_end <= '0';
    en_init <= '0';
    en_acc <= '0';
    en_1st_stage <= '0';
    en_old_delay <= '0';
    en_new_delay <= '0';
    en_result <= '0';
    --signals
    wdata_sample_int <= (others => '0');
    waddr_sample_int <= (others => '0');
    raddr_sample_int <= (others => '0');
    wdata_coeff_int <= (others => '0');
    waddr_coeff_int <= (others => '0');
    raddr_coeff_int <= (others => '0');
        
    case (state) is

        when idle => --wait for new data or initialization
            if RQ_s = '1' then --data valid
                GNT_c <= '1';
                we_sample_mem <= '1';
                wdata_sample_int <= signed(input);
                waddr_sample_int <= (others => '0');
                next_state <= run;
            elsif CFG_s = '1' then
                next_state <= init;
            else
                next_state <= idle;
            end if;

        when init => --initialize memory and load coefficients
            en_init <= '1';
            en_cnt_coeff <= '1';
            en_cnt_section <= '1';
            wdata_coeff_int <= signed(input);
            wdata_sample_int <= (others => '0');
            waddr_coeff_int <= cnt_section_s & cnt_coeff_s;
            --cnt_coeff chosen to reach all memory addresses (cnt_sample only goes to 2)
            waddr_sample_int <= cnt_section_s & cnt_coeff_s(1 downto 0);
            we_coeff_mem <= '1';
            we_sample_mem <= '1';
            --increment section counter after writing all section coefficients
            if cnt_coeff_s = (2**c_len_cnt_coeff-1) then
                en_section_end <= '1';
            end if;
            --if both counters are maxed out (all coefficients writen), jump to idle
            if (cnt_coeff_s >= (2**c_len_cnt_coeff-1))
            AND (cnt_section_s >= (c_f_order/c_s_order-1)) then 
                next_state <= idle;    
            else                       
                next_state <= init;
            end if;
        
        when run =>
            en_cnt_coeff <= '1';
            en_cnt_section <= '1';
            if cnt_coeff_s >= 1 AND cnt_coeff_s <= 6 then --5 accumulate operations
                en_acc <= '1';
            end if;
            if cnt_coeff_s >= 3 AND cnt_coeff_s <= 4 then
                en_1st_stage <= '1';
            end if;
            if cnt_coeff_s = 2 then
                en_old_delay <= '1';
            end if;
            if cnt_coeff_s = 4 then
                en_new_delay <= '1';
            end if;
            if cnt_coeff_s = 6 then
                en_result <= '1';
            end if;
            --select coresponding addresses
            raddr_coeff_int <= cnt_section_s & cnt_coeff_s;
            raddr_sample_int <= cnt_section_s & cnt_sample;
            --rewrite memory with new data while waiting for wreg1_s
            if cnt_coeff_s >= 5 then --write enable when new delay is ready in wreg0_s
                we_sample_mem <= '1';
            end if;

            next_state <= run;
            if cnt_coeff_s = 5 then
                waddr_sample_int <= cnt_section_s & "01"; --delay(0) <= new_delay
                wdata_sample_int <= wreg0_s;
            elsif cnt_coeff_s = 6 then
                waddr_sample_int <= cnt_section_s & "10"; --delay(1) <= delay(0)
                wdata_sample_int <= wreg1_s;
            elsif cnt_coeff_s = 7 then
                en_section_end <= '1';
                --if on last section, go to idle
                if (cnt_section_s >= c_f_order/c_s_order-1) then 
                    RDY_c <= '1';
                    next_state <= idle;
                else --else write section output to next section input
                    waddr_sample_int <= 
                        shift_left(resize(cnt_section_s, waddr_sample_int'length), 2) + 4; 
                    wdata_sample_int <= wreg1_s;
                end if;
            end if;

        when others =>
            next_state <= idle;

    end case;
end process;

end rtl;
