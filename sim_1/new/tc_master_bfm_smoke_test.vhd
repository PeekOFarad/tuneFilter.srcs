library IEEE, work;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;
use work.tuneFilter_pkg.all;
use work.master_bfm_pkg.all;
use std.textio.all;

entity tc_master_bfm_smoke_test is
end entity;

architecture behavioral of tc_master_bfm_smoke_test is

begin

i0_test_bench: entity work.top_tb(bench)
    generic map (
        g_STC => false
    );

p_test_case: process
begin
    wait until bfm_handle_in.RDY = '1';
    report "Filter ready, commence test!";
    
    set_op_init(pkg_handle, "cfg2.txt");  

    set_op_test(pkg_handle, "test_vectors2.txt");

    wait;
end process;

end architecture;