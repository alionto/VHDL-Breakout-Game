

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use work.array_generate.all;
entity platform_2 is
     port( clk : in std_logic;
           Lvl_sel : in std_logic_vector(1 downto 0);
           reset : in std_logic;
           left_2 : in std_logic;
           right_2 : in std_logic;
           game_state: in state;
           platform_pos_2 : out general_array);
end platform_2;

architecture Behavioral of platform_2 is
--- pos_y and pos_x refer to the position of the pixels on the y and x axis respectively --- 
signal pos_y : integer := 0; 
signal border_x : integer := 640;
signal platform_width : integer := 120;
signal platform_height : integer := 10;
signal clkspeed : integer := 400000;
signal pos_x : integer;
signal platform_clk : std_logic := '0';
signal counter : integer := 0;


begin
--- This process makes the width of the platform smaller as the levels progress ---
process(lvl_sel, platform_width)
    begin
    if rising_edge(clk) and game_state = waiting then
    case lvl_sel is
        when "00" => 
            platform_width <= 120;
        when "01" =>
            platform_width <= 100;
        when "10" =>
            platform_width <= 80;
        when others =>
            platform_width <= 60;
        end case;
    end if;
 end process;
         
    --- This process is implemented to adjust the speed of the movement of the platform ---
    platform_clk_gen : process(clk)
    begin
        if rising_edge(clk) then
            if counter = clkspeed then
                counter <= 0;
                platform_clk <= not platform_clk;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
    
    --- In this process, the movement of the platform is implemented ---
    movement : process(left_2, right_2, platform_clk)
    begin
        if rising_edge(platform_clk) then
            if game_state /= started and reset = '1' then
                pos_x <= 640 - platform_width;
            end if;
            if game_state = started and left_2 = '1' and pos_x > 5 then
                pos_x <= pos_x - 5;
            elsif game_state = started and right_2 = '1' and pos_x + platform_width < border_x - 5 then
                pos_x <= pos_x + 5;
            end if;
        end if;
        --- Border pixel positions of the platform ---
        platform_pos_2(0) <= pos_y ;
        platform_pos_2(1) <= pos_x;
        platform_pos_2(2) <= pos_y + platform_height;
        platform_pos_2(3) <= pos_x + platform_width;
     end process;
     


end Behavioral;