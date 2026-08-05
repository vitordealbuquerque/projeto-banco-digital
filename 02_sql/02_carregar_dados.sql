-- ============================================================================
-- Script 02/04 - Carga dos CSV
-- Rodar via psql (necessário pro \COPY)
-- ============================================================================

SET search_path TO banco_digital, public;

-- Ajuste o caminho para onde estão os CSV no seu computador.
\COPY clientes         FROM '03_dados/clientes.csv'         WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8', NULL '');
\COPY produtos_cliente FROM '03_dados/produtos_cliente.csv'  WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8');
\COPY transacoes       FROM '03_dados/transacoes.csv'        WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8', NULL '');

-- Verificação de carga
SELECT 'clientes'         AS tabela, COUNT(*) AS linhas FROM clientes
UNION ALL
SELECT 'produtos_cliente'  AS tabela, COUNT(*) AS linhas FROM produtos_cliente
UNION ALL
SELECT 'transacoes'        AS tabela, COUNT(*) AS linhas FROM transacoes;

-- Esperado:
-- clientes         : 2000
-- produtos_cliente : 5345
-- transacoes       : 25000
