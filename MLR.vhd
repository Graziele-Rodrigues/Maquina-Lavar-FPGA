
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity maquina_lavar is
    Port(
        clk             : in STD_LOGIC;
        b_reset         : in STD_LOGIC;
        b_start         : in STD_LOGIC;
        CH0             : in STD_LOGIC;
        CH1             : in STD_LOGIC;
        led_encher      : out STD_LOGIC;
        led_lavar       : out STD_LOGIC;
        led_enxaguar    : out STD_LOGIC;
        led_centrifugar : out STD_LOGIC
    );
end maquina_lavar;

architecture Behavioral of maquina_lavar is

    type state_type is(
        IDLE,
        ENCHER,
        LAVAR,
        ENXAGUAR,
        CENTRIFUGAR,
        FINAL
    );

    signal state, next_state : state_type := IDLE;

    signal reset   : STD_LOGIC;
    signal clk_div : STD_LOGIC;

    -- Tempos das etapas
    constant T_ENCHER      : unsigned(27 downto 0) := to_unsigned(18750000, 28); -- 3s
    constant T_LAVAR       : unsigned(27 downto 0) := to_unsigned(31250000, 28); -- 5s
    constant T_ENXAGUAR    : unsigned(27 downto 0) := to_unsigned(18750000, 28); -- 3s
    constant T_CENTRIFUGAR : unsigned(27 downto 0) := to_unsigned(31250000, 28); -- 5s

    -- Um unico contador compartilhado
    signal counter : unsigned(27 downto 0) := (others => '0');

    component Gowin_CLKDIV
        port(
            clkout : out STD_LOGIC;
            hclkin : in STD_LOGIC;
            resetn : in STD_LOGIC
        );
    end component;

begin

    -- Reset ativo em nivel baixo
    reset <= not b_reset;

    -- Divisor de clock
    u_clkdiv : Gowin_CLKDIV
        port map(
            clkout => clk_div,
            hclkin => clk,
            resetn => '1'
        );

    -- Contador unico compartilhado
    process(clk_div)
    begin
        if rising_edge(clk_div) then

            if reset = '1' then
                counter <= (others => '0');

            else
                case state is

                    when ENCHER =>
                        if counter >= T_ENCHER then
                            counter <= (others => '0');
                        else
                            counter <= counter + 1;
                        end if;

                    when LAVAR =>
                        if counter >= T_LAVAR then
                            counter <= (others => '0');
                        else
                            counter <= counter + 1;
                        end if;

                    when ENXAGUAR =>
                        if counter >= T_ENXAGUAR then
                            counter <= (others => '0');
                        else
                            counter <= counter + 1;
                        end if;

                    when CENTRIFUGAR =>
                        if counter >= T_CENTRIFUGAR then
                            counter <= (others => '0');
                        else
                            counter <= counter + 1;
                        end if;

                    when others =>
                        counter <= (others => '0');

                end case;
            end if;
        end if;
    end process;

    -- FSM: estado atual
    process(clk_div)
    begin
        if rising_edge(clk_div) then
            if reset = '1' then
                state <= IDLE;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    -- Logica de transicoes
    process(state, b_start, CH0, CH1, counter)
    begin

        next_state <= state;

        case state is

            when IDLE =>
                if b_start = '0' then
                    if CH0 = '1' and CH1 = '1' then
                        next_state <= ENCHER;
                    elsif CH0 = '0' and CH1 = '0' then
                        next_state <= ENCHER;
                    elsif CH0 = '1' and CH1 = '0' then
                        next_state <= ENXAGUAR;
                    elsif CH0 = '0' and CH1 = '1' then
                        next_state <= CENTRIFUGAR;
                    end if;
                end if;

            when ENCHER =>
                if counter >= T_ENCHER then
                    if CH0 = '0' and CH1 = '0' then
                        next_state <= LAVAR;
                    elsif CH0 = '1' and CH1 = '1' then
                        next_state <= LAVAR;
                    else
                        next_state <= FINAL;
                    end if;
                end if;

            when LAVAR =>
                if counter >= T_LAVAR then
                    if CH0 = '1' and CH1 = '1' then
                        next_state <= ENXAGUAR;
                    else
                        next_state <= FINAL;
                    end if;
                end if;

            when ENXAGUAR =>
                if counter >= T_ENXAGUAR then
                    if CH0 = '1' and CH1 = '0' then
                        next_state <= CENTRIFUGAR;
                    elsif CH0 = '1' and CH1 = '1' then
                        next_state <= CENTRIFUGAR;
                    else
                        next_state <= FINAL;
                    end if;
                end if;

            when CENTRIFUGAR =>
                if counter >= T_CENTRIFUGAR then
                    next_state <= FINAL;
                end if;

            when FINAL =>
                next_state <= FINAL;

            when others =>
                next_state <= IDLE;

        end case;

    end process;

    -- Saidas dos LEDs (ativo em nivel baixo)
    led_encher <= '0' when (state = ENCHER or state = FINAL) else '1';
    led_lavar <= '0' when (state = LAVAR or state = FINAL) else '1';
    led_enxaguar <= '0' when (state = ENXAGUAR or state = FINAL) else '1';
    led_centrifugar <= '0' when (state = CENTRIFUGAR or state = FINAL) else '1';

end Behavioral;
