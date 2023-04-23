library IEEE;
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

begin
    --in
    bfm_handle.GNT <= GNT;
    bfm_handle.RDY <= RDY;
    bfm_handle.master_in <= master_in;
    --out
    RQ <= bfm_handle.RQ;
    CFG <= bfm_handle.CFG;
    master_out <= bfm_handle.master_out;
    waddr_coeff <= bfm_handle.waddr_coeff;
   

-------------------------------------------------------------------------------------------------
--COMMAND PROCESS--------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------    
p_cmd: process
    variable op : t_op;
begin

    -- RQ <= '0';
    -- CFG <= '0'; 
    -- waddr_coeff <= (others => '0');
    -- master_out <= (others => '0');
    
    pkg_handle.ack <= '0';
    report "BFM initialized";
    wait for 0 ns; --wait for delta cycle -> TODO: find out what the biscuit is a delta cycle

    loop

        bfm_wait_for_request(pkg_handle);
        op := get_bfm_op;
        bfm_ack_request(pkg_handle);
        wait for 0 ns;

        case op is
            when send_data =>
                null;

            when load_coeff =>
                report("--->Writing coefficients...");
                memory_init("cfg1.txt", bfm_handle);
                wait for clk_period;

            when monitor_slave_output =>
                null;
                
            when others =>
                null;
        end case;
    end loop;


end process;
-------------------------------------------------------------------------------------------------
--SEND DATA--------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------
--SLAVE MONITOR----------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

end architecture;