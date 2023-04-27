library IEEE, work;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;
use work.tuneFilter_pkg.all;
use work.filter_data_pkg.all;
use work.master_bfm_pkg.all;
use work.handshake_pkg.all;
use std.textio.all;

entity master_bfm is
    port (
        clk                 : in std_logic;
        rst                 : in std_logic;

        --link signals
        GNT                 : in STD_LOGIC;
        RDY                 : in STD_LOGIC;
        master_in           : in std_logic_vector(c_data_w-1 downto 0);
        RQ                  : out STD_LOGIC;
        CFG                 : out STD_LOGIC;
        waddr_coeff         : out std_logic_vector(c_coeff_addr_w-1 downto 0);
        master_out          : out std_logic_vector(c_data_w-1 downto 0)
    );
end entity; 

architecture behavioral of master_bfm is

signal send_data_req    : boolean := false;
signal send_data_ack    : boolean := false;
signal sample_data      : std_logic_vector(c_data_w-1 downto 0);

begin
    --in
    bfm_handle_in.GNT <= GNT;
    bfm_handle_in.RDY <= RDY;
    bfm_handle_in.master_in <= master_in;
    --out
    RQ <= bfm_handle.RQ;
    CFG <= bfm_handle.CFG;
    master_out <= bfm_handle.master_out;
    waddr_coeff <= bfm_handle.waddr_coeff;
   

-------------------------------------------------------------------------------------------------
--COMMAND PROCESS--------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------    
p_cmd: process
    variable cmd : t_bfm_cmd;
begin

    pkg_handle.ack <= '0';
    report "BFM initialized";
    wait for 0 ns; --wait for delta cycle -> TODO: find out what the biscuit is a delta cycle
                                        -- ANSWER:everything above happens "in parallel"?

    loop
        --THIS RUNS IN PARALLEL
        bfm_wait_for_request(pkg_handle);
        cmd := get_bfm_cmd;
        bfm_ack_request(pkg_handle);
        ------------------------------
        wait for 0 ns;

        case cmd.op is
            when test =>
                report("---> Running test...");
                run_test(bfm_handle, bfm_handle_in, cmd.test_vector, cmd.ref_vector);

            when init =>
                report("---> Writing coefficients...");
                memory_init(bfm_handle, cmd.init_file);
                
            when others =>
                null;
        end case;
    end loop;


end process;

end architecture;