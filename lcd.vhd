-- ENSC 350
-- SFU, SPRING 2023

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity lcd is
	port ( 
		KEY : in std_logic_vector (3 downto 0);
--		SW : in std_logic_vector ( 17 downto 0);
		-- resetb : in std_logic;
		LCD_BLON : out std_logic; -- backlight is always on
		LCD_ON : out std_logic; -- LCD is always on
		LCD_EN: out std_logic := '1'; -- connect the clock to the lcd_en input
		LCD_RW : out std_logic; -- always writing to the LCD
		LCD_RS : out std_logic; --
		LCD_DATA : out std_logic_vector (7 downto 0);
--		LEDG: out std_logic_vector (7 downto 0); -- send the clock to a green light
		CLOCK_50: in std_logic
--		LEDR: out std_logic_vector (17 downto 0) -- send the clock to a red light LEDs
	);
end entity;

architecture rtl of lcd is

	signal next_state : std_logic_vector(3 downto 0) := "0000";
	signal current_state : std_logic_vector(3 downto 0) := "0000";
	signal dir, resetb, slow_clock : std_logic;
	signal lcd_start, lcd_done : std_logic;
	signal counter, screen_counter: std_logic_vector (25 downto 0) := (others => '0');

begin
	
	LCD_BLON <= '1'; -- backlight is always on
	LCD_ON <= '1'; -- LCD is always on
	LCD_RW <= '0'; -- always writing to the LCD
	LCD_EN <= slow_clock;
	-- dir <= SW(0);
	resetb <= not KEY(3);
	-- LEDG(7) <= resetb; -- for debugging
	
	CLOCK_SLOWDOWN: process (CLOCK_50)
	begin
		if (rising_edge(CLOCK_50) and lcd_start = '1') then
			-- for a 1Hz clock we need 50Mhz divided by a number between 2^25 and 2^26) ~ 0.75s - 1.49s
			
			if (counter(5) = '1') then -- counter a total of 2^26 times at 50 MHz before triggering clk (slowed down clocked)
				slow_clock <= '1';
				counter <= (others => '0'); -- reset all 2^26 counter bits to 0
			else
				slow_clock <= '0';
				counter <= std_logic_vector(unsigned(counter) + 1);
			end if;
		end if;
	end process;


	NEXTE_LOGIC : process (current_state)
	begin
	if lcd_start = '1' then
		lcd_done <= '0';
		case current_state is
			when "0000" =>
				lcd_rs <= '0'; -- sending an instruction
				lcd_data <= "00111000";
--				LEDR <= "000000000000000000";
--				LEDR(0) <= '1';
				next_state <= "0001";
			when "0001" =>
				lcd_rs <= '0'; -- sending an instruction
				lcd_data <= "00111000";
--				LEDR <= "000000000000000000";
--				LEDR(1) <= '1';
				next_state <= "0010";
			when "0010" =>
				lcd_rs <= '0'; -- sending an instruction
				lcd_data <= "00001100";
--				LEDR <= "000000000000000000";
--				LEDR(2) <= '1';
				next_state <= "0011";
			when "0011" =>
				lcd_rs <= '0'; -- sending an instruction
				lcd_data <= "00000001";
--				LEDR <= "000000000000000000";
--				LEDR(3) <= '1';
				next_state <= "0100";
			when"0100" =>
				lcd_rs <= '0'; -- sending an instruction
				lcd_data <= "00000110";
--				LEDR <= "000000000000000000";
--				LEDR(4) <= '1';
				next_state <= "0101";
			when"0101" =>
				lcd_rs <= '0'; -- sending an instruction
				lcd_data <= "10000000";
--				LEDR <= "000000000000000000";
--				LEDR(5) <= '1';
				next_state <= "0111";
			when"0111" =>  -- letter
				lcd_rs <= '1'; -- sending an character
				lcd_data <= "01000111";
--				for (i=0; i<32; i=i+1) begin
--					lcd_data <= decrypted_message(i);
--				end
				next_state <= "1000";
			when "1000" =>
				lcd_done <= '1';
				next_state <= "1000";
			when others =>
				next_state <= "0000";
		end case;
	end if;
	end process;

	process (slow_clock, resetb)
	begin
		if (resetb = '1') then
			current_state <= "0000";
--		elsif(screen_counter(6) = '1') then -- clear screen (go to state "0000") when 2^6 characters have been printed
--			current_state <= "0000";
			screen_counter <= (others => '0');
		elsif(rising_edge(slow_clock)) then
			current_state <= next_state;
--			screen_counter <= std_logic_vector(unsigned(screen_counter) + 1); -- increment clear_screen counter
		end if;
	end process;
	
end architecture;