library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;
use work.tuneFilter_pkg.all;
use work.filter_data_pkg.all;

entity control_tb is
end;

architecture bench of control_tb is

  component top
      Port (  clk, rst, RQ, CFG : in STD_LOGIC;
              input             : in std_logic_vector(c_data_w-1 downto 0);
              GNT, RDY          : out STD_LOGIC;
              output            : out std_logic_vector(c_data_w-1 downto 0));
  end component;

  signal clk, rst, RQ, CFG : STD_LOGIC;
  signal input : std_logic_vector(c_data_w-1 downto 0);
  signal GNT, RDY : STD_LOGIC;
  signal output : std_logic_vector(c_data_w-1 downto 0);

  constant clock_period: time := 10 ns;
  signal stop_the_clock: boolean;

  signal test_fail : boolean;
  signal cnt_err : integer;--unsigned(c_len_cnt_err-1 downto 0);
  signal data_expeced_log : std_logic_vector(c_data_w-1 downto 0);
  constant c_coeff_mem_init : t_coeff_mem := (
  "0001000110101011",  "0001000010101111",  "0001010111111100",  "0100000000000000",  "0010000000000000", "0000000000000000", "0000000000000000", "0000000000000000",
  "0000110110110100",  "0000110011110001",  "0000100111100000",  "0100000000000000",  "0010000000000000", "0000000000000000", "0000000000000000", "0000000000000000",
  "0000101110110010",  "0000101100001011",  "0000001110111101",  "0100000000000000",  "0010000000000000", "0000000000000000", "0000000000000000", "0000000000000000",
  "0000101011010110",  "0000101000111100",  "0000000100011101",  "0100000000000000",  "0010000000000000", "0000000000000000", "0000000000000000", "0000000000000000"
  );



begin

  uut: top port map ( clk    => clk,
                          rst    => rst,
                          RQ     => RQ,
                          CFG    => CFG,
                          input  => input,
                          GNT    => GNT,
                          RDY    => RDY,
                          output => output );

  stimulus: process
  begin
  
    -- Put initialisation code here
    test_fail <= false;
    cnt_err <= 0; 
    data_expeced_log <= (others => '0');
    RQ     <= '0';
    CFG    <= '1';
    input  <= (others => '0');
    rst <= '1';
    wait for 5 ns;
    rst <= '0';
    wait for 5 ns;

    -- Put test bench stimulus code here
---------------------------------------------------------------------------------------------------------
--MEMORY INIT---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
    wait until clk = '1';
    report "loading coefficients";
    CFG <= '1';
    wait for clock_period;
    CFG <= '0';
    for j in 0 to c_len_coeff_mem-1 loop
      input <= std_logic_vector(c_coeff_mem_init(j));
      wait on clk until clk = '1';
    end loop;
    input <= (others => '0');
    report "loading coefficients (DONE)";
    wait for clock_period * 5;
---------------------------------------------------------------------------------------------------------
--TEST START---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
    report "test start";
    for i in 0 to c_len_filter_data loop
      input <= filter_in_data(i);
      RQ <= '1';
      wait on GNT; --sample recieved
      RQ <= '0';
      wait on RDY;
      data_expeced_log <= filter_out_expected(i); --expected data waveform
      --compare output to expected
      if (Is_X(output) OR abs(signed(output)  - signed(filter_out_expected(i))) > 15) then
        test_fail <= true;
        cnt_err <= cnt_err + 1;
        assert false 
            report "Error in output: Expected " 
            & to_hex(filter_out_expected(i))
            & " Actual "
            & to_hex(output)
            severity error;
      end if;
    end loop;
    
    data_expeced_log <= (others => '0');
    --report test result
    if test_fail then
      report "**********TEST FAILED WITH " & integer'image(cnt_err) & " ERRORS!**********" severity error;
    else
      report "***************TEST SUCCESFUL!****************";
    end if;
    -------------
    wait for clock_period*5; 
    stop_the_clock <= true;
    wait;
  end process;

  clocking: process
  begin
    while not stop_the_clock loop
      clk <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;

end;
