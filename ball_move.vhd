
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use work.array_generate.all;
entity ball_move is
	port(clk                   : in std_logic;
		reset                 : in std_logic;
		start : in std_logic;
		block_dimensions            : in block_array;
		visible_block         : out std_logic_vector(31 downto 0);
		platform_pos              : in general_array;
		platform_pos_2            : in general_array;
		game_state            : in state;
		ball_pos              : out general_array;
		well_done : out std_logic);

		
end ball_move;
--- Temp_block_list signal is to list and indicate which blocks have been broken ---
architecture behavioral of ball_move is
signal width            : integer := 6;
signal counter_stop          : integer := 500000;
signal counter              : integer := 0;
signal temp_block_list : std_logic_vector(31 downto 0) := (others => '1');
signal vert_speed            : integer := 1;
signal horz_speed             : integer := -1;
signal pos_x               : integer := 600 - width / 2;
signal pos_y               : integer := 60;


--- The counter is created to adjust the speed of the ball ---
begin
    process(clk)
        begin
            if rising_edge(clk) then
                if game_state = started then
                    if counter >= counter_stop then
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if;
                end if;
            end if; 
     end process;   
     
     process (clk, counter, pos_x , pos_y, platform_pos, platform_pos_2)
     begin
        if rising_edge(clk) then
            --- The initial position and speed of the ball is set ---
            if game_state /= started and reset = '1' then
                pos_x <= 600 - width / 2;
                pos_y <= 60;
            --- All the blocks are set as unbroken when the game is reset ---
                temp_block_list <= (others => '1');
                vert_speed <= -1;
                horz_speed <= 1;
            end if;
            --- Now, the ball starts moving ---
            if game_state = started and start = '1' then

            if counter = 0 then
                --- When the ball does not interact with any object ---
                pos_x <= pos_x + horz_speed;
                pos_y <= pos_y + vert_speed;

            elsif counter = 1 then
                --- When the ball interacts with the walls on the right and left hand side ---
                if (pos_x = 0 or pos_x + width = 640) then
                    pos_x <= pos_x - horz_speed;
                    pos_y <= pos_y + vert_speed;
                    horz_speed <= -horz_speed;
                    
                end if;

            elsif counter = 2 then
                --- When the ball interacts with the platform ---
                if (platform_pos(0) = pos_y + width and platform_pos(1) <= pos_x + 5 and platform_pos(3) + 5 >= pos_x + width) then
                    pos_x <= pos_x + horz_speed;
                    pos_y <= pos_y - vert_speed;
                    vert_speed <= -vert_speed;
                    
                end if;
 
            elsif counter = 3 then
                --- When the ball interacts with the platform ---
                if (platform_pos_2(2) = pos_y and platform_pos_2(1) <= pos_x + 5 and platform_pos_2(3) + 5 >= pos_x + width) then
                    
                    pos_x <= pos_x + horz_speed;
                    pos_y <= pos_y - vert_speed;
                    vert_speed <= -vert_speed;
                end if;
            --- When the ball interacts with the blocks ---
            elsif counter = 4 then
                for k in 0 to 31 loop
                     if temp_block_list(k) = '1' and pos_x + width = block_dimensions(k)(1) and (pos_y + width > block_dimensions(k)(0) and pos_y < block_dimensions(k)(2)) then
                             pos_x <= pos_x - horz_speed;
                             pos_y <= pos_y + vert_speed;
                             horz_speed <= -horz_speed;
                             temp_block_list(k) <= '0';
                     elsif temp_block_list(k) = '1' and pos_y + width = block_dimensions(k)(0) and pos_x + width > block_dimensions(k)(1) and pos_x < block_dimensions(k)(3) then
                             pos_x <= pos_x + horz_speed;
                             pos_y <= pos_y - vert_speed;
                             vert_speed <= -vert_speed;
                             temp_block_list(k) <= '0';
                     elsif temp_block_list(k) = '1' and pos_y = block_dimensions(k)(2) and pos_x + width > block_dimensions(k)(1) and pos_x < block_dimensions(k)(3) then
                             pos_x <= pos_x + horz_speed;
                             pos_y <= pos_y - vert_speed;
                             vert_speed <= -vert_speed;
                             temp_block_list(k) <= '0';
                     elsif temp_block_list(k) = '1' and pos_x = block_dimensions(k)(3) and (pos_y + width > block_dimensions(k)(0) and pos_y < block_dimensions(k)(2)) then  
                             pos_x <= pos_x - horz_speed;
                             pos_y <= pos_y + vert_speed;
                             horz_speed <= -horz_speed; 
                             temp_block_list(k) <= '0';
                     elsif temp_block_list(k) = '1' and ((pos_x + width = block_dimensions(k)(1) and (pos_y + width = block_dimensions(k)(0) or pos_y = block_dimensions(k)(2)))
                                or (pos_x = block_dimensions(k)(3) and (pos_y + width = block_dimensions(k)(0) or pos_y = block_dimensions(k)(2)))) then
                             pos_x <= pos_x - horz_speed;
                             pos_y <= pos_y - vert_speed;
                             horz_speed <= -horz_speed;
                             vert_speed <= -vert_speed;
                             temp_block_list(k) <= '0';
                     end if;
                     end loop;
                end if;             
                end if;          
            end if;
     end process;
    --- In this process, we can see that when all the bricks are broken and all the bits are '0' on the temp_block_list ---
    --- When all the bits are '0', the game is won and when they are not all broken, the game continues ---
    end_game: process(temp_block_list)
    begin
        if temp_block_list = "00000000000000000000000000000000" then
            well_done <= '1';
        else
            well_done <= '0';
        end if;
        --- Border pixel positions of the ball ---
        ball_pos(0) <= pos_y;
	    ball_pos(1) <= pos_x;
	    ball_pos(2) <= pos_y + width;
	    ball_pos(3) <= pos_x + width;
    end process;
    visible_block <= temp_block_list;
    
    
 end behavioral;    

