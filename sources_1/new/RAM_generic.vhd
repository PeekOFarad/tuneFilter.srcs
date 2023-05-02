library IEEE, work;
use IEEE.STD_LOGIC_1164.ALL;
use work.tuneFilter_pkg.all;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity g_ram is
    generic (
            c_addr_w   : integer;
            c_len_mem  : integer
    );
    Port (  clk     : in STD_LOGIC;
            we      : in STD_LOGIC;
            raddr   : in unsigned(c_addr_w-1 downto 0);
            waddr   : in unsigned(c_addr_w-1 downto 0);
            rdata   : out signed(c_data_w-1 downto 0);
            wdata   : in signed(c_data_w-1 downto 0)  
    );
end g_ram;

architecture rtl of g_ram is
-------------------------------------------------------------------------------------------------
--Types------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
type t_mem is array (0 to c_len_mem-1) of signed(c_data_w-1 downto 0);
-------------------------------------------------------------------------------------------------
--Signals----------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
signal mem : t_mem;
-------------------------------------------------------------------------------------------------
--Attributes-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-- attribute ram_style : string;
-- attribute ram_style of mem : signal is "block";
-------------------------------------------------------------------------------------------------
begin

--sample memory write
p_sample_memory: process (clk)
begin
    if rising_edge(clk) then
        if we = '1' then
            mem(to_integer(waddr)) <= wdata; --write
        end if;
        rdata <= mem(to_integer(raddr)); --read
    end if;
end process;

end rtl;
