LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY PC IS
  PORT (
    clk : IN STD_LOGIC;
    reset_n : IN STD_LOGIC;
    en : IN STD_LOGIC;
    sel_a : IN STD_LOGIC;
    sel_imm : IN STD_LOGIC;
    add_imm : IN STD_LOGIC;
    sel_ihandler : IN STD_LOGIC;
    imm : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    a : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    addr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END PC;

ARCHITECTURE synth OF PC IS
  SIGNAL s_addr : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
BEGIN

  addr <= s_addr(31 DOWNTO 0) AND "00000000000000001111111111111111";

  PROCESS (clk, reset_n) IS
  BEGIN
    IF (reset_n = '0') THEN
      s_addr <= (OTHERS => '0');
    ELSIF (rising_edge(clk)) THEN
      IF (en = '1') THEN
        IF (add_imm = '1') THEN
          s_addr <= STD_LOGIC_VECTOR(unsigned(s_addr) + unsigned(imm));
        ELSIF (sel_imm = '1') THEN
          s_addr <= STD_LOGIC_VECTOR(unsigned(imm) * 4); -- to check
        ELSIF (sel_ihandler = '1') THEN
          s_addr <= x"00000004";
        ELSIF (sel_a = '1') THEN
          s_addr <= "0000000000000000" & (a AND x"FFFC");
        ELSE
          s_addr <= STD_LOGIC_VECTOR(unsigned(s_addr) + 4);
        END IF;
      END IF;
    END IF;
  END PROCESS;

END synth;