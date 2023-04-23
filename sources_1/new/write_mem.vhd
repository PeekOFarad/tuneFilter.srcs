--------------------------------
procedure write_mem(constant addr   : in  natural;
                    constant data   : in  integer;
                    signal   we     : out std_logic
                    signal   wd     : in  std_logic;
                    signal   waddr  : out t_MC_MEM_ADDR;
                    signal   wdata  : out t_MC_DATA) is
begin
    we    <= '1';
    waddr <= to_unsigned(addr, c_MC_MEM_ADDR_W);
    wdata <= to_signed  (data, c_MC_DATA_W);
    wait until wd = '1';
    wait for tm_CLK_PER;
    we    <= '0';
    wait until wd = '0';
    wait for tm_CLK_PER;
end procedure;
--------------------------------
procedure write_conf(constant fname  : in string;
                     signal   we     : out std_logic;
                     signal   wd     : in std_logic;
                     signal   waddr  : out t_MC_MEM_ADDR;
                     signal   wdata  : out t_MC_DATA) is
    file ref_f              : text open read_mode is fname;
    variable ref_l          : line;
    variable reg_addr       : integer := 0;
    variable reg_val        : integer;
    variable read_ok        : boolean;
begin
    report("<--- Loading configuration from: " & fname) severity note;
    while not endfile(ref_f) loop
        readline(ref_f, ref_l);

        read(ref_l, reg_val,  read_ok);

        write_mem(reg_addr, reg_val, we, wd, waddr, wdata);

        reg_addr := reg_addr + 1;

    end loop;
    report("---> Configuration Loaded") severity note;
    
end procedure;