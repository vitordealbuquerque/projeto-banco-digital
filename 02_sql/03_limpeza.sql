-- ============================================================================
-- Script 03/04 - Limpeza, checagens e colunas derivadas
-- Nível: intermediário (CASE, EXTRACT, ALTER TABLE, LEFT JOIN)
-- ============================================================================

SET search_path TO banco_digital, public;

-- ------------------------------------------------------------------
-- 1) NULOS por coluna crítica
-- ------------------------------------------------------------------
SELECT
    SUM(CASE WHEN cliente_id     IS NULL THEN 1 ELSE 0 END) AS null_id,
    SUM(CASE WHEN data_transacao IS NULL THEN 1 ELSE 0 END) AS null_data,
    SUM(CASE WHEN valor          IS NULL THEN 1 ELSE 0 END) AS null_valor,
    SUM(CASE WHEN tipo           IS NULL THEN 1 ELSE 0 END) AS null_tipo
FROM transacoes;

-- ------------------------------------------------------------------
-- 2) Clientes sem nenhuma transação em 2024
-- ------------------------------------------------------------------
SELECT COUNT(*) AS clientes_sem_transacao
FROM clientes c
LEFT JOIN transacoes t ON t.cliente_id = c.cliente_id
WHERE t.transacao_id IS NULL;

-- ------------------------------------------------------------------
-- 3) Valores fora do padrão (outliers)
-- ------------------------------------------------------------------
SELECT
    MIN(valor)                                              AS valor_min,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY valor)     AS valor_p50,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY valor)     AS valor_p95,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY valor)     AS valor_p99,
    MAX(valor)                                              AS valor_max
FROM transacoes;

-- ------------------------------------------------------------------
-- 4) UFs fora do padrão IBGE
-- ------------------------------------------------------------------
SELECT uf, COUNT(*) AS qtd
FROM clientes
WHERE uf NOT IN
     ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MG','MS','MT',
        'PA','PB','PE','PI','PR','RJ','RN','RO','RR','RS','SC','SE','SP','TO')
GROUP BY uf;

-- ------------------------------------------------------------------
-- 5) Colunas derivadas em transacoes
-- ------------------------------------------------------------------
ALTER TABLE transacoes
    ADD COLUMN IF NOT EXISTS ano_mes       CHAR(7),
    ADD COLUMN IF NOT EXISTS dia_semana    SMALLINT,
    ADD COLUMN IF NOT EXISTS faixa_horaria VARCHAR(15),
    ADD COLUMN IF NOT EXISTS is_pix        SMALLINT;

UPDATE transacoes
SET ano_mes       = TO_CHAR(data_transacao, 'YYYY-MM'),
    dia_semana    = EXTRACT(DOW FROM data_transacao)::SMALLINT,
    faixa_horaria = CASE
        WHEN EXTRACT(HOUR FROM data_transacao) BETWEEN 0  AND 5  THEN 'Madrugada'
        WHEN EXTRACT(HOUR FROM data_transacao) BETWEEN 6  AND 11 THEN 'Manhã'
        WHEN EXTRACT(HOUR FROM data_transacao) BETWEEN 12 AND 17 THEN 'Tarde'
        ELSE 'Noite'
    END,
    is_pix = CASE WHEN tipo IN ('PIX_enviado','PIX_recebido') THEN 1 ELSE 0 END;

-- ------------------------------------------------------------------
-- 6) Coluna derivada em clientes: qtd_produtos
-- ------------------------------------------------------------------
ALTER TABLE clientes
    ADD COLUMN IF NOT EXISTS qtd_produtos SMALLINT;

UPDATE clientes c
SET qtd_produtos = sub.n
FROM (
      SELECT cliente_id, COUNT(*) AS n
      FROM produtos_cliente
      GROUP BY cliente_id
  ) sub
WHERE c.cliente_id = sub.cliente_id;

-- ------------------------------------------------------------------
-- 7) Índices extras
-- ------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_txn_ano_mes  ON transacoes(ano_mes);
CREATE INDEX IF NOT EXISTS idx_txn_is_pix   ON transacoes(is_pix);
CREATE INDEX IF NOT EXISTS idx_txn_faixa    ON transacoes(faixa_horaria);
