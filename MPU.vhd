library IEEE;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity MPU is
    Port (
        ce_n, we_n, oe_n : in std_logic;        -- Sinais de controle
        intr            : out std_logic;        -- Sinal de interrupção
        address         : in std_logic_vector(15 downto 0);  -- Endereço de 16 bits
        data            : inout std_logic_vector(15 downto 0) -- Dados de 16 bits
    );
end MPU;

architecture Behavioral of MPU is
    -- Definição das matrizes A, B, C
    type matrix is array (0 to 3, 0 to 3) of std_logic_vector(15 downto 0);  -- Exemplo de matrizes 4x4
    signal A, B, C : matrix := (others => (others => (others => '0')));
    signal cmd_reg : std_logic_vector(15 downto 0) := (others => '0'); -- Registro de comando

    -- Variáveis auxiliares para armazenar o endereço atual
    signal addr_row, addr_col : integer range 0 to 3; -- Endereços de linha e coluna
    signal done : std_logic := '0';  -- Sinal de conclusão
    signal command_executed : boolean := false; -- Para indicar que o comando foi executado
begin
    process (ce_n, we_n, oe_n, address)
    begin
        if ce_n = '0' then  -- Chip habilitado
            -- Decodificar o endereço em linhas e colunas
            addr_row <= to_integer(unsigned(address(3 downto 2))); -- Exemplo de decodificação simples
            addr_col <= to_integer(unsigned(address(1 downto 0)));

            if we_n = '0' then -- Escrever dado
                if address = "0000000000001111" then  -- Endereço de comandos
                    cmd_reg <= data; -- Escreve o comando
                elsif address(15 downto 4) = "0001" then  -- Matriz A
                    A(addr_row, addr_col) <= data; 
                elsif address(15 downto 4) = "0010" then  -- Matriz B
                    B(addr_row, addr_col) <= data; 
                elsif address(15 downto 4) = "0011" then  -- Matriz C (se necessário escrever)
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

        -- Execução dos comandos da MPU
        if cmd_reg = "0001" then  -- Comando ADD
            for i in 0 to 3 loop
                for j in 0 to 3 loop
                    C(i, j) <= A(i, j) + B(i, j); -- Soma das matrizes
                end loop;
            end loop;
            done <= '1'; -- Operação concluída
        elsif cmd_reg = "0010" then  -- Comando SUB
            for i in 0 to 3 loop
                for j in 0 to 3 loop
                    C(i, j) <= A(i, j) - B(i, j); -- Subtração das matrizes
                end loop;
            end loop;
            done <= '1'; -- Operação concluída
        elsif cmd_reg = "0011" then  -- Comando MUL
            for i in 0 to 3 loop
                for j in 0 to 3 loop
                    C(i, j) <= A(i, j) * B(i, j); -- Multiplicação das matrizes
                end loop;
            end loop;
            done <= '1'; -- Operação concluída
        elsif cmd_reg = "0100" then  -- Comando MAC
            for i in 0 to 3 loop
                for j in 0 to 3 loop
                    C(i, j) <= C(i, j) + A(i, j) * B(i, j); -- Produto acumulado
                end loop;
            end loop;
            done <= '1'; -- Operação concluída
        elsif cmd_reg = "0101" then  -- Comando FILL
            for i in 0 to 3 loop
                for j in 0 to 3 loop
                    C(i, j) <= data; -- Preenche a matriz com o valor dado
                end loop;
            end loop;
            done <= '1'; -- Operação concluída
        elsif cmd_reg = "0110" then  -- Comando IDENTITY
            for i in 0 to 3 loop
                for j in 0 to 3 loop
                    if i = j then
                        C(i, j) <= "0000000000000001"; -- Matriz identidade
                    else
                        C(i, j) <= "0000000000000000"; -- Zeros fora da diagonal
                    end if;
                end loop;
            end loop;
            done <= '1'; -- Operação concluída
        end if;
    end process;

    -- Interrupção é levantada quando o comando é concluído
    intr <= done;

end Behavioral;
