-- task3_bonus

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Entity part of the description.  Describes inputs and outputs

entity ksa is
  port(CLOCK_50 : in  std_logic;  -- Clock pin
       KEY : in  std_logic_vector(3 downto 0);  -- push button switches
       SW : in  std_logic_vector(17 downto 0);  -- slider switches
		 LEDG : out std_logic_vector(7 downto 0);  -- green lights
		 LEDR : out std_logic_vector(17 downto 0);  -- red lights
		 
		 -- task3_bonus
		 LCD_BLON : out std_logic; -- backlight is always on
		 LCD_ON : out std_logic; -- LCD is always on
		 LCD_EN: out std_logic := '1'; -- connect the clock to the lcd_en input
		 LCD_RW : out std_logic; -- always writing to the LCD
		 LCD_RS : out std_logic := '0';
		 LCD_DATA : out std_logic_vector (7 downto 0));
end ksa;

-- Architecture part of the description

architecture rtl of ksa is

   -- Declare the component for the ram.  This should match the entity description 
	-- in the entity created by the megawizard. If you followed the instructions in the 
	-- handout exactly, it should match.  If not, look at s_memory.vhd and make the
	-- changes to the component below
	
   COMPONENT s_memory IS
	   PORT (
		   address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		   clock		: IN STD_LOGIC  := '1';
		   data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		   wren		: IN STD_LOGIC ;
		   q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
   END component;

	-- Enumerated type for the state variable.  You will likely be adding extra
	-- state names here as you complete your design
	
	type state_type is (state_init, 
                       state_fill,						
   	 					  state_done);
								
    -- These are signals that are used to connect to the memory													 
	 signal address : STD_LOGIC_VECTOR (7 DOWNTO 0);	 
	 signal data : STD_LOGIC_VECTOR (7 DOWNTO 0);
	 signal wren : STD_LOGIC;
	 signal q : STD_LOGIC_VECTOR (7 DOWNTO 0);
	 signal clk : STD_LOGIC;
	
	-- task1 signals
	 type states is (state_init, state_lcd, state_fill, state_wait_1, state_wait_2, state_wait_3, state_wait_4, state_wait_5, state_wait_6, state_wait_7, state_read_i, state_write_i, state_write_j, state_read_j, state_loop3_read_s, state_loop3_read_j, state_loop3_write_i, state_loop3_write_j, state_loop3_read_si, state_loop3_read_sj, state_loop3_read_sij, state_decrypt_write, state_decrypt_read, state_done);
	 signal state : states;
	 signal resetb : STD_LOGIC;
	 
	 -- task2 signals
	 signal secret_key : STD_LOGIC_VECTOR (23 DOWNTO 0) := (others => '0');
	 signal keylength : integer := 3;
	 
	 -- task2b signals
	 signal address_m, address_d : STD_LOGIC_VECTOR (7 DOWNTO 0);	 
	 signal data_d : STD_LOGIC_VECTOR (7 DOWNTO 0);
	 signal wren_d : STD_LOGIC;
	 signal q_m, q_d : STD_LOGIC_VECTOR (7 DOWNTO 0);
	 
	 -- task2b components
	 COMPONENT message IS
		PORT
		(
			address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			clock		: IN STD_LOGIC  := '1';
			q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
		);
	 END COMPONENT;
	 
	 COMPONENT decrypted IS
		PORT
		(
			address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			clock		: IN STD_LOGIC  := '1';
			data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			wren		: IN STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
		);
	 END COMPONENT;
	 
	 -- task3_bonus signals
	 signal slow_clock : STD_LOGIC;
	 signal current_state, next_state : std_logic_vector(3 downto 0) := "0000";
	 signal counter: std_logic_vector (25 downto 0) := (others => '0');
	 signal lcd_start, lcd_done : std_logic := '0';
	 signal i : unsigned(5 downto 0) := "000000";
	 signal j : unsigned(6 downto 0) := "0000000";
	 
	 type MEM is array(0 to 255) of STD_LOGIC_VECTOR(7 DOWNTO 0);
	 signal decrypted_message : MEM;

	 begin
	    -- Include the S memory structurally
	
       u0: s_memory port map (
	        address, clk, data, wren, q);
		 
		 -- Include E memory structurally
		 
		 u1: message port map (
		     address_m, clk, q_m);
		 
		 -- Include E memory structurally
		 u2: decrypted port map (
		     address_d, clk, data_d, wren_d, q_d);
		 
		 clk <= CLOCK_50;
		 resetb <= not KEY(3);

		 -- task3
		 LEDR <= secret_key (23 downto 6);
		 LEDG(7 downto 2) <= secret_key (5 downto 0);

		 LCD_BLON <= '1'; -- backlight is always on
		 LCD_ON <= '1'; -- LCD is always on
		 LCD_RW <= '0'; -- always writing to the LCD
		 LCD_EN <= slow_clock;
		 
	process (clk, resetb, lcd_done)
	variable i : integer;
	variable j, x, k : integer;
	variable upper, lower, ascii : integer;
	variable f, mem_a, mem_b : STD_LOGIC_VECTOR (7 downto 0);
	begin
		if resetb = '1' then
			state <= state_init;
			secret_key <= (others=>'0');
		elsif rising_edge(clk) then
			case state is
				when state_init =>
					i := 0;
					j := 0;
					upper := 0;
					lower := 0;
					k := 0;
					mem_a := "00000000";
					mem_b := "00000000";
					f := "00000000";
					decrypted_message <= (others=>(others=>'0'));
					wren_d <= '0';
					state <= state_fill;
					wren <= '1';
					wren_d <= '1';
					lcd_start <= '0';
					LEDG(1 downto 0) <= "00";
					
				when state_fill =>
					address <= std_logic_vector(to_unsigned(i,8));
					data <= std_logic_vector(to_unsigned(i,8));
					
					wren <= '1';
					i := i + 1;
					if i = 256 then
						state <= state_read_i;
						i := 0;
					end if;
				when state_read_i =>
					
					address <= std_logic_vector(to_unsigned(i,8)); -- read from memory at location i
					
					wren <= '0';
					state <= state_wait_1;
					
				when state_wait_1 =>
					
					state <= state_read_j;
					
				when state_read_j =>
					mem_a := q; -- get data from read at address in state_read_i
					
					if i mod keylength = 0 then
						upper := 23;
						lower := 16;
						x := to_integer(unsigned(secret_key( upper downto lower)));
					elsif i mod keylength = 1 then
						upper := 15;
						lower := 8;
						x := to_integer(unsigned(secret_key( upper downto lower)));
						
					else
						upper := 7;
						lower := 0;
						x := to_integer(unsigned(secret_key( upper downto lower)));
					end if;
					
					
					j := (j + to_integer(unsigned(mem_a)) + x) mod 256;
					-- read s[j]
					address <= std_logic_vector(to_unsigned(j,8));
					
					state <= state_wait_2;
					
				when state_wait_2 =>
					
					wren <= '1';
					state <= state_write_i;
					
				when state_write_i =>
					
					wren <= '1';
					mem_b := q;
					
					address <= std_logic_vector(to_unsigned(i,8));
					data <= mem_b;
					
					
					state <= state_write_j;
					
				when state_write_j =>
					
					address <= std_logic_vector(to_unsigned(j,8));
					data <= mem_a;
					
					i := i + 1;
					if i = 256 then
						state <= state_loop3_read_s;
						i := 0;
						j := 0;
					else
						state <= state_read_i;
					end if;
				
				when state_loop3_read_s =>
				
					wren <= '0';
					i := (i+1) mod 256;
					
					address <= std_logic_vector(to_unsigned(i,8));
					
					state <= state_wait_3;
				when state_wait_3 =>
					
					wren <= '0';
					state <= state_loop3_read_j;
					
				when state_loop3_read_j =>
					
					wren <= '0';
					mem_a := q;
					j := (j + to_integer(unsigned(mem_a))) mod 256;
					
					address <= std_logic_vector(to_unsigned(j,8));
					
					state <= state_wait_4;
					
				when state_wait_4 =>
					
					wren <= '1';
					state <= state_loop3_write_i;
					
				when state_loop3_write_i => -- perform swap/write
					
					mem_b := q;
					
					address <= std_logic_vector(to_unsigned(i,8));
					data <= mem_b;
					
					state <= state_loop3_write_j;
					
				when state_loop3_write_j => -- perform swap/write
					
					address <= std_logic_vector(to_unsigned(j,8));
					data <= mem_a;
					
					state <= state_wait_5;
				when state_wait_5 =>
					
					wren <= '0';
					state <= state_loop3_read_si;
				when state_loop3_read_si => 
					
					address <= std_logic_vector(to_unsigned(i,8));
					
					state <= state_loop3_read_sj;
				when state_loop3_read_sj => 
				
					address <= std_logic_vector(to_unsigned(j,8));
					mem_b := q;
					state <= state_loop3_read_sij;
					
				when state_loop3_read_sij =>
					
					mem_a := q;
					address <= std_logic_vector(to_unsigned(to_integer(unsigned(mem_a) + unsigned(mem_b)) mod 256,8));
					
					state <= state_wait_6;
					
				when state_wait_6 =>
				
					state <= state_decrypt_read;
					address_m <= std_logic_vector(to_unsigned(k,8));
					
				when state_decrypt_read =>
					
					state <= state_wait_7;

				when state_wait_7 =>
				
					state <= state_decrypt_write;
				when state_decrypt_write =>
					
					f := q;
					
					address_d <= std_logic_vector(to_unsigned(k,8));
					data_d <= f xor q_m;
					decrypted_message(k) <= f xor q_m;
					ascii := to_integer(unsigned(f xor q_m));

					k := k + 1;
					if k = 32 then
						state <= state_lcd;
						lcd_start <= '1';
						LEDG(0) <= '1'; -- success
					else
						if ( (ascii < 97 or ascii > 122) and  ascii /= 32) then
							secret_key <= std_logic_vector(unsigned(secret_key) + 1);
							state <= state_init;
						elsif ( secret_key(22) = '1') then
--							-- failed
							state <= state_done;
						else
							state <= state_loop3_read_s;
						end if;
					end if;
				
				when state_lcd =>
					
					lcd_start <= '1';
					if (lcd_done = '1') then
						state <= state_done;
					else
						state <= state_lcd;
					end if;
					
				when state_done =>
					LEDG(1) <= '1'; -- done
					state <= state_done;
					wren <= '0';
			end case;
		end if;
	end process;
	
	CLOCK_SLOWDOWN: process (CLOCK_50, lcd_start, state)
	begin
		if (rising_edge(CLOCK_50) and state = state_lcd) then
			-- for a 1Hz clock we need 50Mhz divided by a number between 2^25 and 2^26) ~ 0.75s - 1.49s	
			if (counter(21) = '1') then -- counter a total of 2^26 times at 50 MHz before triggering clk (slowed down clocked)
				slow_clock <= '1';
				counter <= (others => '0'); -- reset all 2^26 counter bits to 0
			else
				slow_clock <= '0';
				counter <= std_logic_vector(unsigned(counter) + 1);
			end if;
		end if;
	end process;


	NEXTE_LOGIC : process (current_state, lcd_start)
	begin
		lcd_done <= '0';
		case current_state is
			when "0000" =>
				lcd_rs <= '0'; -- sending an instruction
				lcd_data <= "00111000";
				next_state <= "0001";

			when "0001" =>
				lcd_rs <= '0'; -- sending an instruction
				lcd_data <= "00111000";
				next_state <= "0010";
				
			when "0010" =>
				lcd_rs <= '0'; -- sending an instruction
				lcd_data <= "00001100";
				next_state <= "0011";
				
			when "0011" =>
				lcd_rs <= '0'; -- sending an instruction
				lcd_data <= "00000001";
				next_state <= "0100";
				
			when"0100" =>
				lcd_rs <= '0'; -- sending an instruction
				lcd_data <= "00000110";
				next_state <= "0101";
				
			when"0101" =>
				lcd_rs <= '0'; -- sending an instruction
				lcd_data <= "10000000";
				next_state <= "0111";
				
			when"0111" =>  -- letter
				lcd_rs <= '1'; -- sending an character				
				if i(5) = '1' then
					next_state <= "1000";
				else
					lcd_data <= decrypted_message(to_integer(i));
					next_state <= "0111";
				end if;
				
			when "1000" =>
				lcd_rs <= '0';
				lcd_data <= "00000000";
				lcd_done <= '1';
				next_state <= "1000";
				
			when others =>
				lcd_rs <= '0';
				lcd_data <= "00000000";
				next_state <= "0000";				
		end case;
	end process;

	process (slow_clock, resetb)
	begin
		if (resetb = '1') then
			current_state <= "0000";
			i <= "000000";
			j <= "0000000";
		elsif(falling_edge(slow_clock)) then
			current_state <= next_state;
			if current_state = "0111" then
				if to_integer(j) < 15 or to_integer(j) >= 39 then
					i <= i + 1;
				end if;
				j <= j + 1;
			end if;
		end if;
	end process;
end rtl;


