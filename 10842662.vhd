library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;

entity project_reti_logiche is
  port (
    i_clk      : in std_logic;
    i_rst      : in std_logic;
    i_start    : in std_logic;
    i_add      : in std_logic_vector(15 downto 0);
    o_done     : out std_logic;
    o_mem_addr : out std_logic_vector(15 downto 0);
    i_mem_data : in std_logic_vector(7 downto 0);
    o_mem_data : out std_logic_vector(7 downto 0);
    o_mem_we   : out std_logic;
    o_mem_en   : out std_logic
  );
end project_reti_logiche;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity sliding_window is
  port (
    i_clk      : in std_logic;
    i_rst      : in std_logic;
    i_data     : in std_logic_vector(7 downto 0);
    i_load     : in std_logic;
    i_zero_val : in std_logic;
    o_window   : out std_logic_vector(55 downto 0)
  );
end entity;
architecture sliding_window_arch of sliding_window is
  signal window : std_logic_vector(55 downto 0) := (others => '0');
begin
  process(i_clk, i_rst)
  begin
    if i_rst = '1' then
      window <= (others => '0');
    elsif i_clk'event and i_clk = '1' then
      if i_load = '1' then
        if i_zero_val = '1' then
          window <= window(47 downto 0) & "00000000";
        else
          window <= window(47 downto 0) & i_data;
        end if;
      end if;
    end if;
  end process;

  o_window <= window;
end architecture;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
entity counter is
  port (
    i_clk      : in std_logic;
    i_rst      : in std_logic;
    i_count_en : in std_logic;
    o_data     : out std_logic_vector(15 downto 0)
  );
end counter;
architecture counter_arch of counter is
  signal curr_value : std_logic_vector(15 downto 0) := (others => '0');
begin
  o_data <= curr_value;

  process (i_clk, i_rst)
  begin
    if i_rst = '1' then
      curr_value <= (others => '0');
    elsif i_clk'event and i_clk = '1' and i_count_en = '1' then
      curr_value <= curr_value + 1;
    end if;
  end process;
end counter_arch;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity address_calculator is
  port (
    i_data_count   : in std_logic_vector(15 downto 0);
    i_k            : in std_logic_vector(15 downto 0);
    i_add          : in std_logic_vector(15 downto 0);
    i_is_write_out : in std_logic;
    o_addr         : out std_logic_vector(15 downto 0)
  );
end entity;
architecture address_calculator_arch of address_calculator is
begin
  process(i_data_count, i_k, i_add, i_is_write_out)
  begin
    if i_is_write_out = '1' then
      o_addr <= std_logic_vector(unsigned(i_add) + 17 + unsigned(i_k) + (unsigned(i_data_count) - 21)); -- Indirizzo calcolato per la parola Wi con i = count - (17 + 4)
    else
      o_addr <= std_logic_vector(unsigned(i_add) + unsigned(i_data_count));
    end if;
  end process;
end architecture;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity mac_unit is
  port (
    i_clk       : in std_logic;
    i_rst       : in std_logic;
    i_window    : in std_logic_vector(55 downto 0);
    i_coeffs    : in std_logic_vector(55 downto 0);
    i_mac_en    : in std_logic;
    o_mac_value : out signed(17 downto 0)
  );
end entity;
architecture mac_unit_arch of mac_unit is
begin
  process(i_clk, i_rst)
    variable sum : signed(17 downto 0);
  begin
    if i_rst = '1' then
      o_mac_value <= (others => '0');
    elsif i_clk'event and i_clk = '1' and i_mac_en = '1' then
      sum := (others => '0');
      for i in 0 to 6 loop
        sum := sum + signed(i_coeffs(i*8+7 downto i*8)) * signed(i_window(i*8+7 downto i*8));
      end loop;
      o_mac_value <= sum;
    end if;
  end process;
end architecture;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity normalization_unit is
  port(
    i_val            : in signed(17 downto 0);
    i_filter         : in std_logic;
    o_filtered_value : out std_logic_vector(7 downto 0)
  );
end entity;
architecture normalization_unit_arch of normalization_unit is
  constant MAX_OUT : signed(7 downto 0) := to_signed(127, 8);
  constant MIN_OUT : signed(7 downto 0) := to_signed(-128, 8);
begin
  process(i_val)
    variable v_shift4, v_shift6, v_shift8, v_shift10 : signed(17 downto 0);
    variable v_sum : signed(17 downto 0);
  begin
    v_shift4  := shift_right(i_val, 4);
    v_shift6  := shift_right(i_val, 6);
    v_shift8  := shift_right(i_val, 8);
    v_shift10 := shift_right(i_val, 10);

    -- Se i_val < 0, correggo la normalizzazione (v_shift + 1)
    if i_val(i_val'high) = '1' then
      v_shift4  := v_shift4 + 1;
      v_shift6  := v_shift6 + 1;
      v_shift8  := v_shift8 + 1;
      v_shift10 := v_shift10 + 1;
    end if;

    if i_filter = '0' then
      v_sum := v_shift4 + v_shift6 + v_shift8 + v_shift10;
    else
      v_sum := v_shift6 + v_shift10;
    end if;

    if v_sum > resize(MAX_OUT, 18) then
      o_filtered_value <= std_logic_vector(MAX_OUT);
    elsif v_sum < resize(MIN_OUT, 18) then
      o_filtered_value <= std_logic_vector(MIN_OUT);
    else
      o_filtered_value <= std_logic_vector(resize(v_sum, 8));
    end if;
  end process;
end architecture;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity fsm is
  port (
    i_clk        : in std_logic;
    i_rst        : in std_logic;
    i_start      : in std_logic;
    i_mem_data   : in std_logic_vector(7 downto 0);
    i_data_count : in std_logic_vector(15 downto 0);

    o_is_write_out      : out std_logic;
    o_input_len         : out std_logic_vector(15 downto 0);
    o_mem_we            : out std_logic;
    o_counter_increment : out std_logic;
    o_filter_order      : out std_logic;
    o_filter_coeffs     : out std_logic_vector(55 downto 0);
    o_window_we         : out std_logic;
    o_window_zero_in    : out std_logic;
    o_mac_en            : out std_logic;
    o_done              : out std_logic
  );
end entity;

architecture fsm_arch of fsm is
  type state_type is (IDLE, READ_MEM, READ_K1, READ_K2, READ_S, READ_COEFFS, INIT_WINDOW, APPLY_FILTER, WRITE_OUT, DONE);
  signal current_state : state_type;
  signal temp_k1 : std_logic_vector(7 downto 0);
  signal k : std_logic_vector(15 downto 0);
  signal s : std_logic;
  signal temp_coeffs : std_logic_vector(55 downto 0);
begin
  process(i_clk, i_rst)
    variable u_data_count : unsigned(15 downto 0);
    variable u_k : unsigned(15 downto 0);
  begin
    if i_rst = '1' then
      current_state <= IDLE;
      temp_k1 <= (others => '0');
      k <= (others => '0');
      s <= '0';
      temp_coeffs <= (others => '0');
    elsif i_clk'event and i_clk = '1' then
      u_data_count := unsigned(i_data_count);
      u_k := unsigned(k);
      case current_state is
        when IDLE =>
          if i_start = '1' then
            current_state <= READ_MEM;
          end if;
        when READ_MEM =>
          if u_data_count = 0 then
            current_state <= READ_K1;
          elsif u_data_count = 1 then
            current_state <= READ_K2;
          elsif u_data_count = 2 then
            current_state <= READ_S;
          elsif u_data_count >= 3 and u_data_count <= 16 then
            current_state <= READ_COEFFS;
          elsif u_data_count > 16 and u_data_count < 21 then
            current_state <= INIT_WINDOW;
          else -- u_data_count >= 21
            current_state <= APPLY_FILTER;
          end if;
        when READ_K1 =>
          temp_k1 <= i_mem_data;
          current_state <= READ_MEM;
        when READ_K2 =>
          k <= temp_k1 & i_mem_data;
          current_state <= READ_MEM;
        when READ_S =>
          s <= i_mem_data(0);
          current_state <= READ_MEM;
        when READ_COEFFS =>
          if ((s = '0' and u_data_count > 3 and u_data_count < 10) or
              (s = '1' and u_data_count > 9 and u_data_count < 17)) then -- padding per filtro ordine 3
            if (s = '0' and u_data_count = 9) then
              temp_coeffs <= temp_coeffs(47 downto 0) & "00000000"; -- padding per filtro ordine 3
            else
              temp_coeffs <= temp_coeffs(47 downto 0) & i_mem_data;
            end if;
          end if;
          if u_data_count < 17 then
            current_state <= READ_MEM;
          end if;
        when INIT_WINDOW =>
          current_state <= READ_MEM;
        when APPLY_FILTER =>
          current_state <= WRITE_OUT;
        when WRITE_OUT =>
          if u_data_count < (17 + u_k + 3) then
            current_state <= READ_MEM;
          else
            current_state <= DONE;
          end if;
        when DONE =>
          if i_start = '0' then
            current_state <= IDLE;
          end if;
        when others =>
          current_state <= IDLE;
      end case;
    end if;
  end process;

  process(current_state)
    variable window_data_index : unsigned(15 downto 0);
  begin
    o_counter_increment <= '0';
    o_filter_order <= s;
    o_filter_coeffs <= temp_coeffs;
    o_window_we <= '0';
    o_window_zero_in <= '0';
    o_mac_en <= '0';
    o_is_write_out <= '0';
    o_mem_we <= '0';
    o_input_len <= k;
    o_done <= '0';

    case current_state is
      when IDLE =>
        null;
      when READ_MEM =>
        null;
      when READ_K1 =>
        o_counter_increment <= '1';
      when READ_K2 =>
        o_counter_increment <= '1';
      when READ_S =>
        o_counter_increment <= '1';
      when READ_COEFFS =>
        o_counter_increment <= '1';
      when INIT_WINDOW =>
        window_data_index   := unsigned(i_data_count) - 17;
        if window_data_index >= unsigned(k) then
          o_window_zero_in <= '1';
        end if;
        o_counter_increment <= '1';
        o_window_we <= '1';
      when APPLY_FILTER =>
        window_data_index := unsigned(i_data_count) - 17;
        if window_data_index >= unsigned(k) then
          o_window_zero_in <= '1';
        end if;
        o_mac_en <= '1';
        o_window_we <= '1';
      when WRITE_OUT =>
        o_is_write_out <= '1';
        o_mem_we <= '1';
        o_counter_increment <= '1';
      when DONE =>
        o_done <= '1';
      when others =>
        null;
    end case;
  end process;
end architecture;

architecture Behavioral of project_reti_logiche is
  signal curr_addr         : std_logic_vector(15 downto 0);
  signal is_write_out      : std_logic;
  signal input_len         : std_logic_vector(15 downto 0);
  signal window_out        : std_logic_vector(55 downto 0);
  signal mac_out           : signed(17 downto 0);
  signal mac_en            : std_logic;
  signal window_we         : std_logic;
  signal window_zero_in    : std_logic;
  signal filter_order      : std_logic;
  signal filter_coeffs     : std_logic_vector(55 downto 0);
  signal counter_increment : std_logic;
  signal counter_out       : std_logic_vector(15 downto 0);
  signal component_reset   : std_logic;
begin
  SLIDING_WINDOW: entity work.sliding_window
    port map (
      i_clk      => i_clk,
      i_rst      => component_reset,
      i_data     => i_mem_data,
      i_zero_val => window_zero_in,
      i_load     => window_we,
      o_window   => window_out
    );

  COUNT: entity work.counter
    port map(
      i_clk      => i_clk,
      i_rst      => component_reset,
      i_count_en => counter_increment,
      o_data     => counter_out
    );

  ADDR_CALC: entity work.address_calculator
    port map (
      i_data_count   => counter_out,
      i_k            => input_len,
      i_add          => i_add,
      i_is_write_out => is_write_out,
      o_addr         => curr_addr
    );

  MAC: entity work.mac_unit
    port map (
      i_clk       => i_clk,
      i_rst       => component_reset,
      i_coeffs    => filter_coeffs,
      i_window    => window_out,
      i_mac_en    => mac_en,
      o_mac_value => mac_out
    );

  NORM: entity work.normalization_unit
    port map (
      i_val            => mac_out,
      i_filter         => filter_order,
      o_filtered_value => o_mem_data
    );

  CTRL_FSM: entity work.fsm
    port map (
      i_clk               => i_clk,
      i_rst               => i_rst,
      i_start             => i_start,
      i_data_count        => counter_out,
      i_mem_data          => i_mem_data,
      o_is_write_out      => is_write_out,
      o_input_len         => input_len,
      o_counter_increment => counter_increment,
      o_mem_we            => o_mem_we,
      o_filter_order      => filter_order,
      o_filter_coeffs     => filter_coeffs,
      o_window_we         => window_we,
      o_window_zero_in    => window_zero_in,
      o_mac_en            => mac_en,
      o_done              => o_done
    );

  component_reset <= i_rst or not i_start;
  o_mem_en <= i_start;
  o_mem_addr <= curr_addr;
end architecture;