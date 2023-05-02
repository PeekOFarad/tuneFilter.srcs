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
signal acc_s                : signed(c_acc_w-1 downto 0);
signal acc_s_floored        : signed(c_acc_w-1 downto 0);
signal acc                  : signed(c_acc_w downto 0);
--temp
SIGNAL prod                             : signed(31 DOWNTO 0); -- sfix32_En26
  SIGNAL prod_den                         : signed(31 DOWNTO 0); -- sfix32_En26
  SIGNAL prod_den_cast_temp               : signed(33 DOWNTO 0); -- sfix34_En26
  SIGNAL prod_den_cast                    : signed(33 DOWNTO 0); -- sfix34_En26
  SIGNAL prod_den_cast_neg                : signed(33 DOWNTO 0); -- sfix34_En26
  SIGNAL unaryminus_temp                  : signed(34 DOWNTO 0); -- sfix35_En26
-------------------------
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
            prod_pipe_s <= prod_pipe_c;
            if en_acc = '1' then --accuprodator enable
                acc_s <= acc_c;
                prod_pipe_s <= prod_pipe_c;
            else
                acc_s <= (others => '0');
                prod_pipe_s <= (others => '0');
            end if;
        end if;
    end if;
end process;

p_prod: prod_pipe_c <= rdata_sample * rdata_coeff when en_calc = '1' else
        (others => '0');
--temp
prod_den <= prod_pipe_c;

  prod_den_cast_temp <= resize(prod_den, 34);

  prod_den_cast <= prod_den_cast_temp;

  unaryminus_temp <= ('0' & prod_den_cast) WHEN prod_den_cast = "1000000000000000000000000000000000"
      ELSE -resize(prod_den_cast,35);
  prod_den_cast_neg <= (33 => '0', OTHERS => '1') WHEN unaryminus_temp(34) = '0' AND unaryminus_temp(33) /= '0'
      ELSE (33 => '1', OTHERS => '0') WHEN unaryminus_temp(34) = '1' AND unaryminus_temp(33) /= '1'
      ELSE (unaryminus_temp(33 DOWNTO 0));
--------------------------------

-- saturate to -+ 4 and floor lower 13 bits (c_wreg_low downto 0)
p_floor: acc_s_floored <=   c_acc_sat_pos when ((acc(c_acc_w) = '0')
                                AND (acc(c_acc_w-1 downto c_wreg_high) /= 0)) else
                            c_acc_sat_neg when ((acc(c_acc_w) = '1')
                                AND (acc(c_acc_w-1 downto c_wreg_high) /= c_neg_one)) else
                            resize(acc_s(c_wreg_high downto c_wreg_low)
                            &(c_wreg_low-1 downto 0 => '0'),c_acc_w);

prod_pipe_s_floored <= resize(prod_pipe_s(c_wreg_high downto c_wreg_low)
                             &(c_wreg_low-1 downto 0 => '0'),c_prod_w);

p_acc: process(acc_s, prod_pipe_s, en_scale, en_1st_stage, en_2nd_stage)
--no rounding------------------------------------------------------------------------------------
-- begin
--     if en_1st_stage = '1' then -- subtract wreg1_ss of a2 and a3 products
--         acc <= resize(acc_s, c_acc_w + 1) - resize(prod_pipe_s, c_acc_w + 1);
--     else      
--         acc <= resize(acc_s, c_acc_w + 1) + resize(prod_pipe_s, c_acc_w + 1);
--     end if;
-- end process;
-------------------------------------------------------------------------------------------------
--floor round product of scale and 1st stage result----------------------------------------------
begin
    -- normal addition in 2nd stage
    acc <= resize(acc_s, c_acc_w + 1) + resize(prod_pipe_s, c_acc_w + 1);
    --rounding and subtraction
    if en_scale = '1' then -- round prod to 13 frac bits after scale
        acc <= resize(acc_s, c_acc_w + 1) + resize(prod_pipe_s_floored, c_acc_w+1);
    elsif en_1st_stage = '1' then -- subtract in 1st stage
        acc <= resize(acc_s, c_acc_w + 1) + resize(prod_den_cast_neg, 34);-- - resize(prod_pipe_s, c_acc_w + 1);
    elsif en_2nd_stage = '1' then --round acc to 13 frac bits after 1st stage
        acc <= resize(acc_s_floored, c_acc_w + 1) + resize(prod_pipe_s, c_acc_w + 1);
    end if;
-------------------------------------------------------------------------------------------------
end process;

--saturation
p_acc_overflow: acc_c <=    ('0'&(c_acc_w-2 downto 0 => '1')) --positive saturation
                            when ((acc(c_acc_w) = '0') AND (acc(c_acc_w-1) /= '0')) else --
                            ('1'&(c_acc_w-2 downto 0 => '0')) --negative saturation
                            when ((acc(c_acc_w) = '1') AND (acc(c_acc_w-1) /= '1')) else --
                            acc(c_acc_w-1 downto 0);

p_wreg: wreg_c <=   ('0'&(c_data_w-2 downto 0 => '1')) --positive saturation
            when ((acc(c_acc_w) = '0') AND (acc(c_acc_w-1 downto c_wreg_high) /= 0)) else
            ('1'&(c_data_w-2 downto 0 => '0')) --negative saturation
            when ((acc(c_acc_w) = '1') AND (acc(c_acc_w-1 downto c_wreg_high) /= c_neg_one)) else
            acc(c_wreg_high downto c_wreg_low);


end rtl;
