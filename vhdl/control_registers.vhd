LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY control_registers IS
  PORT (
    clk : IN STD_LOGIC;
    reset_n : IN STD_LOGIC;
    write_n : IN STD_LOGIC;
    backup_n : IN STD_LOGIC;
    restore_n : IN STD_LOGIC;
    address : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    irq : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    wrdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

    ipending : OUT STD_LOGIC;
    rddata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END control_registers;

ARCHITECTURE synth OF control_registers IS
  SIGNAL status : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL estatus : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL bstatus : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL ienable : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL s_ipending : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL cpuid : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
BEGIN

  control_process : PROCESS (clk, reset_n) IS
  BEGIN
    IF reset_n = '0' THEN
      status(0) <= '0';
      estatus(0) <= '0';
      bstatus(0) <= '0';
      ienable <= (OTHERS => '0');
      cpuid <= (OTHERS => '0');
      s_ipending <= (OTHERS => '0');
    ELSE
      IF (rising_edge(clk)) THEN

        IF (write_n = '0') THEN
          CASE (address) IS
            WHEN "000" => status(0) <= wrdata(0);
            WHEN "001" => estatus(0) <= wrdata(0);
            WHEN "010" => bstatus(0) <= wrdata(0);
            WHEN "011" =>
              ienable <= wrdata;
              s_ipending <= wrdata AND irq;
              -- WHEN "100" => s_ipending <= v_ienable AND status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0);
            
            WHEN "100" => REPORT "Writing to address 4";
            WHEN "101" => cpuid <= wrdata;
            WHEN OTHERS => NULL;
          END CASE;
        END IF;

        IF (backup_n = '0') THEN
          estatus(0) <= status(0);
          status(0) <= '0';
        END IF;

        IF (restore_n = '0') THEN
          status(0) <= estatus(0);
          -- estatus(0) <= '0';
          -- should we clear estatus?
        END IF;
      END IF;
    END IF;
  END PROCESS control_process;

  WITH address SELECT rddata <=
    "0000000000000000000000000000000" & status(0) WHEN "000",
    "0000000000000000000000000000000" & estatus(0) WHEN "001",
    "0000000000000000000000000000000" & bstatus(0) WHEN "010",
    ienable WHEN "011",
    s_ipending WHEN "100",
    cpuid WHEN "101",
    (OTHERS => 'Z') WHEN OTHERS;

  -- s_ipending <= ienable AND irq;
  -- status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0) & status(0);

  ipending <= '1' WHEN s_ipending /= x"00000000" AND status(0) = '1' ELSE '0';


  -- WITH s_ipending /= "00000000000000000000000000000000" AND status(0) = '1' SELECT ipending <=
  -- '1' WHEN TRUE,
  -- '0' WHEN OTHERS;

END synth;