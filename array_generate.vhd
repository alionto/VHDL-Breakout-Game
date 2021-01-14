library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--- This small package is generated to colour and display objects with ease ---
--- The states of the game is also implemented in this package ---
package array_generate is
    type general_array is array(3 downto 0) of integer;
    type block_array is array (integer range 31 downto 0) of general_array;
    type state is (waiting, started, ended);

end array_generate;
