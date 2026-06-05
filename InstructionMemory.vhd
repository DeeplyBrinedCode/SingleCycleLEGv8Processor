library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity InstructionMemory is
    Port (
        Address     : in  STD_LOGIC_VECTOR(31 downto 0);
        Instruction : out STD_LOGIC_VECTOR(31 downto 0)
    );
end InstructionMemory;

architecture Behavioral of InstructionMemory is

type ROM_TYPE is array (0 to 31) of STD_LOGIC_VECTOR(31 downto 0);

constant ROM : ROM_TYPE := (

    -- ADDI X1, XZR, #5
    0 => x"91001401",

    -- ADDI X2, XZR, #10
    1 => x"91002802",

    -- ADD X3, X1, X2
    2 => x"8B020023",

    -- SUB X4, X3, X1
    3 => x"CB010064",

    -- AND X5, X3, X2
    4 => x"8A020065",

    -- ORR X6, X1, X2
    5 => x"AA020026",

    -- STUR X3, [XZR,#0]
    6 => x"F8000003",

    -- LDUR X7, [XZR,#0]
    7 => x"F8400007",

    -- B END
    8 => x"14000002",

    -- ADDI X1, X0, #99 Should be skipped
    9 => x"91018C01",

    -- END: NOP
    10 => x"D503201F",

    others => x"D503201F"
);

begin

    Instruction <= ROM(
        to_integer(unsigned(Address(6 downto 2)))
    );

end Behavioral;
