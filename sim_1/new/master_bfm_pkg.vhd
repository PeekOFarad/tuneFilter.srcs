library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;
use std.textio.all;
use work.tuneFilter_pkg.all;
use work.handshake_pkg.all;

package master_bfm_pkg is

    type t_bfm_handle is record
        RQ                  : STD_LOGIC;
        CFG                 : STD_LOGIC;
        GNT                 : STD_LOGIC;
        RDY                 : STD_LOGIC;
        master_out          : std_logic_vector(c_data_w-1 downto 0);
        waddr_coeff         : std_logic_vector(c_coeff_addr_w-1 downto 0);
        master_in           : std_logic_vector(c_data_w-1 downto 0);
    end record;

    function t_bfm_handle_init return t_bfm_handle;

    signal bfm_handle : t_bfm_handle := t_bfm_handle_init;

    signal pkg_handle : t_pkg_handle := t_pkg_handle_init; -- used to pass data between package and bfm

    type t_op is (send_data, load_coeff, monitor_slave_output);

    shared variable bfm_op : t_op;


    

    impure function get_bfm_op return t_op;

    -- BFM Command Type (Used for passing data between BFM and Package)
    -- type t_bfm_cmd is record
    --     op                       : t_op_type;
    --     received_data            : std_logic_vector(c_data_w-1 downto 0);
    --     data                     : std_logic_vector(c_data_w-1 downto 0);
    --     waddr                    : std_logic_vector(c_coeff_addr_w-1 downto 0);
    -- end record;

    procedure mem_init (
        signal handle   : inout t_pkg_handle
    );
        

    procedure memory_init (
        constant init_file  : in string;
        signal bfm_handle       : inout t_bfm_handle        
    );

    procedure write_coeff (
        signal bfm_handle   : inout t_bfm_handle;
        constant data   : std_logic_vector(c_data_w-1 downto 0);
        constant addr   : std_logic_vector(c_coeff_addr_w-1 downto 0)
    );

    -- procedure write_coeff (
    --     signal bfm_handle   : inout t_bfm_handle;
    --     constant data   : bit_vector(c_data_w-1 downto 0);
    --     constant addr   : integer
    -- );

        
end package;

package body master_bfm_pkg is
-------------------------------------------------------------------------------------------------
--PROCEDURES------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

    procedure memory_init (
        constant init_file  : in string;
        signal bfm_handle   : inout t_bfm_handle
    ) is
        file file_id        : text open read_mode is (
                                        "../../../../tuneFilter.srcs/sim_1/new/" & init_file
                                        );
    --relative path to simulation sources folder, where matlab scrip convertCoeff.m is located
        variable line_id    : line;
        variable addr       : integer := 0;
        variable data       : bit_vector(c_data_w-1 downto 0);
    begin
        report("---> Loading coefficients from: " & init_file);
        while not endfile(file_id) loop
            readline(file_id, line_id);
            read(line_id, data);
            write_coeff(
                bfm_handle,
                to_stdlogicvector(data),
                std_logic_vector(to_unsigned(addr, c_coeff_addr_w))
            );
            addr := addr + 1;
        end loop;
        
        file_close(file_id);
        report("---> Done loading coefficients!");
    end procedure;

    procedure write_coeff (
        signal bfm_handle   : inout t_bfm_handle;
        constant data       : std_logic_vector(c_data_w-1 downto 0);
        constant addr       : std_logic_vector(c_coeff_addr_w-1 downto 0)
    ) is
    begin
        report("---> writing coefficient " & integer'image(to_integer(unsigned(addr))) & "!");
        bfm_handle.waddr_coeff <= addr;
        bfm_handle.master_out <= data;
        bfm_handle.CFG <= '1'; --write enable
        --wait until bfm_handle.GNT = '1'; --wait for confirmation
        wait for clk_period;
        bfm_handle.CFG <= '0'; --pull down we
        --wait until bfm_handle.GNT = '0'; --wait for return to idle 
        --> fsm stuck here, GNT not droping, decided to not use GNT confirmation
        wait for clk_period;
    end procedure;

    --procedure overloading for fun
    -- procedure write_coeff (
    --     signal bfm_handle   : inout t_bfm_handle;
    --     constant data   : bit_vector(c_data_w-1 downto 0);
    --     constant addr   : integer
    -- ) is
    -- begin
    --     write_coeff(    -- this can be written directly into memory_init procedure
            -- bfm_handle,
            -- to_stdlogicvector(data),
            -- std_logic_vector(to_unsigned(addr, c_coeff_addr_w))
    --     );
    -- end procedure;

    procedure mem_init (
        signal handle   : inout t_pkg_handle
    ) is
    begin
        bfm_op := load_coeff;
        bfm_send_request(handle);
    end procedure;
-------------------------------------------------------------------------------------------------
--FUNCTIONS--------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
    impure function get_bfm_op return t_op is
    begin
        return bfm_op;
    end function;

    function t_bfm_handle_init return t_bfm_handle is   
        variable ret : t_bfm_handle;--t_pkg_handleArray(0 to size - 1);
     begin
        --for i in ret'range loop
           -- initialize control signals to 'Z' (overriden from BFM or test controller)
           -- the index is set only during initialization and remaind constant
           ret := (   
                GNT => 'Z',
                RDY => 'Z',
                master_in => (others => 'Z'),
                RQ => 'Z',
                CFG => 'Z', 
                waddr_coeff => (others => 'Z'),
                master_out => (others => 'Z')
                      );
        --end loop;
        return ret;
    end function;

end package body;