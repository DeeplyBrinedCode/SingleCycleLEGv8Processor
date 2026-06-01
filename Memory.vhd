--------------------------------------------------------------------------------
-- REFACTORED SINGLE BIT STORAGE (Fully Synchronous)
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
	 signal highz : std_logic_vector(31 downto 0) := (others => 'Z') ;
begin 

    -- Safely convert the 30-bit vector to an integer
    addr_int <= to_integer(unsigned(Address)); 

    ------------------------------------------------------------ 
    -- WRITE & RESET PROCESS (Synchronous Logic) 
    ------------------------------------------------------------ 
    WriteProc : process(Clock, Reset) 
    begin 
        if (Reset = '1') then 
            for i in 0 to 127 loop 
                i_ram(i) <= X"00000000"; 
            end loop; 
        elsif falling_edge(Clock) then 
            if (WE = '1') then 
                -- Safeguard against array index out-of-bounds errors during simulation
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
        -- Drive DataOut only if Output Enable is active and index is valid
        if (OE = '0' and addr_int <= 127) then 
            DataOut <= i_ram(addr_int); 
        else 
            DataOut <= highz; 
        end if; 
    end process ReadProc; 

end architecture staticRAM;

--------------------------------------------------------------------------------
-- REGISTER BANK
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;
entity Registers is
Port(
ReadReg1 : in std_logic_vector(4 downto 0);
ReadReg2 : in std_logic_vector(4 downto 0);
WriteReg : in std_logic_vector(4 downto 0);
WriteData : in std_logic_vector(31 downto 0);
WriteCmd : in std_logic;
ReadData1 : out std_logic_vector(31 downto 0);
ReadData2 : out std_logic_vector(31 downto 0)
);
end entity Registers;
architecture remember of Registers is
component register32
port(
datain : in std_logic_vector(31 downto 0);
enout32 : in std_logic;
enout16 : in std_logic;
enout8 : in std_logic;
writein32 : in std_logic;
writein16 : in std_logic;
writein8 : in std_logic;
dataout : out std_logic_vector(31 downto 0)
);
end component;
----------------------------------------------------------------
-- SIGNALS
----------------------------------------------------------------
signal enable : std_logic;
-- XZR REGISTER (constant zero register)
signal XZRReg : std_logic_vector(31 downto 0);
signal XZROut : std_logic_vector(31 downto 0);
signal XZRWrite : std_logic;
-- WRITE ENABLES
signal x0_write, x1_write, x2_write, x3_write : std_logic;
signal x4_write, x5_write, x6_write, x7_write : std_logic;
-- REGISTER OUTPUTS
signal x0_out, x1_out, x2_out, x3_out : std_logic_vector(31 downto 0);
signal x4_out, x5_out, x6_out, x7_out : std_logic_vector(31 downto 0);
signal Fail_read : std_logic_vector(31 downto 0);
begin
----------------------------------------------------------------
-- INITIALIZATION
----------------------------------------------------------------
enable <= '0';
XZRReg <= X"00000000";
XZRWrite <= '1';
Fail_read <= (others => 'Z');
----------------------------------------------------------------
-- WRITE DECODER
----------------------------------------------------------------
x0_write <= '1' when ((WriteCmd = '1') and (WriteReg = "00000")) else '0';
x1_write <= '1' when ((WriteCmd = '1') and (WriteReg = "00001")) else '0';
x2_write <= '1' when ((WriteCmd = '1') and (WriteReg = "00010")) else '0';
x3_write <= '1' when ((WriteCmd = '1') and (WriteReg = "00011")) else '0';
x4_write <= '1' when ((WriteCmd = '1') and (WriteReg = "00100")) else '0';
x5_write <= '1' when ((WriteCmd = '1') and (WriteReg = "00101")) else '0';
x6_write <= '1' when ((WriteCmd = '1') and (WriteReg = "00110")) else '0';
x7_write <= '1' when ((WriteCmd = '1') and (WriteReg = "00111")) else '0';
----------------------------------------------------------------
-- REGISTER INSTANTIATION
----------------------------------------------------------------
-- XZR REGISTER
XZR : register32 port map(
XZRReg,
enable,
enable,
enable,
XZRWrite,
XZRWrite,
XZRWrite,
XZROut
);
-- GENERAL PURPOSE REGISTERS
X0 : register32 port map(
WriteData,
enable,
enable,
enable,
x0_write,
x0_write,
x0_write,
x0_out
);
X1 : register32 port map(
WriteData,
enable,
enable,
enable,
x1_write,
x1_write,
x1_write,
x1_out
);
X2 : register32 port map(
WriteData,
enable,
enable,
enable,
x2_write,
x2_write,
x2_write,
x2_out
);
X3 : register32 port map(
WriteData,
enable,
enable,
enable,
x3_write,
x3_write,
x3_write,
x3_out
);
X4 : register32 port map(
WriteData,
enable,
enable,
enable,
x4_write,
x4_write,
x4_write,
x4_out
);
X5 : register32 port map(
WriteData,
enable,
enable,
enable,
x5_write,
x5_write,
x5_write,
x5_out
);
X6 : register32 port map(
WriteData,
enable,
enable,
enable,
x6_write,
x6_write,
x6_write,
x6_out
);
X7 : register32 port map(
WriteData,
enable,
enable,
enable,
x7_write,
x7_write,
x7_write,
x7_out
);
----------------------------------------------------------------
-- READ PORT 1
----------------------------------------------------------------
with ReadReg1 select
ReadData1 <=
x0_out when "00000",
x1_out when "00001",
x2_out when "00010",
x3_out when "00011",
x4_out when "00100",
x5_out when "00101",
x6_out when "00110",
x7_out when "00111",
XZROut when "11111",
Fail_read when others;
----------------------------------------------------------------
-- READ PORT 2
----------------------------------------------------------------
with ReadReg2 select
ReadData2 <=
x0_out when "00000",
x1_out when "00001",
x2_out when "00010",
x3_out when "00011",
x4_out when "00100",
x5_out when "00101",
x6_out when "00110",
x7_out when "00111",
XZROut when "11111",
Fail_read when others;
end architecture remember;
--------------------------------------------------------------------------------
-- SINGLE BIT STORAGE
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;
entity bitstorage is
port(
bitin : in std_logic;
enout : in std_logic;
writein : in std_logic;
bitout : out std_logic
);
end entity bitstorage;
architecture memlike of bitstorage is
signal q : std_logic := '0';
begin
process(writein)
begin
if rising_edge(writein) then
q <= bitin;
end if;
end process;
bitout <= q when enout = '0' else 'Z';
end architecture memlike;
--------------------------------------------------------------------------------
-- 8-BIT REGISTER
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;
entity register8 is
port(
datain : in std_logic_vector(7 downto 0);
enout : in std_logic;
writein : in std_logic;
dataout : out std_logic_vector(7 downto 0)
);
end entity register8;
architecture memmy of register8 is
component bitstorage
port(
bitin : in std_logic;
enout : in std_logic;
writein : in std_logic;
bitout : out std_logic
);
end component;
begin
m0 : bitstorage port map(datain(0), enout, writein, dataout(0));
m1 : bitstorage port map(datain(1), enout, writein, dataout(1));
m2 : bitstorage port map(datain(2), enout, writein, dataout(2));
m3 : bitstorage port map(datain(3), enout, writein, dataout(3));
m4 : bitstorage port map(datain(4), enout, writein, dataout(4));
m5 : bitstorage port map(datain(5), enout, writein, dataout(5));
m6 : bitstorage port map(datain(6), enout, writein, dataout(6));
m7 : bitstorage port map(datain(7), enout, writein, dataout(7));
end architecture memmy;
--------------------------------------------------------------------------------
-- 32-BIT REGISTER
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;
entity register32 is
port(
datain : in std_logic_vector(31 downto 0);
enout32 : in std_logic;
enout16 : in std_logic;
enout8 : in std_logic;
writein32 : in std_logic;
writein16 : in std_logic;
writein8 : in std_logic;
dataout : out std_logic_vector(31 downto 0)
);
end entity register32;
architecture biggermem of register32 is
signal w32, w16, w8 : std_logic := '0';
signal out32, out16, out8 : std_logic := '1';
component register8
port(
datain : in std_logic_vector(7 downto 0);
enout : in std_logic;
writein : in std_logic;
dataout : out std_logic_vector(7 downto 0)
);
end component;
begin
w8 <= writein8 OR writein16 OR writein32;
w16 <= writein16 OR writein32;
w32 <= writein32;
out8 <= enout8 AND enout16 AND enout32;
out16 <= enout16 AND enout32;
out32 <= enout32;
m0 : register8 port map(
datain(7 downto 0),
out8,
w8,
dataout(7 downto 0)
);
m1 : register8 port map(
datain(15 downto 8),
out16,
w16,
dataout(15 downto 8)
);
m2 : register8 port map(
datain(23 downto 16),
out32,
w32,
dataout(23 downto 16)
);
m3 : register8 port map(
datain(31 downto 24),
out32,
w32,
dataout(31 downto 24)
);
end architecture biggermem;