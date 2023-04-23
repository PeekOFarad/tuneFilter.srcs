-- vsg_off
library IEEE;
use IEEE.STD_LOGIC_1164.all;
USE ieee.numeric_std.ALL;
use IEEE.math_real.all;

package tuneFilter_pkg is
--constants
constant c_f_order : integer := 8; --filter order
constant c_s_order : integer := 2; --section order
constant c_data_w : integer := 16; --data width
constant c_acc_w : integer := c_data_w*2+2; --accummulator width, default = 34
constant c_mul_w : integer := c_data_w*2; --multiplier width, default = 32
constant c_len_data_frac : integer := 13; --coefficient fractional part length
constant c_len_coeff_frac : integer := 13; --coefficient fractional part length
constant c_len_acc_frac : integer := 26; --accummulator fractional part length
constant c_len_mul_frac : integer := 26; --accummulator fractional part length
constant c_len_mul_int : integer := c_mul_w-c_len_mul_frac; -- =6
constant c_wreg_high : integer := c_acc_w-(c_len_mul_int); -- 34-(32-26)=28, 
constant c_wreg_low : integer := c_wreg_high-(c_data_w-1); -- =13
constant c_neg_one : signed(c_len_mul_int-1 downto 0) 
                    :=  to_signed(-1,c_len_mul_int);
constant c_len_cnt_coeff : integer := integer(ceil(log2(real(2*c_s_order+1)))); 
-- =3; find nearest power of 2 larger than the number of coefficients
constant c_len_cnt_sample : integer := integer(ceil(log2(real(c_S_Order+1))));
-- =2; find nearest power of 2 larger than the number of delay elements in a section
constant c_len_cnt_section : integer := integer(ceil(log2(real(c_f_order/c_s_order))));
--=2; finde the nearest power of 2 larger than the number of sections
constant c_coeff_addr_w : integer := c_len_cnt_section+c_len_cnt_coeff;
constant c_sample_addr_w : integer := c_len_cnt_section+c_len_cnt_sample;
constant c_len_sample_mem : integer := c_F_Order/c_s_order * 2**c_len_cnt_sample;
--sample memory size
constant c_len_coeff_mem : integer := c_f_order/c_s_order * 2**c_len_cnt_coeff;
-- =32; coefficient memory size = number of sections * coeff. memory alocated for one section
constant c_len_cnt_init : integer := integer(ceil(log2(real(c_len_coeff_mem))));

constant clk_period: time := 10 ns;

--types
type t_sample_mem is array (0 to c_len_sample_mem-1) of signed(c_data_w-1 downto 0); --sram
type t_coeff_mem is array (0 to c_len_coeff_mem-1) of signed(c_data_w-1 downto 0);
    --coefficient memory

--functions
FUNCTION to_hex( x : IN std_logic) RETURN string;
FUNCTION to_hex( x : IN std_logic_vector) RETURN string;
FUNCTION to_hex( x : IN signed ) RETURN string;
FUNCTION to_hex( x : IN unsigned ) RETURN string;
FUNCTION to_hex( x : IN real ) RETURN string;

end package tuneFilter_pkg;

package body tuneFilter_pkg is
FUNCTION to_hex( x : IN std_logic_vector) RETURN string IS
    VARIABLE result  : STRING(1 TO 256); -- 1024 bits max
    VARIABLE i       : INTEGER;
    VARIABLE imod    : INTEGER;
    VARIABLE j       : INTEGER;
    VARIABLE jinc    : INTEGER;
    VARIABLE newx    : std_logic_vector(1023 DOWNTO 0);
BEGIN
    newx := (OTHERS => '0');
    IF x'LEFT > x'RIGHT THEN
      j := x'LENGTH-1;
      jinc := -1;
    ELSE
      j := 0;
      jinc := 1;
    END IF;
    FOR i IN x'RANGE LOOP
      newx(j) := x(i);
      j := j+jinc;
    END LOOP;  -- i
    i := x'LENGTH-1;
    imod := x'LENGTH MOD 4;
    IF    imod = 1 THEN i := i+3;
    ELSIF imod = 2 THEN i := i+2;
    ELSIF imod = 3 THEN i := i+1;
    END IF;
    j := 1;
    WHILE i >= 3 LOOP
      IF    newx(i DOWNTO (i-3)) = "0000" THEN result(j) := '0';
      ELSIF newx(i DOWNTO (i-3)) = "0001" THEN result(j) := '1';
      ELSIF newx(i DOWNTO (i-3)) = "0010" THEN result(j) := '2';
      ELSIF newx(i DOWNTO (i-3)) = "0011" THEN result(j) := '3';
      ELSIF newx(i DOWNTO (i-3)) = "0100" THEN result(j) := '4';
      ELSIF newx(i DOWNTO (i-3)) = "0101" THEN result(j) := '5';
      ELSIF newx(i DOWNTO (i-3)) = "0110" THEN result(j) := '6';
      ELSIF newx(i DOWNTO (i-3)) = "0111" THEN result(j) := '7';
      ELSIF newx(i DOWNTO (i-3)) = "1000" THEN result(j) := '8';
      ELSIF newx(i DOWNTO (i-3)) = "1001" THEN result(j) := '9';
      ELSIF newx(i DOWNTO (i-3)) = "1010" THEN result(j) := 'A';
      ELSIF newx(i DOWNTO (i-3)) = "1011" THEN result(j) := 'B';
      ELSIF newx(i DOWNTO (i-3)) = "1100" THEN result(j) := 'C';
      ELSIF newx(i DOWNTO (i-3)) = "1101" THEN result(j) := 'D';
      ELSIF newx(i DOWNTO (i-3)) = "1110" THEN result(j) := 'E';
      ELSIF newx(i DOWNTO (i-3)) = "1111" THEN result(j) := 'F';
      ELSE result(j) := 'X';
      END IF;
      i := i-4;
      j := j+1;
    END LOOP;
    RETURN result(1 TO j-1);
  END;

  FUNCTION to_hex( x : IN std_logic ) RETURN string IS
  BEGIN
    RETURN std_logic'image(x);
  END;

  FUNCTION to_hex( x : IN signed ) RETURN string IS
  BEGIN
    RETURN to_hex( std_logic_vector(x) );
  END;

  FUNCTION to_hex( x : IN unsigned ) RETURN string IS
  BEGIN
    RETURN to_hex( std_logic_vector(x) );
  END;

  FUNCTION to_hex( x : IN real ) RETURN string IS
  BEGIN
    RETURN real'image(x);
  END;

end package body tuneFilter_pkg;
