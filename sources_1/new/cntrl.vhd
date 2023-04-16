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
            input               : in std_logic_vector(c_data_w-1 downto 0);
            GNT, RDY            : out STD_LOGIC;
            output              : out std_logic_vector(c_data_w-1 downto 0));
end control;

architecture Behavioral of control is
-------------------------------------------------------------------------------------------------
--types------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
type t_state is (idle, init, run);
-------------------------------------------------------------------------------------------------
--signals----------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--SRAM
signal sample_mem : t_sample_mem;
signal coeff_mem : t_coeff_mem;
--read and write signals
signal wdata_sample, wdata_coeff, rdata_sample_s, rdata_coeff_s : signed(c_data_w-1 downto 0); 
signal waddr_sample, raddr_sample : unsigned(c_len_cnt_section+c_len_cnt_sample-1 downto 0);
signal waddr_coeff, raddr_coeff : unsigned(c_len_cnt_section+c_len_cnt_coeff-1 downto 0);
signal we_sample_mem, we_coeff_mem : std_logic;
--internal memory
signal wreg_c, wreg0_s, wreg1_s : signed(c_data_w-1 downto 0);
--FSM
signal state, next_state : t_state := idle;
--enable and control signals
signal RQ_s, CFG_s, GNT_c, RDY_c, en_cnt_coeff, en_cnt_section, en_section_end, en_acc, en_init 
    : std_logic;
--counters
signal cnt_coeff_c, cnt_coeff_s :  unsigned(c_len_cnt_coeff-1 downto 0);
signal cnt_sample :  unsigned(c_len_cnt_sample-1 downto 0);
signal cnt_section_c, cnt_section_s : unsigned(c_len_cnt_section-1 downto 0);
--arithmetics
signal mul_pipe_c, mul_pipe_s : signed(c_mul_w-1 downto 0);
signal acc_c, acc_s : signed(c_acc_w-1 downto 0);
signal acc : signed(c_acc_w downto 0);
-------------------------------------------------------------------------------------------------
begin
p_reg: process (clk, rst)
begin
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
    elsif rising_edge(clk) then
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
        --arithmetic regiters
        mul_pipe_s <= mul_pipe_c;

        if en_acc = '1' then --accumulator enable
            acc_s <= acc_c;
            mul_pipe_s <= mul_pipe_c;
        else
            acc_s <= (others => '0');
            mul_pipe_s <= (others => '0');
        end if;
        --internal memory registers
        if cnt_coeff_s = 4 AND en_init = '0' then
            wreg0_s <= wreg_c; --feddback wreg1_s
        end if;
        if en_init = '0' then
            --TODO: use enable signals to split combinational and sequential?
            if cnt_coeff_s = 2 then
                wreg1_s <= rdata_sample_s; --stores new delay
            elsif cnt_coeff_s = 6 then
                wreg1_s <= wreg_c; --stores old delay for memory rewrite and section result
            end if;
        end if;
        --enable signals
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
    --signals
    wdata_sample <= (others => '0');
    waddr_sample <= (others => '0');
    raddr_sample <= (others => '0');
    wdata_coeff <= (others => '0');
    waddr_coeff <= (others => '0');
    raddr_coeff <= (others => '0');
        
    case (state) is

        when idle => --wait for new data or initialization
            if RQ_s = '1' then --data valid
                GNT_c <= '1';
                we_sample_mem <= '1';
                wdata_sample <= signed(input);
                waddr_sample <= (others => '0');
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
            wdata_coeff <= signed(input);
            wdata_sample <= (others => '0');
            waddr_coeff <= cnt_section_s & cnt_coeff_s;
            --cnt_coeff chosen to reach all memory addresses (cnt_sample only goes to 2)
            waddr_sample <= cnt_section_s & cnt_coeff_s(1 downto 0);
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
            if (cnt_coeff_s >= 1) AND (cnt_coeff_s <= 6) then --5 accumulate operations
                en_acc <= '1';
            end if;
            --select coresponding addresses
            raddr_coeff <= cnt_section_s & cnt_coeff_s;
            raddr_sample <= cnt_section_s & cnt_sample;
            --rewrite memory with new data while waiting for wreg1_s
            if cnt_coeff_s >= 5 then --write enable when new delay is ready in wreg0_s
                we_sample_mem <= '1';
            end if;

            next_state <= run;
            if cnt_coeff_s = 5 then
                waddr_sample <= cnt_section_s & "01"; --delay(0) <= new_delay
                wdata_sample <= wreg0_s;
            elsif cnt_coeff_s = 6 then
                waddr_sample <= cnt_section_s & "10"; --delay(1) <= delay(0)
                wdata_sample <= wreg1_s;
            elsif cnt_coeff_s = 7 then
                en_section_end <= '1';
                --if on last section, go to idle
                if (cnt_section_s >= c_f_order/c_s_order-1) then 
                    RDY_c <= '1';
                    next_state <= idle;
                else --else write section output to next section input
                    waddr_sample <= shift_left(resize(cnt_section_s, waddr_sample'length), 2)
                                    + 4; 
                    wdata_sample <= wreg1_s;
                end if;
            end if;

        when others =>
            next_state <= idle;

    end case;
end process;

p_mul: mul_pipe_c <= rdata_sample_s * rdata_coeff_s;

p_acc: process(cnt_coeff_s, acc_s, mul_pipe_s)
begin
    if cnt_coeff_s >= 3 and cnt_coeff_s <= 4 then -- subtract wreg1_ss of a2 and a3 products
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

--sample memory write
p_sample_memory: process (clk, rst, we_sample_mem, wdata_sample, waddr_sample)
begin
    if rising_edge(clk) then
        if we_sample_mem = '1' then
            sample_mem(to_integer(waddr_sample)) <= wdata_sample; --write
        end if;
        rdata_sample_s <= sample_mem(to_integer(raddr_sample)); --read
    end if;
end process;
--coefficient memory write
p_coeff_memory: process (clk, we_coeff_mem, wdata_coeff, waddr_coeff)
begin
    if rising_edge(clk) then
        if we_coeff_mem = '1' then
            coeff_mem(to_integer(waddr_coeff)) <= wdata_coeff; --write
        end if;
        rdata_coeff_s <= coeff_mem(to_integer(raddr_coeff)); --read
    end if;
end process;

end Behavioral;
