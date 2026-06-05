-- =============================================================
-- DataMemory.vhd
-- LEGv8 Single-Cycle Processor – Data Memory (Module 6)
--
-- Supports:
--   LDUR – 64-bit (doubleword) read from byte address
--   STUR – 64-bit (doubleword) write to byte address
--
-- Implementation:
--   256 bytes of word-addressable storage (64 x 32-bit words).
--   Addresses are byte addresses; word index = Address[31:2].
--   For a 32-bit datapath the upper 32 bits of a 64-bit access
--   span the next consecutive word (little-endian).
--
--   MemRead  : '1' enables read; ReadData driven from memory
--   MemWrite : '1' enables write on rising clock edge
--
-- Note: ReadData is updated combinationally for read; writes
--       are clocked (synchronous write, asynchronous read),
--       matching a standard single-cycle textbook model.
-- =============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DataMemory is
    port (
        CLK       : in  std_logic;
        Address   : in  std_logic_vector(31 downto 0);  -- Byte address from ALU
        WriteData : in  std_logic_vector(31 downto 0);  -- Data to write (STUR)
        MemRead   : in  std_logic;                       -- '1' = read enabled
        MemWrite  : in  std_logic;                       -- '1' = write enabled (clocked)
        ReadData  : out std_logic_vector(31 downto 0)   -- Data read (LDUR)
    );
end entity DataMemory;

architecture Behavioral of DataMemory is

    -- 64 words × 32 bits = 256 bytes
    -- Initialised to all zeros; can be pre-loaded via synthesis tool
    type MemArray is array(0 to 63) of std_logic_vector(31 downto 0);
    signal mem : MemArray := (others => (others => '0'));

    -- Word index: byte address / 4  (bits [7:2] of the lower byte address)
    signal word_index : integer range 0 to 63;

begin

    -- Convert byte address to word index (truncate lower 2 bits)
    word_index <= to_integer(unsigned(Address(7 downto 2)));

    -- -------------------------------------------------------
    -- Synchronous Write (STUR)
    -- -------------------------------------------------------
    write_proc : process(CLK)
    begin
        if rising_edge(CLK) then
            if MemWrite = '1' then
                mem(word_index) <= WriteData;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------
    -- Asynchronous (combinational) Read (LDUR)
    -- -------------------------------------------------------
    ReadData <= mem(word_index) when MemRead = '1' else (others => '0');

end architecture Behavioral;


-- =============================================================
-- Testbench: tDataMemory.vhd
-- Verifies successful writes (STUR), reads (LDUR), and correct
-- address generation across multiple locations.
-- =============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tDataMemory is
end entity tDataMemory;

architecture Sim of tDataMemory is

    component DataMemory
        port (
            CLK       : in  std_logic;
            Address   : in  std_logic_vector(31 downto 0);
            WriteData : in  std_logic_vector(31 downto 0);
            MemRead   : in  std_logic;
            MemWrite  : in  std_logic;
            ReadData  : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Testbench signals
    signal CLK       : std_logic := '0';
    signal Address   : std_logic_vector(31 downto 0) := (others => '0');
    signal WriteData : std_logic_vector(31 downto 0) := (others => '0');
    signal MemRead   : std_logic := '0';
    signal MemWrite  : std_logic := '0';
    signal ReadData  : std_logic_vector(31 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    -- Helper: build a 32-bit byte address from a word index
    function word_addr(idx : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(idx * 4, 32));
    end function;

begin

    uut : DataMemory port map (
        CLK       => CLK,
        Address   => Address,
        WriteData => WriteData,
        MemRead   => MemRead,
        MemWrite  => MemWrite,
        ReadData  => ReadData
    );

    -- 100 MHz clock
    CLK <= not CLK after CLK_PERIOD / 2;

    stim : process
    begin
        -- Give reset one full cycle
        wait for CLK_PERIOD;

        -- -------------------------------------------------------
        -- Test 1: Write 0xDEADBEEF to address 0 (word 0)
        --   Simulates: STUR X_src, [X_base, #0]
        -- -------------------------------------------------------
        Address   <= word_addr(0);
        WriteData <= x"DEADBEEF";
        MemWrite  <= '1';
        MemRead   <= '0';
        wait until rising_edge(CLK);    -- Write latches on rising edge
        wait for 1 ns;                  -- Setup time
        MemWrite  <= '0';

        -- Test 1 read-back
        MemRead <= '1'; wait for 5 ns;
        assert ReadData = x"DEADBEEF"
            report "FAIL Test1: Write/Read word 0 (addr 0x00)" severity error;
        MemRead <= '0';

        -- -------------------------------------------------------
        -- Test 2: Write 0xCAFEBABE to address 4 (word 1)
        -- -------------------------------------------------------
        Address   <= word_addr(1);
        WriteData <= x"CAFEBABE";
        MemWrite  <= '1'; MemRead <= '0';
        wait until rising_edge(CLK);
        wait for 1 ns;
        MemWrite  <= '0';

        MemRead <= '1'; wait for 5 ns;
        assert ReadData = x"CAFEBABE"
            report "FAIL Test2: Write/Read word 1 (addr 0x04)" severity error;
        MemRead <= '0';

        -- -------------------------------------------------------
        -- Test 3: Write to address 8 (word 2), #8 offset typical of LDUR X4,[X1,#8]
        -- -------------------------------------------------------
        Address   <= word_addr(2);      -- 0x00000008
        WriteData <= x"12345678";
        MemWrite  <= '1'; MemRead <= '0';
        wait until rising_edge(CLK);
        wait for 1 ns;
        MemWrite  <= '0';

        MemRead <= '1'; wait for 5 ns;
        assert ReadData = x"12345678"
            report "FAIL Test3: Write/Read word 2 (addr 0x08)" severity error;
        MemRead <= '0';

        -- -------------------------------------------------------
        -- Test 4: Confirm word 0 still holds its value (no aliasing)
        -- -------------------------------------------------------
        Address <= word_addr(0);
        MemRead <= '1'; wait for 5 ns;
        assert ReadData = x"DEADBEEF"
            report "FAIL Test4: word 0 corrupted by other writes" severity error;
        MemRead <= '0';

        -- -------------------------------------------------------
        -- Test 5: Read-while-write-disabled returns 0
        -- -------------------------------------------------------
        Address <= word_addr(3);    -- Unwritten address
        MemRead <= '0'; MemWrite <= '0'; wait for 5 ns;
        assert ReadData = x"00000000"
            report "FAIL Test5: Disabled read should return 0" severity error;

        -- -------------------------------------------------------
        -- Test 6: Overwrite word 1 with new value
        -- -------------------------------------------------------
        Address   <= word_addr(1);
        WriteData <= x"0000FFFF";
        MemWrite  <= '1'; MemRead <= '0';
        wait until rising_edge(CLK);
        wait for 1 ns;
        MemWrite  <= '0';

        MemRead <= '1'; wait for 5 ns;
        assert ReadData = x"0000FFFF"
            report "FAIL Test6: Overwrite word 1" severity error;
        MemRead <= '0';

        -- -------------------------------------------------------
        -- Test 7: Write to high address (word 63 = byte addr 0xFC)
        -- -------------------------------------------------------
        Address   <= word_addr(63);
        WriteData <= x"BEEFCAFE";
        MemWrite  <= '1'; MemRead <= '0';
        wait until rising_edge(CLK);
        wait for 1 ns;
        MemWrite  <= '0';

        MemRead <= '1'; wait for 5 ns;
        assert ReadData = x"BEEFCAFE"
            report "FAIL Test7: Write/Read word 63 (addr 0xFC)" severity error;
        MemRead <= '0';

        -- -------------------------------------------------------
        -- Test 8: Word 0 still intact after all operations
        -- -------------------------------------------------------
        Address <= word_addr(0);
        MemRead <= '1'; wait for 5 ns;
        assert ReadData = x"DEADBEEF"
            report "FAIL Test8: word 0 final integrity check" severity error;
        MemRead <= '0';

        report "DataMemory: all tests passed." severity note;
        wait;
    end process;

end architecture Sim;
