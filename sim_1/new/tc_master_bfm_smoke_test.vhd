library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;
use work.tuneFilter_pkg.all;
use work.filter_data_pkg.all;
use work.master_bfm_pkg.all;
use std.textio.all;

entity tc_master_bfm_smoke_test is
end entity;

architecture behavioral of tc_master_bfm_smoke_test is

signal stop_the_clock : boolean := false;

begin

i0_test_bench: entity work.control_tb(bench)
    generic map (
        g_STC => stop_the_clock
    );

p_test_case: process
begin
    wait for 10 ns;
    report("Hello world!");
    wait until bfm_handle.RDY = '1';
    report "Filter ready, commence test!";
    
    mem_init(pkg_handle);
    wait for 10*clk_period;
    report("Bye Bye world!");
    stop_the_clock <= true;
    wait;
end process;

end architecture;