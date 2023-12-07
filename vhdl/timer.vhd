LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY timer IS
  PORT (
    -- bus interface
    clk : IN STD_LOGIC;
    reset_n : IN STD_LOGIC;
    cs : IN STD_LOGIC;
    read : IN STD_LOGIC;
    write : IN STD_LOGIC;
    address : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    wrdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

    irq : OUT STD_LOGIC;
    rddata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END timer;

ARCHITECTURE synth OF timer IS
  SIGNAL counter : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL period : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL control : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL status : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

  SIGNAL s_rddata : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => 'Z');
BEGIN

  timer : PROCESS (clk, reset_n, address, write, cs, wrdata, status, control, read, counter) IS
    VARIABLE addr : INTEGER RANGE 0 TO 3 := 0;
    VARIABLE v_counter : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    VARIABLE v_period : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    VARIABLE v_control : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    VARIABLE v_status : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  BEGIN
    IF (reset_n = '0') THEN
      counter <= (OTHERS => '0');
      period <= (OTHERS => '0');
      control <= (OTHERS => '0');
      status <= (OTHERS => '0');
    ELSIF (rising_edge(clk)) THEN
      addr := to_integer(unsigned(address));
      v_counter := counter;
      v_period := period;
      v_control := control;
      v_status := status;

      IF (write = '1' AND cs = '1') THEN
        CASE addr IS
          WHEN 0 => NULL; -- counter
          WHEN 1 => -- period
            v_period := wrdata;
            v_counter := wrdata;
            v_status(0) := '0'; -- RUN = 0
          WHEN 2 => -- control

            IF (wrdata(3) = '1') THEN -- START = 1
              v_status(0) := '1'; -- RUN = 1
            END IF;

            IF (wrdata(2) = '1') THEN -- STOP = 1
              v_status(0) := '0'; -- RUN = 0
            END IF;

            v_control(1 DOWNTO 0) := wrdata(1 DOWNTO 0);

          WHEN 3 => -- status
            IF (wrdata(1) = '0') THEN -- TO = 0
              v_status(1) := '0'; -- TO = 0
            END IF;
          WHEN OTHERS => NULL;
        END CASE;
      END IF;

      IF (v_status(0) = '1') THEN -- RUN = 1

        v_counter := STD_LOGIC_VECTOR(signed(v_counter) - 1);
        IF (signed(v_counter) < 0) THEN
          v_counter := v_period;
          v_status(1) := '1'; -- TO = 1

          IF (v_control(0) = '0') THEN -- CONT = 0
            v_status(0) := '0'; -- RUN = 0
          END IF;

        END IF;
      END IF;

      IF (read = '1' AND cs = '1') THEN
        CASE address IS
          WHEN "00" =>
            s_rddata <= counter;
          WHEN "01" =>
            s_rddata <= period;
          WHEN "10" =>
            s_rddata <= control;
          WHEN "11" =>
            s_rddata <= status;
          WHEN OTHERS =>
            s_rddata <= (OTHERS => 'Z');
        END CASE;
      END IF;

      counter <= v_counter;
      period <= v_period;
      control <= v_control;
      status <= v_status;
    END IF;

  END PROCESS timer;

  irq <= status(1) AND control(1); -- IRQ = TO AND ITO
  rddata <= s_rddata WHEN (reset_n = '1') ELSE (OTHERS => 'Z');
END synth;