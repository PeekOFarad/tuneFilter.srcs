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


library IEEE, work;
use IEEE.STD_LOGIC_1164.ALL;
use work.tuneFilter_pkg.all;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity control is
    Port (  clk                 : in STD_LOGIC;
            rst                 : in STD_LOGIC;
            RQ                  : in STD_LOGIC;
            CFG                 : in STD_LOGIC;
            input               : in signed(c_data_w-1 downto 0);
            rdata_sample        : in signed(c_data_w-1 downto 0);
            wreg_c              : in signed(c_data_w-1 downto 0);
            waddr_coeff         : in unsigned(c_coeff_addr_w-1 downto 0);
            GNT                 : out STD_LOGIC;
            RDY                 : out STD_LOGIC;
            we_sample_mem       : out STD_LOGIC;
            we_coeff_mem        : out STD_LOGIC;
            en_1st_stage        : out STD_LOGIC;
            en_acc              : out STD_LOGIC;
            en_calc             : out STD_LOGIC;
            raddr_sample        : out unsigned(c_sample_addr_w-1 downto 0);
            waddr_sample        : out unsigned(c_sample_addr_w-1 downto 0);        
            raddr_coeff         : out unsigned(c_coeff_addr_w-1 downto 0);
            waddr_coeff_int     : out unsigned(c_coeff_addr_w-1 downto 0);
            wdata_sample        : out signed(c_data_w-1 downto 0);
            wdata_coeff         : out signed(c_data_w-1 downto 0);
            output              : out signed(c_data_w-1 downto 0)
        );
end control;

architecture rtl of control is
-------------------------------------------------------------------------------------------------
--types------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
type t_state is (idle, run);
-------------------------------------------------------------------------------------------------
--signals----------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--internal memory
signal wreg0_s, wreg1_s : signed(c_data_w-1 downto 0);

--FSM
signal state, next_state : t_state := idle;
--enable and control signals
signal  RQ_s, CFG_s, GNT_c, RDY_c, en_cnt, en_section_end, flag_init_s,
        flag_init_c, en_init, en_init_done, en_old_delay, en_new_delay, en_result : std_logic;
--counters
signal cnt_coeff_c, cnt_coeff_s :  unsigned(c_len_cnt_coeff-1 downto 0);
signal cnt_sample :  unsigned(c_len_cnt_sample-1 downto 0);
signal cnt_section_c, cnt_section_s : unsigned(c_len_cnt_section-1 downto 0);
-------------------------------------------------------------------------------------------------
begin
p_reg: process (clk)
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
            flag_init_s <= '1';
        else
            --reset flag
            flag_init_s <= flag_init_c;
            --FSM
            state <= next_state;
            --output registers
            if RDY_c = '1' then --temporary output
                output <= wreg1_s;
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
            if en_new_delay = '1' AND flag_init_s = '0' then
                wreg0_s <= wreg_c; --stores 1st section result
            end if;
            if flag_init_s = '0' then
                if en_old_delay = '1' then
                    wreg1_s <= rdata_sample; --stores old delay
                elsif en_result = '1' then
                    wreg1_s <= wreg_c; --stores section result
                end if;
            end if;
        end if;
    end if;
end process;

p_counters: process (en_cnt, en_section_end, cnt_coeff_s, cnt_section_s)
begin
    cnt_coeff_c <= (others => '0');
    cnt_section_c <= (others => '0');
    cnt_sample <= (others => '0');
    --coefficient memory counter
    if en_cnt = '1' then
        if en_section_end = '1' then
            cnt_coeff_c <= (others => '0');
        else
            cnt_coeff_c <= cnt_coeff_s + 1;
        end if;
    end if;
    --section counter
    if en_cnt = '1' then
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

P_rst_flag: flag_init_c <=  flag_init_s when en_init_done = '0' else
                            '0' when en_init_done = '1';                

p_fsm: process (state, RQ_s, CFG_s, input, cnt_sample, cnt_coeff_s,cnt_section_s, wreg0_s,
                wreg1_s, waddr_coeff)
begin
    --handshake
    GNT_c <= '0';
    RDY_c <= '0';
    --write enables
    we_sample_mem <= '0';
    we_coeff_mem <= '0';
    --enable signals
    en_cnt <= '0';
    en_calc <= '0';
    en_section_end <= '0';
    en_acc <= '0';
    en_1st_stage <= '0';
    en_old_delay <= '0';
    en_new_delay <= '0';
    en_result <= '0';
    en_init <= '0';
    en_init_done <= '0';
    --signals
    wdata_sample <= (others => '0');
    waddr_sample <= (others => '0');
    raddr_sample <= (others => '0');
    wdata_coeff <= (others => '0');
    waddr_coeff_int <= (others => '0');
    raddr_coeff <= (others => '0');
        
    case (state) is

        when idle => --wait for new data or initialization
            next_state <= idle;
            if CFG_s = '1' AND flag_init_s = '0' then
                we_coeff_mem <= '1';
                waddr_coeff_int <= waddr_coeff;
                wdata_coeff <= input;
            end if;
            if flag_init_s = '1' then
                en_init <= '1';
                en_cnt <= '1';
                we_sample_mem <= '1';
                wdata_sample <= (others => '0');
                waddr_sample <= cnt_section_s & cnt_coeff_s(1 downto 0);
                if cnt_coeff_s >= 2**c_len_cnt_sample-1 then
                    en_section_end <= '1';
                end if;
                if (cnt_coeff_s >= 2**c_len_cnt_sample-1)
                AND (cnt_section_s >= (c_f_order/c_s_order-1)) then 
                    RDY_c <= '1';
                    en_init_done <= '1';
                end if; 
            elsif RQ_s = '1' AND flag_init_s = '0' then --data valid
                GNT_c <= '1';
                we_sample_mem <= '1';
                waddr_sample <= (others => '0');
                wdata_sample <= input;
                next_state <= run;
            end if;
        
        when run =>
            en_cnt <= '1';
            en_calc <= '1';
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
                    waddr_sample <= 
                        shift_left(resize(cnt_section_s, waddr_sample'length), 2) + 4; 
                    wdata_sample <= wreg1_s;
                end if;
            end if;

        when others =>
            next_state <= idle;

    end case;
end process;

end rtl;
