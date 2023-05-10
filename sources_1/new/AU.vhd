library IEEE, work;
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
            en_scale            : in STD_LOGIC;
            en_2nd_stage        : in STD_LOGIC;
            rdata_sample        : in signed(c_data_w-1 downto 0);
            rdata_coeff         : in signed(c_data_w-1 downto 0);
            wreg_c              : out signed(c_data_w-1 downto 0)
        );
end au;

architecture rtl of au is
-------------------------------------------------------------------------------------------------
--signals----------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
signal prod_pipe_c          : signed(c_prod_w-1 downto 0);
signal prod_pipe_s          : signed(c_prod_w-1 downto 0);
signal prod_pipe_s_floored  : signed(c_prod_w-1 downto 0);
signal acc_c                : signed(c_acc_w-1 downto 0);
signal acc_c_floored        : signed(c_acc_w-1 downto 0);
signal acc_mux_out           : signed(c_acc_w-1 downto 0);
signal acc_s                : signed(c_acc_w downto 0);
signal acc                  : signed(c_acc_w downto 0);
--temp


----------------------
-------------------------------------------------------------------------------------------------
begin
p_reg: process (clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            prod_pipe_s <= (others => '0');
            acc_s <= (others => '0');
        else
            --arithmetic regiters
            acc_s <= resize(acc_mux_out, c_acc_w+1);
            prod_pipe_s <= prod_pipe_c;
        end if;
    end if;
end process;

p_prod: prod_pipe_c <= rdata_sample * rdata_coeff;

prod_pipe_s_floored <=  resize(prod_pipe_s(c_wreg_high downto c_wreg_low)
                            &(c_wreg_low-1 downto 0 => '0'), c_prod_w) when en_calc = '1'
                        else
                            (others => '0');

p_acc: process(acc_s, prod_pipe_s, prod_pipe_s_floored, en_scale, en_1st_stage,
                en_2nd_stage)
--floor product of scale and 1st stage result----------------------------------------------
begin
    -- normal addition in 2nd stage
    acc <= acc_s + resize(prod_pipe_s, c_acc_w + 1);
    --rounding and subtraction
    if en_scale = '1' then -- round prod to 13 frac bits after scale
        acc <= acc_s + resize(prod_pipe_s_floored, c_acc_w+1);
    elsif en_1st_stage = '1' then -- subtract in 1st stage
        acc <= acc_s - resize(prod_pipe_s, c_acc_w + 1);
    end if;
-------------------------------------------------------------------------------------------------
end process;

--saturation
p_acc_overflow: acc_c <=    ('0'&(c_acc_w-2 downto 0 => '1')) --positive saturation
                            when ((acc(c_acc_w) = '0') AND (acc(c_acc_w-1) /= '0')) else
                            ('1'&(c_acc_w-2 downto 0 => '0')) --negative saturation
                            when ((acc(c_acc_w) = '1') AND (acc(c_acc_w-1) /= '1')) else
                            acc(c_acc_w-1 downto 0);

p_acc_floored:  acc_c_floored <= --positive saturation (to c_data_w)
                    c_acc_sat_pos when 
                        ((acc(c_acc_w) = '0')
                        AND (acc(c_acc_w-1 downto c_wreg_high) /= 0))
                else    --negative saturation (to c_data_w)
                    c_acc_sat_neg when 
                        ((acc(c_acc_w) = '1')
                        AND (acc(c_acc_w-1 downto c_wreg_high) /= c_neg_one(c_len_mul_int-1 downto 0)))
                else    -- floor to 16 digits       
                    resize(acc(c_wreg_high downto c_wreg_low)
                    &(c_wreg_low-1 downto 0 => '0'),c_acc_w);

                            -- floor 1st stage result
p_acc_mux: acc_mux_out <=   acc_c_floored when en_2nd_stage = '1' AND en_acc = '1' else
                            -- else normal sum
                            acc_c when en_acc = '1' else
                            -- else zeros
                            (others => '0');

p_wreg: wreg_c <=   
            ('0'&(c_data_w-2 downto 0 => '1')) when -- positive saturation
                ((acc(c_acc_w) = '0')
                AND (acc(c_acc_w-1 downto c_wreg_high) /= 0))
        else
            ('1'&(c_data_w-2 downto 0 => '0')) when -- negative saturation
                ((acc(c_acc_w) = '1')
                AND (acc(c_acc_w-1 downto c_wreg_high) /= c_neg_one))
        else
            acc(c_wreg_high downto c_wreg_low);


end rtl;
