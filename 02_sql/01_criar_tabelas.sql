-- ============================================================================
-- PROJETO: Comportamento de Clientes — Banco Digital (Brasil, 2024)
-- Script 01/04 - DDL: schema, dimensões, fato, índices, constraints
-- PostgreSQL 15+
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS banco_digital;
SET search_path TO banco_digital, public;

-- --------------------------------------------------------------------------
-- Dimensão: clientes
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS transacoes       CASCADE;
DROP TABLE IF EXISTS produtos_cliente CASCADE;
DROP TABLE IF EXISTS clientes         CASCADE;

CREATE TABLE clientes (
      cliente_id       INTEGER      PRIMARY KEY,
      idade            SMALLINT     NOT NULL CHECK (idade BETWEEN 18 AND 100),
      genero           CHAR(1)      NOT NULL CHECK (genero IN ('M','F')),
      uf               CHAR(2)      NOT NULL,
      renda_mensal     NUMERIC(10,2) CHECK (renda_mensal > 0),
      segmento         VARCHAR(10)  NOT NULL
          CHECK (segmento IN ('Standard','Plus','Premium')),
      data_cadastro    DATE         NOT NULL,
      canal_aquisicao  VARCHAR(30)  NOT NULL,
      status           VARCHAR(10)  NOT NULL
          CHECK (status IN ('Ativo','Inativo','Churned')),
      data_churn       DATE
  );

COMMENT ON TABLE  clientes              IS 'Base de clientes do banco digital';
COMMENT ON COLUMN clientes.segmento     IS 'Standard < R$4k | Plus R$4-10k | Premium > R$10k';
COMMENT ON COLUMN clientes.data_churn   IS 'Preenchido somente quando status = Churned';

-- --------------------------------------------------------------------------
-- Ponte: produtos por cliente
-- --------------------------------------------------------------------------
CREATE TABLE produtos_cliente (
      registro_id      SERIAL       PRIMARY KEY,
      cliente_id       INTEGER      NOT NULL REFERENCES clientes(cliente_id),
      produto          VARCHAR(30)  NOT NULL
          CHECK (produto IN ('Conta Digital','Cartão Débito','Cartão Crédito',
                             'Investimentos','Seguros','Empréstimo Pessoal')),
      data_ativacao    DATE         NOT NULL,
      status_produto   VARCHAR(15)  NOT NULL
          CHECK (status_produto IN ('Ativo','Cancelado'))
  );

-- --------------------------------------------------------------------------
-- Fato: transações
-- --------------------------------------------------------------------------
CREATE TABLE transacoes (
      transacao_id     BIGINT       PRIMARY KEY,
      cliente_id       INTEGER      NOT NULL REFERENCES clientes(cliente_id),
      tipo             VARCHAR(20)  NOT NULL
          CHECK (tipo IN ('PIX_enviado','PIX_recebido','Compra_Credito',
                          'Compra_Debito','TED','Boleto','Pagamento_Fatura',
                          'Investimento','Recarga','Saque')),
      data_transacao   TIMESTAMP    NOT NULL,
      valor            NUMERIC(10,2) CHECK (valor > 0),
      categoria        VARCHAR(30)
  );

COMMENT ON TABLE  transacoes                IS 'Transações financeiras 2024';
COMMENT ON COLUMN transacoes.categoria      IS 'Preenchido somente em compras (crédito/débito)';

-- Índices para acelerar análises
CREATE INDEX idx_txn_cliente     ON transacoes(cliente_id);
CREATE INDEX idx_txn_tipo        ON transacoes(tipo);
CREATE INDEX idx_txn_data        ON transacoes(data_transacao);
CREATE INDEX idx_cli_status      ON clientes(status);
CREATE INDEX idx_cli_segmento    ON clientes(segmento);
CREATE INDEX idx_cli_uf          ON clientes(uf);
CREATE INDEX idx_prod_cliente    ON produtos_cliente(cliente_id);
CREATE INDEX idx_prod_produto    ON produtos_cliente(produto);
