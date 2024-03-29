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

i0_test_bench: entity work.top_tb(bench);

p_test_case: process
begin
    wait until rising_edge(bfm_handle_in.RDY);
    report "Filter ready, commence test!";

    
    run_test(pkg_handle, "LP_w03_o8", 4);
    -- set_op_init(pkg_handle, "cfg_w03_o8.txt");  
    -- set_op_test(pkg_handle, "test_vectors_w03_o8.txt");
    wait until pkg_handle.ready = '1';

    run_test(pkg_handle, "HP_w03_o8", 4);

    run_test(pkg_handle, "BP_w03_07_o8", 4);

    run_test(pkg_handle, "BS_w03_07_o8", 4);

    run_test(pkg_handle, "w07_o20", 10);
    wait;
end process;

end architecture;