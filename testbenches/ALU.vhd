-- =============================================================
-- ALU.vhd
-- LEGv8 Single-Cycle Processor – Arithmetic Logic Unit (Module 5)
--
-- Supported operations (selected by ALUControl):
--   "0000" – AND   : Result = A AND B
--   "0001" – ORR   : Result = A OR  B
--   "0010" – ADD   : Result = A + B
--   "0110" – SUB   : Result = A - B  (also used by CBZ/branch compare)
--   "1111" – PASS B: Result = B      (used by LDUR/STUR address calc with imm)
--
-- Outputs:
--   ALUResult : 32-bit computation result
--   Zero      : '1' when ALUResult = 0 (used by CBZ branch logic)
-- =============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
    port (
        A          : in  std_logic_vector(31 downto 0);  -- Operand A (register read data 1)
        B          : in  std_logic_vector(31 downto 0);  -- Operand B (register or immediate)
        ALUControl : in  std_logic_vector(3  downto 0);  -- Operation select
        ALUResult  : out std_logic_vector(31 downto 0);  -- Computation result
        Zero       : out std_logic                        -- High when result = 0
    );
end entity ALU;

architecture Behavioral of ALU is

    signal result_internal : std_logic_vector(31 downto 0);

    -- -------------------------------------------------------
    -- ALUControl encoding (matches Patterson & Hennessy LEGv8)
    -- -------------------------------------------------------
    constant ALU_AND  : std_logic_vector(3 downto 0) := "0000";
    constant ALU_ORR  : std_logic_vector(3 downto 0) := "0001";
    constant ALU_ADD  : std_logic_vector(3 downto 0) := "0010";
    constant ALU_SUB  : std_logic_vector(3 downto 0) := "0110";
    constant ALU_PASS : std_logic_vector(3 downto 0) := "1111"; -- pass B (optional)

begin

    -- -------------------------------------------------------
    -- Combinational ALU operation
    -- -------------------------------------------------------
    process(A, B, ALUControl)
        variable a_s : signed(31 downto 0);
        variable b_s : signed(31 downto 0);
        variable r_s : signed(31 downto 0);
    begin
        a_s := signed(A);
        b_s := signed(B);

        case ALUControl is
            when ALU_AND =>
                result_internal <= A and B;

            when ALU_ORR =>
                result_internal <= A or B;

            when ALU_ADD =>
                r_s := a_s + b_s;
                result_internal <= std_logic_vector(r_s);

            when ALU_SUB =>
                r_s := a_s - b_s;
                result_internal <= std_logic_vector(r_s);

            when ALU_PASS =>
                -- Pass B through unchanged (useful for address generation)
                result_internal <= B;

            when others =>
                result_internal <= (others => '0');
        end case;
    end process;

    -- Drive outputs
    ALUResult <= result_internal;
    Zero      <= '1' when result_internal = x"00000000" else '0';

end architecture Behavioral;


-- =============================================================
-- Testbench: tALU.vhd
-- Verifies all five ALU operations independently, including
-- Zero flag behavior for CBZ support.
-- =============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tALU is
end entity tALU;

architecture Sim of tALU is

    component ALU
        port (
            A          : in  std_logic_vector(31 downto 0);
            B          : in  std_logic_vector(31 downto 0);
            ALUControl : in  std_logic_vector(3  downto 0);
            ALUResult  : out std_logic_vector(31 downto 0);
            Zero       : out std_logic
        );
    end component;

    signal A, B       : std_logic_vector(31 downto 0) := (others => '0');
    signal ALUControl : std_logic_vector(3 downto 0)  := "0000";
    signal ALUResult  : std_logic_vector(31 downto 0);
    signal Zero       : std_logic;

    -- Convenience function to build std_logic_vector from integer
    function slv32(n : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(n, 32));
    end function;

begin

    uut : ALU port map (A => A, B => B, ALUControl => ALUControl,
                        ALUResult => ALUResult, Zero => Zero);

    stim : process
    begin
        -- -------------------------------------------------------
        -- ADD Tests
        -- -------------------------------------------------------
        -- Test 1: 5 + 3 = 8
        A <= slv32(5); B <= slv32(3); ALUControl <= "0010"; wait for 10 ns;
        assert ALUResult = slv32(8) and Zero = '0'
            report "FAIL ADD 5+3" severity error;

        -- Test 2: 0 + 0 = 0, Zero should be '1'
        A <= slv32(0); B <= slv32(0); ALUControl <= "0010"; wait for 10 ns;
        assert ALUResult = slv32(0) and Zero = '1'
            report "FAIL ADD 0+0 Zero flag" severity error;

        -- Test 3: Overflow wraps (signed): MAXINT + 1 wraps to MININT
        A <= x"7FFFFFFF"; B <= slv32(1); ALUControl <= "0010"; wait for 10 ns;
        assert ALUResult = x"80000000"
            report "FAIL ADD overflow wrap" severity error;

        -- -------------------------------------------------------
        -- SUB Tests
        -- -------------------------------------------------------
        -- Test 4: 10 - 3 = 7
        A <= slv32(10); B <= slv32(3); ALUControl <= "0110"; wait for 10 ns;
        assert ALUResult = slv32(7) and Zero = '0'
            report "FAIL SUB 10-3" severity error;

        -- Test 5: 5 - 5 = 0, Zero flag
        A <= slv32(5); B <= slv32(5); ALUControl <= "0110"; wait for 10 ns;
        assert ALUResult = slv32(0) and Zero = '1'
            report "FAIL SUB 5-5 Zero flag" severity error;

        -- Test 6: 3 - 10 = -7
        A <= slv32(3); B <= slv32(10); ALUControl <= "0110"; wait for 10 ns;
        assert ALUResult = slv32(-7) and Zero = '0'
            report "FAIL SUB 3-10 negative result" severity error;

        -- -------------------------------------------------------
        -- AND Tests
        -- -------------------------------------------------------
        -- Test 7: 0xFF00FF00 AND 0xF0F0F0F0 = 0xF000F000
        A <= x"FF00FF00"; B <= x"F0F0F0F0"; ALUControl <= "0000"; wait for 10 ns;
        assert ALUResult = x"F000F000"
            report "FAIL AND basic" severity error;

        -- Test 8: anything AND 0 = 0, Zero flag
        A <= x"DEADBEEF"; B <= x"00000000"; ALUControl <= "0000"; wait for 10 ns;
        assert ALUResult = x"00000000" and Zero = '1'
            report "FAIL AND with zero" severity error;

        -- -------------------------------------------------------
        -- ORR Tests
        -- -------------------------------------------------------
        -- Test 9: 0x0F0F0F0F ORR 0xF0F0F0F0 = 0xFFFFFFFF
        A <= x"0F0F0F0F"; B <= x"F0F0F0F0"; ALUControl <= "0001"; wait for 10 ns;
        assert ALUResult = x"FFFFFFFF" and Zero = '0'
            report "FAIL ORR complementary" severity error;

        -- Test 10: 0 ORR 0 = 0, Zero flag
        A <= x"00000000"; B <= x"00000000"; ALUControl <= "0001"; wait for 10 ns;
        assert ALUResult = x"00000000" and Zero = '1'
            report "FAIL ORR zero" severity error;

        -- -------------------------------------------------------
        -- PASS B (address generation support)
        -- -------------------------------------------------------
        -- Test 11: PASS B passes operand B unchanged
        A <= x"DEADBEEF"; B <= x"0000000C"; ALUControl <= "1111"; wait for 10 ns;
        assert ALUResult = x"0000000C"
            report "FAIL PASS B" severity error;

        -- -------------------------------------------------------
        -- Zero flag edge cases
        -- -------------------------------------------------------
        -- Test 12: -1 + 1 = 0, Zero flag
        A <= slv32(-1); B <= slv32(1); ALUControl <= "0010"; wait for 10 ns;
        assert ALUResult = slv32(0) and Zero = '1'
            report "FAIL Zero flag -1+1" severity error;

        report "ALU: all tests passed." severity note;
        wait;
    end process;

end architecture Sim;
