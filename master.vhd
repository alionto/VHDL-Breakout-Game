
library IEEE;
use work.array_generate.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;


entity master is
    Port (clk : in std_logic;
          reset : in std_logic;
          left : in std_logic;
          start : in std_logic;
          right : in std_logic;
          lvl_sel : in std_logic_vector(1 downto 0);
          left_2 : in std_logic;
          right_2 : in std_logic;
          horz_sync_f : out std_logic;
          vert_sync_f : out std_logic;
          vgaR : out std_logic_vector(2 downto 0);
          vgaG : out std_logic_vector(2 downto 0);
          vgaB : out std_logic_vector(2 downto 0);
          out1 : out std_logic;
          out2: out std_logic;
          out3: out std_logic;
          out4: out std_logic);
end master;


architecture Behavioral of master is
signal block_dimensions            : block_array;
signal visible_block    : std_logic_vector(31 downto 0);
signal platform_pos       : general_array;
signal platform_pos_2 : general_array;
signal ball_pos         : general_array;
signal well_done              : std_logic;
signal game_state            : state := waiting; 

component ball_move
	port(clk                   : in std_logic;
	    start : in std_logic;
		reset                 : in std_logic;
		block_dimensions            : in block_array;
		visible_block         : out std_logic_vector(31 downto 0);
		platform_pos              : in general_array;
		platform_pos_2            : in general_array;
		game_state            : in state;
		ball_pos              : out general_array;
		well_done : out std_logic);
end component;

component platform
     port( clk : in std_logic;
           reset : in std_logic;
           lvl_sel : in std_logic_vector(1 downto 0);
           left : in std_logic;
           right : in std_logic;
           game_state : in state;
           platform_pos : out general_array);
end component;

component platform_2
port( clk : in std_logic;
           reset : in std_logic;
           left_2 : in std_logic;
           lvl_sel : in std_logic_vector(1 downto 0);
           right_2 : in std_logic;
           game_state: in state;
           platform_pos_2 : out general_array);
end component;

component vga_driver
 
	port(clk               : in std_logic;
	     reset : in std_logic;
	     well_done : in std_logic;
	     start : in std_logic;
		game_state         : in state := waiting;
		platform_pos     : in general_array;
		platform_pos_2 : in general_array;
		ball_pos      : in general_array;
		block_dimensions : in block_array;
		visible_block : in std_logic_vector(31 downto 0);
		vgaB : out std_logic_vector(2 downto 0);
		vgaR, vgaG : out std_logic_vector(2 downto 0);
		horz_sync, vert_sync       : out std_logic);
		
end component;
component Blocks
    port(
		clk          : in std_logic;
		LvL_sel : in std_logic_vector(1 downto 0);
		game_state   : in state;
		block_dimensions   : out block_array);
end component;


begin
    platform_info : platform port map (clk => clk,
                                       reset => reset, 
                                       left => left,
                                       lvl_sel => lvl_sel,
                                       right => right,
                                       game_state => game_state, 
                                       platform_pos => platform_pos);
    platform_2_info : platform_2 port map (clk => clk,
                                       reset => reset, 
                                       left_2 => left_2,
                                       lvl_sel => lvl_sel,
                                       right_2 => right_2,
                                       game_state => game_state, 
                                       platform_pos_2 => platform_pos_2);
    ball_info : ball_move port map (clk => clk,
                                    start => start,
		                            block_dimensions => block_dimensions,
		                            visible_block => visible_block,
		                            well_done => well_done,              
                                    reset => reset,
                                    platform_pos => platform_pos,
                                    platform_pos_2 => platform_pos_2,
                                    game_state => game_state,
                                    ball_pos => ball_pos);
    vga : vga_driver port map (clk => clk,
                               reset => reset,
                               start => start,
                               well_done => well_done,
                               block_dimensions => block_dimensions,
                               visible_block => visible_block,
                               game_state => game_state,
                               platform_pos => platform_pos,
                               platform_pos_2 => platform_pos_2,
                               ball_pos => ball_pos,
                               vgaR => vgaR,
                               vgaG => vgaG,
                               vgaB => vgaB,
                               horz_sync => horz_sync_f,
                               vert_sync => vert_sync_f);    
        
        
        Block_info : Blocks port map(clk => clk,
		                             LvL_sel => LvL_sel,
		                             game_state => game_state,
		                             block_dimensions => block_dimensions);                            
--- In the process below, the conditions for the game_state changes are stated ---                    
--- The states are self-explanatory and there are 3 of them ---
--- waiting, started and ended ---                                                 
    process(clk, ball_pos, game_state, left, right)
    begin
        if rising_edge(clk) then
            case game_state is
                when waiting =>
                    if reset = '0' and start = '1' then
                        game_State <= started;
                    elsif reset = '0' and start = '0' then 
                        game_State <= waiting;
                    elsif reset = '1' then
                        game_state <= waiting;
                    end if;
                --- When the ball goes out of bounds, the game ends ---
                when started =>
                    if ((ball_pos(0) >= 480 or ball_pos(2) <= 0) or well_done = '1') then
                        game_state <= ended;
                    elsif reset = '1' then
                        game_State <= waiting;
                    else
                        game_state <= started;
                    end if;
                 
                 when ended =>
                    if reset = '1' then
                        game_state <= waiting;
                    else
                        game_state <= ended;
                    end if;
                 end case;
              end if;
           end process;
    --- These are the LED outputs to indicate the state of the game ---
    --- There are also out3 and out4 which indicate which level the user has selected to play ---
    process(game_state)
        begin
            if game_state = started then
                out1 <= '1';
                out2 <= '0';
            elsif game_state = ended then
                out2 <= '1';
                out1 <= '0';
            else
                out1 <= '0';
                out2 <= '0';
            end if;
        out3 <= lvl_sel(0);   
        out4 <= lvl_sel(1);
    end process;
    
    
    
 

end Behavioral;
