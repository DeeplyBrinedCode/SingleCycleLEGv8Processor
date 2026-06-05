-- =============================================================
-- ImmediateGenerator.vhd
-- LEGv8 Single-Cycle Processor – Immediate Generator (Module 4)
--
-- Extracts and sign-extends immediate fields from LEGv8 instructions:
--   ADDI  : 12-bit immediate (bits [21:10])
--   LDUR  : 9-bit offset    (bits [20:12])
--   STUR  : 9-bit offset    (bits [20:12])
--   CBZ   : 19-bit offset   (bits [23:5])
--   B     : 26-bit offset   (bits [25:0])
--
-- All outputs are sign-extended to 32 bits.
-- =============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ImmediateGenerator is
    port (
        Instruction : in  std_logic_vector(31 downto 0);  -- Full 32-bit instruction word
        ImmOut      : out std_logic_vector(31 downto 0)   -- Sign-extended 32-bit immediate
    );
end entity ImmediateGenerator;

architecture Behavioral of ImmediateGenerator is

    -- Opcode field (bits [31:21]) – 11 bits
    signal opcode : std_logic_vector(10 downto 0);

    -- -------------------------------------------------------
    -- LEGv8 Opcode Constants
    -- -------------------------------------------------------
    -- R-type (no immediate needed, included for completeness)
    constant OP_ADD  : std_logic_vector(10 downto 0) := "10001011000"; -- ADD
    constant OP_SUB  : std_logic_vector(10 downto 0) := "11001011000"; -- SUB
    constant OP_AND  : std_logic_vector(10 downto 0) := "10001010000"; -- AND
    constant OP_ORR  : std_logic_vector(10 downto 0) := "10101010000"; -- ORR

    -- I-type
    constant OP_ADDI : std_logic_vector(10 downto 0) := "10010001000"; -- ADDI

    -- D-type
    constant OP_LDUR : std_logic_vector(10 downto 0) := "11111000010"; -- LDUR
    constant OP_STUR : std_logic_vector(10 downto 0) := "11111000000"; -- STUR

    -- CB-type
    constant OP_CBZ  : std_logic_vector(10 downto 0) := "10110100000"; -- CBZ (upper 8 match)

    -- B-type
    constant OP_B    : std_logic_vector(10 downto 0) := "00010100000"; -- B (upper 6 match)

begin

    opcode <= Instruction(31 downto 21);

    process(Instruction, opcode)
        variable raw_imm : std_logic_vector(31 downto 0);
    begin
        raw_imm := (others => '0'); -- default

        -- -------------------------------------------------------
        -- ADDI – I-type: bits [21:10] = 12-bit immediate
        -- -------------------------------------------------------
        if opcode = OP_ADDI then
            -- Sign-extend 12-bit immediate
            raw_imm(11 downto 0) := Instruction(21 downto 10);
            if Instruction(21) = '1' then
                raw_imm(31 downto 12) := (others => '1');
            else
                raw_imm(31 downto 12) := (others => '0');
            end if;

        -- -------------------------------------------------------
        -- LDUR / STUR – D-type: bits [20:12] = 9-bit offset
        -- -------------------------------------------------------
        elsif opcode = OP_LDUR or opcode = OP_STUR then
            -- Sign-extend 9-bit immediate
            raw_imm(8 downto 0) := Instruction(20 downto 12);
            if Instruction(20) = '1' then
                raw_imm(31 downto 9) := (others => '1');
            else
                raw_imm(31 downto 9) := (others => '0');
            end if;

        -- -------------------------------------------------------
        -- CBZ – CB-type: bits [23:5] = 19-bit PC-relative offset
        -- Opcode is upper 8 bits: Instruction[31:24] = "10110100"
        -- -------------------------------------------------------
        elsif Instruction(31 downto 24) = "10110100" then
            -- Sign-extend 19-bit immediate
            raw_imm(18 downto 0) := Instruction(23 downto 5);
            if Instruction(23) = '1' then
                raw_imm(31 downto 19) := (others => '1');
            else
                raw_imm(31 downto 19) := (others => '0');
            end if;

        -- -------------------------------------------------------
        -- B – B-type: bits [25:0] = 26-bit PC-relative offset
        -- Opcode is upper 6 bits: Instruction[31:26] = "000101"
        -- -------------------------------------------------------
        elsif Instruction(31 downto 26) = "000101" then
            -- Sign-extend 26-bit immediate
            raw_imm(25 downto 0) := Instruction(25 downto 0);
            if Instruction(25) = '1' then
                raw_imm(31 downto 26) := (others => '1');
            else
                raw_imm(31 downto 26) := (others => '0');
            end if;

        -- -------------------------------------------------------
        -- R-type or unknown – no immediate needed, output zero
        -- -------------------------------------------------------
        else
            raw_imm := (others => '0');
        end if;

        ImmOut <= raw_imm;
    end process;

end architecture Behavioral;


-- =============================================================
-- Testbench: tImmediateGenerator.vhd
-- Verifies positive, negative, and zero immediates for each
-- supported instruction type (ADDI, LDUR, STUR, CBZ, B).
-- =============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tImmediateGenerator is
end entity tImmediateGenerator;

architecture Sim of tImmediateGenerator is

    component ImmediateGenerator
        port (
            Instruction : in  std_logic_vector(31 downto 0);
            ImmOut      : out std_logic_vector(31 downto 0)
        );
    end component;

    signal Instruction : std_logic_vector(31 downto 0) := (others => '0');
    signal ImmOut      : std_logic_vector(31 downto 0);

    -- Helper: build a D-type instruction word (LDUR/STUR)
    --   opcode[31:21], offset[20:12], op2[11:10], Rn[9:5], Rt[4:0]
    function make_d_type(
        op     : std_logic_vector(10 downto 0);
        offset : std_logic_vector(8  downto 0);
        op2    : std_logic_vector(1  downto 0);
        rn     : std_logic_vector(4  downto 0);
        rt     : std_logic_vector(4  downto 0))
    return std_logic_vector is
    begin
        return op & offset & op2 & rn & rt;
    end function;

    -- Helper: build an I-type instruction word (ADDI)
    --   opcode[31:21], imm12[21:10], Rn[9:5], Rd[4:0]
    function make_i_type(
        op   : std_logic_vector(10 downto 0);
        imm  : std_logic_vector(11 downto 0);
        rn   : std_logic_vector(4  downto 0);
        rd   : std_logic_vector(4  downto 0))
    return std_logic_vector is
    begin
        return op & imm & rn & rd;
    end function;

    -- Helper: build a CB-type instruction word (CBZ)
    --   opcode[31:24], offset19[23:5], Rt[4:0]
    function make_cb_type(
        op     : std_logic_vector(7  downto 0);
        offset : std_logic_vector(18 downto 0);
        rt     : std_logic_vector(4  downto 0))
    return std_logic_vector is
    begin
        return op & offset & rt;
    end function;

    -- Helper: build a B-type instruction word (B)
    --   opcode[31:26], offset26[25:0]
    function make_b_type(
        op     : std_logic_vector(5  downto 0);
        offset : std_logic_vector(25 downto 0))
    return std_logic_vector is
    begin
        return op & offset;
    end function;

begin

    uut : ImmediateGenerator
        port map (Instruction => Instruction, ImmOut => ImmOut);

    stim : process
    begin
        -- -------------------------------------------------------
        -- Test 1: LDUR X4, [X1, #8]   → 9-bit offset = +8
        --   Expected ImmOut = 0x00000008
        -- -------------------------------------------------------
        Instruction <= make_d_type(
            "11111000010",          -- LDUR opcode
            "000001000",            -- offset = 8
            "00",
            "00001",                -- X1
            "00100");               -- X4
        wait for 20 ns;
        assert ImmOut = x"00000008"
            report "FAIL Test1 LDUR +8: got " & integer'image(to_integer(unsigned(ImmOut)))
            severity error;

        -- -------------------------------------------------------
        -- Test 2: LDUR with negative offset (#-4)
        --   9-bit two's complement of -4 = "111111100"
        --   Expected ImmOut = 0xFFFFFFFC
        -- -------------------------------------------------------
        Instruction <= make_d_type(
            "11111000010",
            "111111100",            -- -4 in 9-bit two's complement
            "00",
            "00001",
            "00100");
        wait for 20 ns;
        assert ImmOut = x"FFFFFFFC"
            report "FAIL Test2 LDUR -4: got " & integer'image(to_integer(signed(ImmOut)))
            severity error;

        -- -------------------------------------------------------
        -- Test 3: STUR X3, [X1, #16]  → offset = +16
        --   Expected ImmOut = 0x00000010
        -- -------------------------------------------------------
        Instruction <= make_d_type(
            "11111000000",          -- STUR opcode
            "000010000",            -- offset = 16
            "00",
            "00001",
            "00011");
        wait for 20 ns;
        assert ImmOut = x"00000010"
            report "FAIL Test3 STUR +16"
            severity error;

        -- -------------------------------------------------------
        -- Test 4: ADDI X2, X1, #100  → 12-bit imm = 100
        --   Expected ImmOut = 0x00000064
        -- -------------------------------------------------------
        Instruction <= make_i_type(
            "10010001000",          -- ADDI opcode
            "000001100100",         -- 100 in binary (12 bits)
            "00001",                -- X1
            "00010");               -- X2
        wait for 20 ns;
        assert ImmOut = x"00000064"
            report "FAIL Test4 ADDI +100"
            severity error;

        -- -------------------------------------------------------
        -- Test 5: ADDI with negative 12-bit immediate (#-1)
        --   12-bit two's complement of -1 = "111111111111"
        --   Expected ImmOut = 0xFFFFFFFF
        -- -------------------------------------------------------
        Instruction <= make_i_type(
            "10010001000",
            "111111111111",         -- -1 in 12-bit two's complement
            "00001",
            "00010");
        wait for 20 ns;
        assert ImmOut = x"FFFFFFFF"
            report "FAIL Test5 ADDI -1"
            severity error;

        -- -------------------------------------------------------
        -- Test 6: CBZ X0, #4  → 19-bit offset = 4
        --   Expected ImmOut = 0x00000004
        -- -------------------------------------------------------
        Instruction <= make_cb_type(
            "10110100",             -- CBZ opcode (upper 8 bits)
            "0000000000000000100",  -- offset = 4 (19 bits)
            "00000");               -- X0
        wait for 20 ns;
        assert ImmOut = x"00000004"
            report "FAIL Test6 CBZ +4"
            severity error;

        -- -------------------------------------------------------
        -- Test 7: CBZ with negative offset (#-8)
        --   19-bit two's complement of -8 = "1111111111111111000"
        --   Expected ImmOut = 0xFFFFFFF8
        -- -------------------------------------------------------
        Instruction <= make_cb_type(
            "10110100",
            "1111111111111111000",  -- -8 in 19-bit two's complement
            "00000");
        wait for 20 ns;
        assert ImmOut = x"FFFFFFF8"
            report "FAIL Test7 CBZ -8"
            severity error;

        -- -------------------------------------------------------
        -- Test 8: B #12  → 26-bit offset = 12
        --   Expected ImmOut = 0x0000000C
        -- -------------------------------------------------------
        Instruction <= make_b_type(
            "000101",               -- B opcode (upper 6 bits)
            "00000000000000000000001100"); -- offset = 12 (26 bits)
        wait for 20 ns;
        assert ImmOut = x"0000000C"
            report "FAIL Test8 B +12"
            severity error;

        -- -------------------------------------------------------
        -- Test 9: B with negative offset (#-4)
        --   26-bit two's complement of -4 = "11111111111111111111111100"
        --   Expected ImmOut = 0xFFFFFFFC
        -- -------------------------------------------------------
        Instruction <= make_b_type(
            "000101",
            "11111111111111111111111100"); -- -4 in 26-bit two's complement
        wait for 20 ns;
        assert ImmOut = x"FFFFFFFC"
            report "FAIL Test9 B -4"
            severity error;

        -- -------------------------------------------------------
        -- Test 10: R-type ADD → no immediate, expect 0
        -- -------------------------------------------------------
        Instruction <= "10001011000" & "00010" & "000000" & "00001" & "00011"; -- ADD X3,X1,X2
        wait for 20 ns;
        assert ImmOut = x"00000000"
            report "FAIL Test10 R-type ADD should give 0"
            severity error;

        report "ImmediateGenerator: all tests passed." severity note;
        wait;
    end process;

end architecture Sim;
