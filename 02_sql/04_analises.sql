-- ============================================================================
-- Script 04/04 - Análises intermediárias
-- Usa: CTE, window functions (RANK/LAG/NTILE), PERCENTILE_CONT, FILTER
-- Cada bloco alimenta um card ou visual do dashboard.
-- ============================================================================

SET search_path TO banco_digital, public;

-- ============================================================================
-- KPI 1 — Panorama executivo
-- ============================================================================
SELECT
    COUNT(DISTINCT c.cliente_id)                                          AS total_clientes,
    COUNT(DISTINCT c.cliente_id) FILTER (WHERE c.status = 'Ativo')        AS clientes_ativos,
    COUNT(DISTINCT c.cliente_id) FILTER (WHERE c.status = 'Churned')      AS churned,
    ROUND(100.0 * COUNT(DISTINCT c.cliente_id) FILTER (WHERE c.status = 'Churned')
                  / COUNT(DISTINCT c.cliente_id), 2)                        AS churn_rate,
    COUNT(t.transacao_id)                                                AS total_txns,
    ROUND(SUM(t.valor)::numeric, 2)                                      AS volume_total,
    ROUND(AVG(t.valor)::numeric, 2)                                      AS ticket_medio
FROM clientes c
LEFT JOIN transacoes t ON t.cliente_id = c.cliente_id;

-- ============================================================================
-- KPI 2 — Volume transacional por tipo (PIX domina?)
-- ============================================================================
SELECT
    tipo,
    COUNT(*)                                          AS transacoes,
    ROUND(SUM(valor)::numeric, 2)                     AS volume,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_volume,
    ROUND(AVG(valor)::numeric, 2)                     AS ticket_medio
FROM transacoes
GROUP BY tipo
ORDER BY transacoes DESC;

-- ============================================================================
-- KPI 3 — Evolução mensal de MAU e volume (com LAG pra MoM)
-- ============================================================================
WITH mensal AS (
      SELECT
          ano_mes,
          COUNT(DISTINCT cliente_id)   AS mau,
          COUNT(*)                     AS txns,
          ROUND(SUM(valor)::numeric,2) AS volume
      FROM transacoes
      GROUP BY ano_mes
  )
SELECT
    ano_mes,
    mau,
    txns,
    volume,
    LAG(mau)    OVER (ORDER BY ano_mes)                                        AS mau_ant,
    ROUND(100.0*(mau - LAG(mau) OVER (ORDER BY ano_mes))
                / NULLIF(LAG(mau) OVER (ORDER BY ano_mes), 0), 2)               AS crescimento_mau_pct,
    ROUND(100.0*(volume - LAG(volume) OVER (ORDER BY ano_mes))
                / NULLIF(LAG(volume) OVER (ORDER BY ano_mes), 0), 2)            AS crescimento_vol_pct
FROM mensal
ORDER BY ano_mes;

-- ============================================================================
-- KPI 4 — Churn por segmento e canal
-- ============================================================================
SELECT
    segmento,
    canal_aquisicao,
    COUNT(*)                                                    AS clientes,
    COUNT(*) FILTER (WHERE status = 'Churned')                   AS churned,
    ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'Churned')
                  / COUNT(*), 2)                                  AS churn_rate
FROM clientes
GROUP BY segmento, canal_aquisicao
ORDER BY churn_rate DESC;

-- ============================================================================
-- KPI 5 — Adoção de produtos (cross-sell rate)
-- ============================================================================
SELECT
    produto,
    COUNT(*)                                                AS total_ativacoes,
    COUNT(*) FILTER (WHERE status_produto = 'Ativo')         AS ativos,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT cliente_id) FROM clientes), 2)
                                                            AS penetracao_pct
FROM produtos_cliente
GROUP BY produto
ORDER BY total_ativacoes DESC;

-- ============================================================================
-- KPI 6 — Ranking UFs por volume (RANK + share %)
-- ============================================================================
WITH uf_stats AS (
      SELECT
          c.uf,
          COUNT(DISTINCT c.cliente_id)     AS clientes,
          COUNT(t.transacao_id)            AS txns,
          ROUND(SUM(t.valor)::numeric, 2)  AS volume
      FROM clientes c
      JOIN transacoes t ON t.cliente_id = c.cliente_id
      GROUP BY c.uf
  )
SELECT
    uf,
    clientes,
    txns,
    volume,
    RANK() OVER (ORDER BY volume DESC)                          AS rank_volume,
    ROUND(100.0 * volume / SUM(volume) OVER (), 2)              AS share_pct
FROM uf_stats
ORDER BY volume DESC
LIMIT 10;

-- ============================================================================
-- KPI 7 — Perfil demográfico: idade × segmento × churn
-- ============================================================================
WITH faixas AS (
      SELECT *,
          CASE
              WHEN idade BETWEEN 18 AND 24 THEN '18-24'
              WHEN idade BETWEEN 25 AND 34 THEN '25-34'
              WHEN idade BETWEEN 35 AND 44 THEN '35-44'
              WHEN idade BETWEEN 45 AND 54 THEN '45-54'
              ELSE '55+'
          END AS faixa_etaria
      FROM clientes
  )
SELECT
    faixa_etaria,
    segmento,
    COUNT(*)                                             AS clientes,
    COUNT(*) FILTER (WHERE status = 'Churned')            AS churned,
    ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'Churned')
                  / COUNT(*), 2)                           AS churn_rate,
    ROUND(AVG(renda_mensal)::numeric, 2)                  AS renda_media
FROM faixas
GROUP BY faixa_etaria, segmento
ORDER BY faixa_etaria, segmento;

-- ============================================================================
-- KPI 8 — Faixa horária: quando os clientes transacionam
-- ============================================================================
SELECT
    faixa_horaria,
    COUNT(*)                                              AS txns,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)    AS pct,
    ROUND(SUM(valor)::numeric, 2)                         AS volume,
    ROUND(AVG(valor)::numeric, 2)                         AS ticket_medio
FROM transacoes
GROUP BY faixa_horaria
ORDER BY txns DESC;

-- ============================================================================
-- KPI 9 — Top 10 clientes por volume (NTILE pra quartil)
-- ============================================================================
WITH cli_vol AS (
      SELECT
          c.cliente_id,
          c.segmento,
          c.uf,
          COUNT(t.transacao_id)            AS txns,
          ROUND(SUM(t.valor)::numeric, 2)  AS volume
      FROM clientes c
      JOIN transacoes t ON t.cliente_id = c.cliente_id
      GROUP BY c.cliente_id, c.segmento, c.uf
  )
SELECT
    cliente_id,
    segmento,
    uf,
    txns,
    volume,
    NTILE(4) OVER (ORDER BY volume DESC) AS quartil
FROM cli_vol
ORDER BY volume DESC
LIMIT 10;

-- ============================================================================
-- KPI 10 — Percentis de valor por tipo de transação
-- ============================================================================
SELECT
    tipo,
    COUNT(*)                                                            AS n,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY valor)::numeric, 2) AS p50,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY valor)::numeric, 2) AS p90,
    ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY valor)::numeric, 2) AS p99,
    ROUND(MAX(valor)::numeric, 2)                                        AS max_valor
FROM transacoes
GROUP BY tipo
ORDER BY p50 DESC;
