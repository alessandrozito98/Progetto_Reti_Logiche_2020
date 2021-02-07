----------------------------------------------------------------------------------
-- Company: Polytechnic University of Milan
-- Engineer: Giuseppe Serra (10566090 / 887630) // Alessandro Zito (10617579 / 890219)
-- Instuctor/Supervisor: Prof. Gianluca Palermo
--
-- Project Name: Prova Finale - Progetto di Reti Logiche
--
-- Description: The specification of the Final Test (Project of Logic Networks) 2020 is inspired by the method of
-- equalization of the histogram of an image.
--
-- 
----------------------------------------------------------------------------------
LIBRARY IEEE;
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


ENTITY project_reti_logiche IS
	PORT
	(
		i_clk : IN std_logic;
		i_rst : IN std_logic;
		i_start : IN std_logic;
		i_data : IN std_logic_vector(7 DOWNTO 0);
		o_address : OUT std_logic_vector(15 DOWNTO 0);
		o_done : OUT std_logic;
		o_en : OUT std_logic;
		o_we : OUT std_logic;
		o_data : OUT std_logic_vector (7 DOWNTO 0)
	);
END project_reti_logiche;


ARCHITECTURE Behavioral OF project_reti_logiche IS
	TYPE fsm_state IS (RESET,
	IDLING,
	READ_ROW,
	READ_COLUMN,
	SET_NUMBER_OF_PIXEL,
	SET_MAX_AND_MIN,
	READ_PIXEL,
	SET_SHIFT_LEVEL,
	READ_PIXEL_VALUE,
	SET_NEW_PIXEL_VALUE,
	SHIFT_NEW_PIXEL_VALUE,
	WRITE_NEW_PIXEL_VALUE,
	WAIT_READ,
	FINALIZE);
	
	
	SIGNAL curr_state : fsm_state;
	SIGNAL loop_sig : std_logic := '0';
	SIGNAL number_of_byte : std_logic_vector(15 DOWNTO 0);
	SIGNAL count : std_logic_vector(15 DOWNTO 0);
	SIGNAL helper : std_logic_vector(7 DOWNTO 0);
	SIGNAL min_pixel_value : std_logic_vector(7 DOWNTO 0);
	SIGNAL max_pixel_value : std_logic_vector(7 DOWNTO 0);
	SIGNAL delta_value : std_logic_vector(8 DOWNTO 0);
	SIGNAL temp_value : std_logic_vector(7 DOWNTO 0);
	SIGNAL new_pixel_value : std_logic_vector(15 DOWNTO 0);
	SIGNAL shift_level : std_logic_vector(7 DOWNTO 0);
	SIGNAL current_address : std_logic_vector(7 DOWNTO 0);
	
	
BEGIN
	UNIQUE_PROCESS : PROCESS (i_clk)
	BEGIN
		IF i_clk'EVENT AND i_clk = '0' THEN
			IF i_rst = '1' THEN
				-- stato attuale della macchina a stati
				curr_state <= RESET;
			ELSE
				CASE curr_state IS
				
				
					WHEN RESET =>
						o_en <= '0';
						o_we <= '0';
						o_data <= "00000000";
						o_done <= '0';
						curr_state <= RESET;
						current_address <= "00000010";
						o_address <= "0000000000000000";
						count <= "0000000000000000";
						max_pixel_value <= "00000000";
						shift_level <= "00000000";
						curr_state <= IDLING;
						
						
					WHEN IDLING =>
					    IF i_start = '1' THEN
							o_en <= '1';
							curr_state <= READ_ROW;
						END IF;
						
						
					WHEN READ_ROW =>
						helper <= i_data;
						o_address <= "0000000000000001";
						curr_state <= READ_COLUMN;
						
						
					WHEN READ_COLUMN =>
						temp_value <= i_data;
						o_address <= "0000000000000010";
						curr_state <= SET_NUMBER_OF_PIXEL;
						
						
					WHEN SET_NUMBER_OF_PIXEL =>
						number_of_byte <= std_logic_vector(unsigned(helper) * unsigned(temp_value));
						curr_state <= SET_MAX_AND_MIN;
						
						
					WHEN SET_MAX_AND_MIN =>
						IF (count = number_of_byte) THEN
							count <= "0000000000000010";
							delta_value <= "0" & std_logic_vector(unsigned(max_pixel_value) - unsigned(min_pixel_value));
							curr_state <= SET_SHIFT_LEVEL;
						ELSE
							IF (count = "00000000") THEN
								min_pixel_value <= i_data;
								max_pixel_value <= i_data;
							ELSE
								IF (temp_value > max_pixel_value) THEN
									max_pixel_value <= temp_value;
								ELSIF (temp_value < min_pixel_value) THEN
									min_pixel_value <= temp_value;
								END IF;
							END IF;
							o_address <= count + 3;
							curr_state <= READ_PIXEL;
						END IF;
						
						
					WHEN READ_PIXEL =>
						count <= count + 1;
						temp_value <= i_data;
						curr_state <= SET_MAX_AND_MIN;
						
						
					WHEN SET_SHIFT_LEVEL =>
						IF (delta_value = 0) THEN
							shift_level <= "00000000";
							o_address <= "0000000000000010";
							count <= (OTHERS => '0');
							curr_state <= READ_PIXEL_VALUE;
						ELSE
							IF (count <= delta_value + 1) THEN
								shift_level <= shift_level + 1;
								count <= count + count;
								curr_state <= SET_SHIFT_LEVEL;
							ELSE
								shift_level <= 8 - shift_level;
								count <= (OTHERS => '0');
								o_address <= "0000000000000010";
								curr_state <= READ_PIXEL_VALUE;
							END IF;
						END IF;
						
						
					WHEN READ_PIXEL_VALUE =>
						IF (count = number_of_byte) THEN
						    o_done <= '1';
							curr_state <= FINALIZE;
						ELSE
							temp_value <= i_data;
							curr_state <= SET_NEW_PIXEL_VALUE;
						END IF;
						
						
					WHEN SET_NEW_PIXEL_VALUE =>
						new_pixel_value <= "00000000" & (temp_value - min_pixel_value);
						curr_state <= SHIFT_NEW_PIXEL_VALUE;
						
						
					WHEN SHIFT_NEW_PIXEL_VALUE =>
						new_pixel_value <= std_logic_vector(unsigned(shift_left(unsigned(new_pixel_value), to_integer(unsigned(shift_level)))));
						o_address <= count + 2 + number_of_byte;
						o_we <= '1';
						curr_state <= WRITE_NEW_PIXEL_VALUE;
						
						
					WHEN WRITE_NEW_PIXEL_VALUE =>
						IF (new_pixel_value < 255) THEN
							o_data <= std_logic_vector(RESIZE(unsigned(new_pixel_value), 8));
						ELSE
							o_data <= "11111111";
						END IF;
						curr_state <= WAIT_READ;
						
						
					WHEN WAIT_READ =>
						o_we <= '0';
						o_address <= count + 3;
						count <= count + 1;
						curr_state <= READ_PIXEL_VALUE;
						
						
					WHEN FINALIZE =>
						IF (i_start = '0') THEN
							o_done <= '0';
							o_en <= '0';
							curr_state <= RESET;
						ELSE
							o_done <= '0';
							o_we <= '0';
						END IF;
				END CASE;
				
			END IF;
			
		END IF;
		
	END PROCESS;
	
END Behavioral;
