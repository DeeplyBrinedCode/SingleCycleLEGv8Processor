--------------------------------------------------------------------------------
-- REFACTORED RAM STORAGE (Fully Synchronous Write/Reset, Async Read)
--------------------------------------------------------------------------------
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all; 

entity Memory is 
    port( 
        Reset    : in std_logic; 
        Clock    : in std_logic; 
        OE       : in std_logic; 
        WE       : in std_logic; 
        Address  : in std_logic_vector(29 downto 0); 
        DataIn   : in std_logic_vector(31 downto 0); 
        DataOut  : out std_logic_vector(31 downto 0) 
    ); 
end entity Memory; 

architecture staticRAM of Memory is 
    type ram_type is array (0 to 127) of std_logic_vector(31 downto 0); 
    signal i_ram    : ram_type; 
    signal addr_int : integer range 0 to 1073741823; 
    constant HIGHZ  : std_logic_vector(31 downto 0) := (others => 'Z'); 
begin 

    -- Safely convert the 30-bit vector to an integer
    addr_int <= to_integer(unsigned(Address)); 

    ------------------------------------------------------------ 
    -- WRITE & RESET PROCESS (Synchronous Logic) 
    ------------------------------------------------------------ 
    WriteProc : process(Clock) 
    begin 
        if falling_edge(Clock) then 
            if (Reset = '1') then 
                for i in 0 to 127 loop 
                    i_ram(i) <= X"00000000"; 
                end loop; 
            elsif (WE = '1') then 
                -- Safeguard against array index out-of-bounds errors
                if (addr_int <= 127) then 
                    i_ram(addr_int) <= DataIn; 
                end if; 
            end if; 
        end if; 
    end process WriteProc; 

    ------------------------------------------------------------ 
    -- READ PROCESS (Asynchronous/Combinational Logic) 
    ------------------------------------------------------------ 
    ReadProc : process(OE, addr_int, i_ram) 
    begin 
        -- Drive DataOut only if Output Enable is active (Assumed Active Low '0' per your code)
        if (OE = '0' and addr_int <= 127) then 
            DataOut <= i_ram(addr_int); 
        else 
            DataOut <= HIGHZ; 
        end if; 
    end process ReadProc; 

end architecture staticRAM;
