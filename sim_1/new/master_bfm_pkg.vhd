library IEEE, work;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;
use std.textio.all;
use work.tuneFilter_pkg.all;
use work.handshake_pkg.all;
use work.filter_data_pkg.all;

package master_bfm_pkg is

    type t_bfm_handle is record
        RQ                  : STD_LOGIC;
        CFG                 : STD_LOGIC;
        master_out          : std_logic_vector(c_data_w-1 downto 0);
        waddr_coeff         : std_logic_vector(c_coeff_addr_w-1 downto 0);
    end record;

    type t_bfm_handle_in is record
        GNT                 : STD_LOGIC;
        RDY                 : STD_LOGIC;
        master_in           : std_logic_vector(c_data_w-1 downto 0);
    end record;

    function bfm_handle_init return t_bfm_handle;
    function bfm_handle_in_init return t_bfm_handle_in;

    function pad_string (arg : string) return string;

    signal bfm_handle    : t_bfm_handle := bfm_handle_init;
    signal bfm_handle_in : t_bfm_handle_in := bfm_handle_in_init;

    signal pkg_handle : t_pkg_handle := t_pkg_handle_init; -- used to pass data between package and bfm

    type t_op is (test, init);

    --BFM Command Type (Used for passing data between BFM and Package)
    type t_bfm_cmd is record
        op                       : t_op;
        test_vector              : t_test_vector;
        ref_vector               : t_test_vector;
        init_file                : string(1 to 50);
    end record;

    shared variable bfm_cmd : t_bfm_cmd;

    impure function get_bfm_cmd return t_bfm_cmd;


-------------------------------------------------------------------------------------------------
--BFM REQUESTS (USABLE IN TEST CASE)-------------------------------------------------------------
-------------------------------------------------------------------------------------------------  

    procedure set_op_init (
        signal handle       : inout t_pkg_handle;
        constant init_file  : string
    );

    procedure set_op_test (
        signal handle           : inout t_pkg_handle;
        constant test_vector    : t_test_vector
    );
        
        
-------------------------------------------------------------------------------------------------
--BFM INTERNAL PROCEDURES------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
    procedure memory_init (
        signal bfm_handle       : out t_bfm_handle;
        constant init_file      : in string        
    );

    procedure write_coeff (
        signal bfm_handle   : out t_bfm_handle;
        constant data   : std_logic_vector(c_data_w-1 downto 0);
        constant addr   : std_logic_vector(c_coeff_addr_w-1 downto 0)
    );

    procedure write_coeff (
        signal bfm_handle   : out t_bfm_handle;
        constant data   : bit_vector(c_data_w-1 downto 0);
        constant addr   : integer
    );

    procedure send_one_sample (
        signal bfm_handle   : out t_bfm_handle;
        signal bfm_handle_in    : in t_bfm_handle_in;
        constant data       : std_logic_vector(c_data_w-1 downto 0)
    );

    procedure run_test (
        signal bfm_handle       : out t_bfm_handle;
        signal bfm_handle_in    : in t_bfm_handle_in;
        constant test_vector    : t_test_vector;
        constant ref_vector     : t_test_vector
    );
        
end package;

package body master_bfm_pkg is
-------------------------------------------------------------------------------------------------
--BFM REQUESTS (USABLE IN TEST CASE)-------------------------------------------------------------
-------------------------------------------------------------------------------------------------
    procedure set_op_init (
        signal handle       : inout t_pkg_handle;
        constant init_file  : string
    ) is
    begin
        bfm_cmd.op := init;
        bfm_cmd.init_file := pad_string(init_file);
        bfm_send_request(handle);
    end procedure;

    procedure set_op_test ( --TODO
        signal handle           : inout t_pkg_handle;
        constant test_vector    : t_test_vector
    ) is
    begin
        bfm_cmd.op := test;
        bfm_cmd.test_vector := test_vector;
        bfm_send_request(handle);
    end procedure;
-------------------------------------------------------------------------------------------------
--BFM INTERNAL PROCEDURES------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

    procedure memory_init (
        signal bfm_handle   : out t_bfm_handle;
        constant init_file  : in string
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
                data,
                addr
            );
            addr := addr + 1;
        end loop;
        
        file_close(file_id);
        report("---> Done loading coefficients!");
    end procedure;

    procedure write_coeff (
        signal bfm_handle   : out t_bfm_handle;
        constant data       : std_logic_vector(c_data_w-1 downto 0);
        constant addr       : std_logic_vector(c_coeff_addr_w-1 downto 0)
    ) is
    begin
        report("---> writing coefficient " & integer'image(to_integer(unsigned(addr))) & " = " & integer'image(to_integer(signed(data))) &"!");
        bfm_handle.waddr_coeff <= addr;
        bfm_handle.master_out <= data;
        bfm_handle.CFG <= '1'; --write enable
        wait for clk_period;
        bfm_handle.CFG <= '0'; --pull down we

        wait for clk_period;
    end procedure;

    --procedure overloading for fun
    procedure write_coeff (
        signal bfm_handle   : out t_bfm_handle;
        constant data   : bit_vector(c_data_w-1 downto 0);
        constant addr   : integer
    ) is
    begin
        write_coeff(    -- this can be written directly into memory_init procedure
            bfm_handle,
            to_stdlogicvector(data),
            std_logic_vector(to_unsigned(addr, c_coeff_addr_w))
        );
    end procedure;

    procedure send_one_sample (
        signal bfm_handle       : out t_bfm_handle;
        signal bfm_handle_in    : in t_bfm_handle_in;
        constant data           : std_logic_vector(c_data_w-1 downto 0)
    ) is
    begin
            bfm_handle.master_out <= data;
            bfm_handle.RQ <= '1';
            wait until bfm_handle_in.GNT = '1'; --wait for confirmation
            bfm_handle.RQ <= '0';
    end procedure;

    -- procedure read_output (
    --     signal bfm_handle       : out t_bfm_handle;
    --     signal bfm_handle_in    : in t_bfm_handle_in;
    --     constant ref_vector     : t_test_vector
    -- ) is
    --     variable
    -- begin
    --     if (Is_X(output) OR abs(signed(output)  - signed(ref_vector(i))) > 15) then
    --     test_fail <= true;
    --     cnt_err <= cnt_err + 1;
    --     assert false 
    --         report "Error in output: Expected " 
    --         & to_hex(ref_vector(i))
    --         & " Actual "
    --         & to_hex(output)
    --         severity error;
    --     end if;
    -- end procedure;

    procedure run_test (
        signal bfm_handle       : out t_bfm_handle;
        signal bfm_handle_in    : in t_bfm_handle_in;
        constant test_vector    : t_test_vector;
        constant ref_vector     : t_test_vector
    ) is
        variable addr       : integer := 0;
        variable data       : std_logic_vector(c_data_w-1 downto 0);
        variable test_fail  : boolean := false;
        variable cnt_err    : integer := 0;
    begin
        report("---> TEST START");
        while addr <= c_len_test_vector-1 loop
            if bfm_handle_in.RDY = '1' then
                data := test_vector(addr);
                send_one_sample(bfm_handle, bfm_handle_in, data);
                wait until bfm_handle_in.RDY = '1';
                
                if (Is_X(bfm_handle_in.master_in)
                OR abs(signed(bfm_handle_in.master_in)  - signed(ref_vector(addr))) > 15) then
                    test_fail := true;
                    cnt_err := cnt_err + 1;
                    assert false 
                        report "Error in output: Expected " 
                        & to_hex(ref_vector(addr))
                        & " Actual "
                        & to_hex(bfm_handle_in.master_in)
                        severity error;
                end if;

                addr := addr + 1;
            else
                report("---> BFM NOT READY") severity error;
                wait until bfm_handle_in.RDY = '1';
            end if;
        end loop;
        if test_fail then
            report "**********TEST FAILED WITH " & integer'image(cnt_err) & " ERRORS!**********" severity error;
        else
            report "***************TEST SUCCESFUL!****************";
        end if;   
    end procedure;

-------------------------------------------------------------------------------------------------
--FUNCTIONS--------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
    impure function get_bfm_cmd return t_bfm_cmd is
    begin
        return bfm_cmd;
    end function;

    function bfm_handle_init return t_bfm_handle is   
        variable ret : t_bfm_handle;--t_pkg_handleArray(0 to size - 1);
     begin
        --for i in ret'range loop
           -- initialize control signals to 'Z' (overriden from BFM or test controller)
           -- the index is set only during initialization and remaind constant
           ret := (   
                RQ => 'Z',
                CFG => 'Z', 
                waddr_coeff => (others => 'Z'),
                master_out => (others => 'Z')
                      );
        --end loop;
        return ret;
    end function;

    function bfm_handle_in_init return t_bfm_handle_in is   
        variable ret : t_bfm_handle_in;--t_pkg_handleArray(0 to size - 1);
     begin
        --for i in ret'range loop
           -- initialize control signals to 'Z' (overriden from BFM or test controller)
           -- the index is set only during initialization and remaind constant
           ret := (   
                GNT => 'Z',
                RDY => 'Z',
                master_in => (others => 'Z')
                      );
        --end loop;
        return ret;
    end function;

    function pad_string (
        arg : string
    ) return string is
        variable ret_arg    : string(1 to 50);
    begin
        ret_arg := (others => ' ');
        ret_arg(arg'range) := arg;
        return ret_arg;
    end function;

end package body;