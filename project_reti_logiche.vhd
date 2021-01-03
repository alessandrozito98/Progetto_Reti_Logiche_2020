----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.12.2020 15:41:45
-- Design Name: 
-- Module Name: top_level - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project_reti_logiche is
    port (
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_start : in std_logic;
    i_data : in std_logic_vector(7 downto 0);
    o_address : out std_logic_vector(15 downto 0);
    o_done : out std_logic;
    o_en : out std_logic;
    o_we : out std_logic;
    o_data : out std_logic_vector (7 downto 0)
);

end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

    type state is (RESET,
                   LEGGIRIGA,                   
                   LEGGICOLONNA,
                   CALCOLONBIT,
                   CALCOLOMAXEMIN,
                   READPIXEL,
                   CALCOLOSHIFT_LEVEL,
                   READPIXELVALUE,
                   CALCOLONEWPIXELVALUE,
                   SHIFTNEWPIXELVALUE,
                   WRITEPIXELVALUE,
                   WAIT_READ,
                   FINALIZE);
                   
  signal  curr_state      :      state ;
  signal  loop_sig        :      std_logic := '0';
  signal  number_of_byte :       std_logic_vector(15 downto 0);
  signal  count :                std_logic_vector(15 downto 0);
  signal  helper :               std_logic_vector(7 downto 0);
  signal  test :                 std_logic_vector(7 downto 0);
  signal  min_pixel_value :      std_logic_vector(7 downto 0);
  signal  max_pixel_value :      std_logic_vector(7 downto 0);
  signal delta_value :           std_logic_vector(7 downto 0);
  signal temp_value :            std_logic_vector(7 downto 0);
  signal new_pixel_value:        std_logic_vector(15 downto 0);
  signal shift_level :           std_logic_vector(7 downto 0);
  signal current_address:        std_logic_vector(7 downto 0);
  
begin

        
    
    UNIQUE_PROCESS : process(i_clk)
    begin
    
        if i_clk'event and i_clk = '0' then
        
            if i_rst = '1' then
    
                -- stato attuale della macchina a stati
                curr_state <= RESET;            
                
            else        
        case curr_state is
            when RESET      =>  
                                o_en        <= '0';
                                o_we        <= '0';
                                o_data <= "00000000";
                                o_done      <= '0';
                                curr_state <= RESET;
                                current_address <= "00000010";
                                o_address <= "0000000000000000";
                                count <= "0000000000000000";
                                max_pixel_value <= "00000000";
                                shift_level <= "00000000";
                                if i_start = '1' then
                                o_en <= '1';
                                curr_state <= LEGGIRIGA;
                                end if;
                               


            when LEGGIRIGA   => helper <= i_data;
                                o_address <= "0000000000000001";
                                curr_state <= LEGGICOLONNA;                                
                                
            when LEGGICOLONNA   => temp_value <= i_data; 
                                   o_address <= "0000000000000010";
                                   curr_state <=CALCOLONBIT;
                                    
            when CALCOLONBIT=>    number_of_byte <=std_logic_vector(unsigned(helper) * unsigned(temp_value));   
                                  curr_state <= CALCOLOMAXEMIN;
                             
       
             when CALCOLOMAXEMIN   =>     if(count = number_of_byte)then
                                          count <= "0000000000000010";
                                          delta_value <= std_logic_vector(unsigned(max_pixel_value)-unsigned(min_pixel_value));
                                          curr_state  <= CALCOLOSHIFT_LEVEL;
                                          else
                                          if(count = "00000000") then
                                          min_pixel_value <=  i_data;
                                          max_pixel_value <=  i_data;
                                          else
                                          if(temp_value>max_pixel_value) then
                                          max_pixel_value <=  temp_value; 
                                          elsif( temp_value<min_pixel_value) then
                                          min_pixel_value <=  temp_value;
                                          end if;
                                          end if;
                                          o_address <=  count + 3;
                                          curr_state <= READPIXEL;  
                                          end if;                                                                             
              when READPIXEL            => count <= count +1 ;
                                           temp_value <= i_data;                  
                                           curr_state <= CALCOLOMAXEMIN; 
              
              when CALCOLOSHIFT_LEVEL   => if(delta_value = 0) then
                                           shift_level  <= "00000000";
                                           o_address <= "0000000000000010";
                                           count <= (others => '0');
                                           curr_state <= READPIXELVALUE;
                                           else
                                           if( count < delta_value+1 )then
                                           shift_level<=shift_level+1;     
                                           count <= count + count;
                                           curr_state <= CALCOLOSHIFT_LEVEL;
                                           else
                                           shift_level<=8-shift_level;
                                           count <= (others => '0');
                                           o_address <= "0000000000000010";
                                           curr_state <= READPIXELVALUE;
                                           end if;
                                           end if;
                                           
               when READPIXELVALUE        => 
                                             if(count = number_of_byte) then
                                             curr_state <= FINALIZE;
                                             else
                                             temp_value<= i_data;
                                             curr_state <= CALCOLONEWPIXELVALUE;
                                             end if;                            
               
               
               
               when CALCOLONEWPIXELVALUE  => new_pixel_value <= "00000000" & (temp_value-min_pixel_value);
                                             curr_state <= SHIFTNEWPIXELVALUE; 
                                         
                                         
               when SHIFTNEWPIXELVALUE  =>
                                             new_pixel_value <=std_logic_vector(unsigned(shift_left(unsigned(new_pixel_value),to_integer(unsigned(shift_level)))));
                                             o_address <= count + 2 + number_of_byte;                      
                                             o_we<='1';
                                             curr_state <= WRITEPIXELVALUE;

                                             
               when WRITEPIXELVALUE     =>   if(new_pixel_value < 255) then
                                             o_data <= std_logic_vector(RESIZE(unsigned(new_pixel_value), 8));
                                             else
                                             o_data <=  "11111111";
                                             end if; 
                                             curr_state <= WAIT_READ;
                                             
                                             
                                             
                                             
                                             
               when WAIT_READ           =>   o_we<='0';
                                             o_address <=count + 3; 
                                             count <= count + 1;      
                                             curr_state <= READPIXELVALUE;
               
                                                        
                when FINALIZE               => 
                                               if(i_start='0') then
                                               o_done <= '1';
                                               curr_state <= RESET;
                                               else
                                                   o_done <= '1';
                                                   o_we <= '0';
                                               end if;                                                               
            end case;
     end if;
     end if;
     
     end process;

end Behavioral;