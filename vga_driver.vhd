
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.array_generate.all;

entity vga_driver is
	port(clk               : in std_logic;
	     start : in std_logic;
	     reset : in std_logic;
	     well_done : in std_logic;
		game_state         : in state := waiting;
		platform_pos     : in general_array;
		platform_pos_2 : in general_array;
		ball_pos      : in general_array;
		block_dimensions : in block_array;
		visible_block : in std_logic_vector(31 downto 0);
		vgaR,vgaB,vgaG : out std_logic_vector(2 downto 0);
		horz_sync, vert_sync       : out std_logic);
		
end vga_driver;

architecture Behavioral of vga_driver is
--- For this project, a 800*525 screen was used including the non-visible areas ---
--- The display area is 640*480 with a pixel frequency of approx. 25 Mhz ---
signal vert_sync_width : integer := 2;
signal horz_sync_width : integer := 96;
signal vert_BP : integer := 33;
signal vert_FP : integer := 10;
signal horz_BP : integer := 48;
signal horz_FP : integer := 16;
signal   horz_pos : integer range 0 to 800  := 0;
signal	vert_pos : integer range 0 to 525 := 0;
signal vga_clk : std_logic;
signal vga_clk_conv_1 : std_logic;
signal vga_clk_conv_2 : std_logic;
signal temp_clk : std_logic;
signal display_on : std_logic;
begin
    --- In these two processes, the standard 100 MHz clock of the Basys3 is converted to a 25 MHz vga clock ---
	process(clk, temp_clk) is
	begin
		if rising_edge(clk) then
            temp_clk <= not temp_clk;
        end if;
        vga_clk_conv_1 <= temp_clk;
    end process;    
    process(vga_clk_conv_1, vga_clk_conv_2) is
    begin
        if rising_edge(vga_clk_conv_1) then
            vga_clk_conv_2 <= not vga_clk_conv_2;                
        end if;    
	    vga_clk <= vga_clk_conv_2;
	end process;
	
    --- The horizontal pixels are scanned ---
    horz_pos_counter:process(vga_clk, reset) is
    begin
        if reset = '1' then
            horz_pos <= 0;
            
        elsif rising_edge(vga_clk) then
            if horz_pos < 800 then
                horz_pos <= horz_pos + 1;
            else 
                horz_pos <= 0;
            end if;
        end if;
     end process;
    
    --- The vertical pixels are scanned ---
     vert_pos_counter:process(vga_clk, reset, horz_pos) is
    begin
        if reset = '1' then
            vert_pos <= 0;
            
        elsif rising_edge(vga_clk) then
            if horz_pos = 800 then
                if vert_pos < 525 then
                    vert_pos <= vert_pos + 1;
                else 
                    vert_pos <= 0;
            end if;
        end if;
        end if;
     end process;
     
    --- In this process, the visible area of the screen is isolated for further use ---,
    --- Display_on '1' when the pixel scan is on the visible area, '0' otherwise ---
     process(vga_clk, reset, horz_pos, vert_pos, display_on)
     begin
        if (reset = '1') then
            display_on <= '0';
        elsif rising_edge(vga_clk) then
            if horz_pos >= 0 and horz_pos <= 800 - horz_FP - horz_BP - horz_sync_width
                and vert_pos >= 0 and vert_pos <= 525 - vert_FP - vert_FP - vert_sync_width then
                display_on <= '1';
            else
                display_on <= '0';
            end if;
        end if;
     end process;
     --- In this process, the synchronization of the vga display is implemented ---
     --- Check out the xilinx website for more info about the vga display ---
     process(vert_pos, horz_pos, platform_pos, platform_pos_2, ball_pos, vga_clk) 
     begin
        if rising_edge(vga_clk) then
            if reset = '1' then
                vert_sync <= '0';
                horz_sync <= '0';
            else
                if vert_pos < 525 - vert_FP and vert_pos >= 480 + vert_BP then
                    vert_sync <= '1';
                else
                    vert_sync <= '0';
                end if;
                if horz_pos < 800 - horz_FP and horz_pos >= 640 + horz_BP then
                    horz_sync <= '1';
                else
                    horz_sync <= '0';
                end if;
            end if;
       --- After all the components are implemented, the objects in our game are coloured ---         
       if game_state = started and display_on = '1' then
            if (horz_pos >=  platform_pos(1) and horz_pos <=  platform_pos(3)) and
                    (vert_pos >=  platform_pos(0) and vert_pos <= platform_pos(2)) then
                vgaR <= "111";
                vgaG <= "000";
                vgaB <= "000";
            elsif (horz_pos >=  platform_pos_2(1) and horz_pos <=  platform_pos_2(3)) and
                    (vert_pos >=  platform_pos_2(0) and vert_pos <=  platform_pos_2(2)) then
                vgaR <= "111";
                vgaG <= "000";
                vgaB <= "000";
            elsif (horz_pos >=  ball_pos(1) and horz_pos <=  ball_pos(3)) and
                    (vert_pos >=  ball_pos(0) and vert_pos <= ball_pos(2)) then
                vgaR <= "000";
                vgaG <= "111";
                vgaB <= "000";
            elsif visible_block(0) = '1' and vert_pos >= block_dimensions(0)(0) and vert_pos <= block_dimensions(0)(2) and
                        horz_pos >= block_dimensions(0)(1) and horz_pos <= block_dimensions(0)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(1) = '1' and vert_pos >= block_dimensions(1)(0) and vert_pos <= block_dimensions(1)(2) and
                        horz_pos >= block_dimensions(1)(1) and horz_pos <= block_dimensions(1)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
             elsif visible_block(2) = '1' and vert_pos >= block_dimensions(2)(0) and vert_pos <= block_dimensions(2)(2) and
                        horz_pos >= block_dimensions(2)(1) and horz_pos <= block_dimensions(2)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            
            elsif visible_block(3) = '1' and vert_pos >= block_dimensions(3)(0) and vert_pos <= block_dimensions(3)(2) and
                        horz_pos >= block_dimensions(3)(1) and horz_pos <= block_dimensions(3)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(4) = '1' and vert_pos >= block_dimensions(4)(0) and vert_pos <= block_dimensions(4)(2) and
                        horz_pos >= block_dimensions(4)(1) and horz_pos <= block_dimensions(4)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
             elsif visible_block(5) = '1' and vert_pos >= block_dimensions(5)(0) and vert_pos <= block_dimensions(5)(2) and
                        horz_pos >= block_dimensions(5)(1) and horz_pos <= block_dimensions(5)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(6) = '1' and vert_pos >= block_dimensions(6)(0) and vert_pos <= block_dimensions(6)(2) and
                        horz_pos >= block_dimensions(6)(1) and horz_pos <= block_dimensions(6)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";        
            elsif visible_block(7) = '1' and vert_pos >= block_dimensions(7)(0) and vert_pos <= block_dimensions(7)(2) and
                        horz_pos >= block_dimensions(7)(1) and horz_pos <= block_dimensions(7)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(8) = '1' and vert_pos >= block_dimensions(8)(0) and vert_pos <= block_dimensions(8)(2) and
                        horz_pos >= block_dimensions(8)(1) and horz_pos <= block_dimensions(8)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
             elsif visible_block(9) = '1' and vert_pos >= block_dimensions(9)(0) and vert_pos <= block_dimensions(9)(2) and
                        horz_pos >= block_dimensions(9)(1) and horz_pos <= block_dimensions(9)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(10) = '1' and vert_pos >= block_dimensions(10)(0) and vert_pos <= block_dimensions(10)(2) and
                        horz_pos >= block_dimensions(10)(1) and horz_pos <= block_dimensions(10)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(11) = '1' and vert_pos >= block_dimensions(11)(0) and vert_pos <= block_dimensions(11)(2) and
                        horz_pos >= block_dimensions(11)(1) and horz_pos <= block_dimensions(11)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(12) = '1' and vert_pos >= block_dimensions(12)(0) and vert_pos <= block_dimensions(12)(2) and
                        horz_pos >= block_dimensions(12)(1) and horz_pos <= block_dimensions(12)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
             elsif visible_block(13) = '1' and vert_pos >= block_dimensions(13)(0) and vert_pos <= block_dimensions(13)(2) and
                        horz_pos >= block_dimensions(13)(1) and horz_pos <= block_dimensions(13)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(14) = '1' and vert_pos >= block_dimensions(14)(0) and vert_pos <= block_dimensions(14)(2) and
                        horz_pos >= block_dimensions(14)(1) and horz_pos <= block_dimensions(14)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";        
             elsif visible_block(15) = '1' and vert_pos >= block_dimensions(15)(0) and vert_pos <= block_dimensions(15)(2) and
                        horz_pos >= block_dimensions(15)(1) and horz_pos <= block_dimensions(15)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(16) = '1' and vert_pos >= block_dimensions(16)(0) and vert_pos <= block_dimensions(16)(2) and
                        horz_pos >= block_dimensions(16)(1) and horz_pos <= block_dimensions(16)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
             elsif visible_block(17) = '1' and vert_pos >= block_dimensions(17)(0) and vert_pos <= block_dimensions(17)(2) and
                        horz_pos >= block_dimensions(17)(1) and horz_pos <= block_dimensions(17)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(18) = '1' and vert_pos >= block_dimensions(18)(0) and vert_pos <= block_dimensions(18)(2) and
                        horz_pos >= block_dimensions(18)(1) and horz_pos <= block_dimensions(18)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(19) = '1' and vert_pos >= block_dimensions(19)(0) and vert_pos <= block_dimensions(19)(2) and
                        horz_pos >= block_dimensions(19)(1) and horz_pos <= block_dimensions(19)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(20) = '1' and vert_pos >= block_dimensions(20)(0) and vert_pos <= block_dimensions(20)(2) and
                        horz_pos >= block_dimensions(20)(1) and horz_pos <= block_dimensions(20)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
             elsif visible_block(21) = '1' and vert_pos >= block_dimensions(21)(0) and vert_pos <= block_dimensions(21)(2) and
                        horz_pos >= block_dimensions(21)(1) and horz_pos <= block_dimensions(21)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(22) = '1' and vert_pos >= block_dimensions(22)(0) and vert_pos <= block_dimensions(22)(2) and
                        horz_pos >= block_dimensions(22)(1) and horz_pos <= block_dimensions(22)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";        
            elsif visible_block(23) = '1' and vert_pos >= block_dimensions(23)(0) and vert_pos <= block_dimensions(23)(2) and
                        horz_pos >= block_dimensions(23)(1) and horz_pos <= block_dimensions(23)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(24) = '1' and vert_pos >= block_dimensions(24)(0) and vert_pos <= block_dimensions(24)(2) and
                        horz_pos >= block_dimensions(24)(1) and horz_pos <= block_dimensions(24)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
             elsif visible_block(25) = '1' and vert_pos >= block_dimensions(25)(0) and vert_pos <= block_dimensions(25)(2) and
                        horz_pos >= block_dimensions(25)(1) and horz_pos <= block_dimensions(25)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(26) = '1' and vert_pos >= block_dimensions(26)(0) and vert_pos <= block_dimensions(26)(2) and
                        horz_pos >= block_dimensions(26)(1) and horz_pos <= block_dimensions(26)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(27) = '1' and vert_pos >= block_dimensions(27)(0) and vert_pos <= block_dimensions(27)(2) and
                        horz_pos >= block_dimensions(27)(1) and horz_pos <= block_dimensions(27)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(28) = '1' and vert_pos >= block_dimensions(28)(0) and vert_pos <= block_dimensions(28)(2) and
                        horz_pos >= block_dimensions(28)(1) and horz_pos <= block_dimensions(28)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
             elsif visible_block(29) = '1' and vert_pos >= block_dimensions(29)(0) and vert_pos <= block_dimensions(29)(2) and
                        horz_pos >= block_dimensions(29)(1) and horz_pos <= block_dimensions(29)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            elsif visible_block(30) = '1' and vert_pos >= block_dimensions(30)(0) and vert_pos <= block_dimensions(30)(2) and
                        horz_pos >= block_dimensions(30)(1) and horz_pos <= block_dimensions(30)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";                 
            elsif visible_block(31) = '1' and vert_pos >= block_dimensions(31)(0) and vert_pos <= block_dimensions(31)(2) and
                        horz_pos >= block_dimensions(31)(1) and horz_pos <= block_dimensions(31)(3) then
                        vgaR <= "000";
                        vgaG <= "111";
                        vgaB <= "111";
            else
                    vgaR <= "000";
                    vgaG <= "000";
                    vgaB <= "000";
                
            end if;
            --- This is the entrance screen to the game ---
       elsif display_on = '1' and game_state = waiting then
            if start = '0' then
                if  (horz_pos >= 80 and horz_pos <= 160 and vert_pos >= 160 and vert_pos <= 180) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 60 and horz_pos <= 80 and vert_pos >= 180 and vert_pos <= 200) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 80 and horz_pos <= 160 and vert_pos >= 200 and vert_pos <= 220) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 160 and horz_pos <= 180 and vert_pos >= 220 and vert_pos <= 240) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 80 and horz_pos <= 160 and vert_pos >= 240 and vert_pos <= 260) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 200 and horz_pos <= 260 and vert_pos >= 160 and vert_pos <= 180) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 220 and horz_pos <= 240 and vert_pos >= 180 and vert_pos <= 260) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 280 and horz_pos <= 300 and vert_pos >= 180 and vert_pos <= 260) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 300 and horz_pos <= 320 and vert_pos >= 160 and vert_pos <= 180) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 300 and horz_pos <= 320 and vert_pos >= 200 and vert_pos <= 220) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 320 and horz_pos <= 340 and vert_pos >= 180 and vert_pos <= 260) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 380 and horz_pos <= 400 and vert_pos >= 160 and vert_pos <= 260) then
                       vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 400 and horz_pos <= 440 and vert_pos >= 160 and vert_pos <= 180) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 400 and horz_pos <= 440 and vert_pos >= 200 and vert_pos <= 220) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 440 and horz_pos <= 460 and vert_pos >= 220 and vert_pos <= 260) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 440 and horz_pos <= 460 and vert_pos >= 180 and vert_pos <= 200) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 480 and horz_pos <= 540 and vert_pos >= 160 and vert_pos <= 180) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 500 and horz_pos <= 520 and vert_pos >= 180 and vert_pos <= 260) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                elsif (horz_pos >= 580 and horz_pos <= 600 and vert_pos >= 200 and vert_pos <= 220) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
                 else
                        vgaR <= "000";
                        vgaG <= "000";
                        vgaB <= "000";
                end if;
            end if;
            --- When the game is lost and the ball is out of bounds, the screen coded below appears ---
       elsif display_on = '1' and game_state = ended then
            if well_done = '0' then
                if (horz_pos >= 220 and horz_pos <= 240 and vert_pos >= 160 and vert_pos <= 240) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 240 and horz_pos <= 280 and vert_pos >= 140 and vert_pos <= 160) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 280 and horz_pos <= 300 and vert_pos >= 160 and vert_pos <= 180) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 260 and horz_pos <= 300 and vert_pos >= 200 and vert_pos <= 220) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 280 and horz_pos <= 300 and vert_pos >= 220 and vert_pos <= 240) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 240 and horz_pos <= 280 and vert_pos >= 240 and vert_pos <= 260) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 340 and horz_pos <= 360 and vert_pos >= 160 and vert_pos <= 240) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 360 and horz_pos <= 400 and vert_pos >= 140 and vert_pos <= 160) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 400 and horz_pos <= 420 and vert_pos >= 160 and vert_pos <= 180) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 380 and horz_pos <= 420 and vert_pos >= 200 and vert_pos <= 220) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 400 and horz_pos <= 420 and vert_pos >= 220 and vert_pos <= 240) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 360 and horz_pos <= 400 and vert_pos >= 240 and vert_pos <= 260) then
                         vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";

                else
                         vgaR <= "000";
                        vgaG <= "000";
                        vgaB <= "000";
             end if;
             --- When the game is won, the coded screen below appears ---
            else
                if (horz_pos >= 200 and horz_pos <= 220 and vert_pos >= 120 and vert_pos <= 240) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 220 and horz_pos <= 240 and vert_pos >= 240 and vert_pos <= 260) then 
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 240 and horz_pos <= 260 and vert_pos >= 180 and vert_pos <= 240) then 
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 260 and horz_pos <= 280 and vert_pos >= 240 and vert_pos <= 260) then 
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 280 and horz_pos <= 300 and vert_pos >= 120 and vert_pos <= 240) then 
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 340 and horz_pos <= 360 and vert_pos >= 120 and vert_pos <= 260) then 
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 360 and horz_pos <= 420 and vert_pos >= 120 and vert_pos <= 140) then 
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 420 and horz_pos <= 440 and vert_pos >= 140 and vert_pos <= 180) then 
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";
               elsif (horz_pos >= 360 and horz_pos <= 420 and vert_pos >= 180 and vert_pos <= 200) then
                        vgaR <= "111";
                        vgaG <= "111";
                        vgaB <= "111";

                else
                        vgaR <= "000";
                        vgaG <= "000";
                        vgaB <= "000";
             end if;
            end if;
         end if;
       end if;
    end process;
       
    end behavioral;     
            
       
    