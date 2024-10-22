library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Biblioteca recomendada para conversões e operações numéricas

entity MPU is
    Port (
        ce_n, we_n, oe_n : in std_logic;
        intr            : out std_logic;
        address         : in std_logic_vector(15 downto 0);
        data            : inout std_logic_vector(15 downto 0)
    );
end MPU;

architecture Behavioral of MPU is
    -- Definição das matrizes A, B, C
    type matrix is array (0 to 3, 0 to 3) of std_logic_vector(15 downto 0);  -- Matrizes de 4x4
    signal A, B, C : matrix := (others => (others => (others => '0')));
    signal cmd_reg : std_logic_vector(15 downto 0) := (others => '0');

    signal addr_row, addr_col : integer range 0 to 3;
    signal done : std_logic := '0';
begin
    process (ce_n, we_n, oe_n, address)
    begin
        if ce_n = '0' then  -- Chip habilitado
            -- Decodificação do endereço em linhas e colunas
            addr_row <= to_integer(unsigned(address(3 downto 2))); -- Converte std_logic_vector para unsigned
            addr_col <= to_integer(unsigned(address(1 downto 0)));

            if we_n = '0' then -- Escrever dado
                if address = "0000000000001111" then  -- Endereço de comandos
                    cmd_reg <= data;
                elsif address(15 downto 4) = "0001" then  -- Matriz A
                    A(addr_row, addr_col) <= data; 
                elsif address(15 downto 4) = "0010" then  -- Matriz B
                    B(addr_row, addr_col) <= data; 
                elsif address(15 downto 4) = "0011" then  -- Matriz C
                    C(addr_row, addr_col) <= data; 
                end if;
            elsif oe_n = '0' then -- Ler dado
                if address(15 downto 4) = "0001" then  -- Ler da matriz A
                    data <= A(addr_row, addr_col); 
                elsif address(15 downto 4) = "0010" then  -- Ler da matriz B
                    data <= B(addr_row, addr_col);
                elsif address(15 downto 4) = "0011" then  -- Ler da matriz C
                    data <= C(addr_row, addr_col); 
                end if;
            end if;
        end if;

        -- Execução dos comandos
        if cmd_reg = "0001" then  -- Comando ADD
            for i in 0 to 3 loop
                for j in 0 to 3 loop
                    -- Converte std_logic_vector para unsigned, faz a soma, e converte de volta para std_logic_vector
                    C(i, j) <= std_logic_vector(unsigned(A(i, j)) + unsigned(B(i, j)));
                end loop;
            end loop;
            done <= '1'; -- Operação concluída
        elsif cmd_reg = "0010" then  -- Comando SUB
            for i in 0 to 3 loop
                for j in 0 to 3 loop
                    -- Converte std_logic_vector para unsigned, faz a subtração, e converte de volta
                    C(i, j) <= std_logic_vector(unsigned(A(i, j)) - unsigned(B(i, j)));
                end loop;
            end loop;
            done <= '1'; -- Operação concluída
        end if;
    end process;

    -- Interrupção é levantada quando o comando é concluído
    intr <= done;

end Behavioral;
