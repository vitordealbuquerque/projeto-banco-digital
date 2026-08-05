# Comportamento de Clientes — Banco Digital

Projeto de portfólio construído em cima de uma base sintética de banco digital brasileiro. A ideia foi reproduzir o fluxo real de um analista: extrair e modelar os dados, tratar e analisar em SQL, depois montar o dashboard final em Power BI.

**Dashboard interativo:** [abrir no Power BI](https://app.powerbi.com/links/U-hvA-o0GN?ctid=61768ab7-be77-4b79-a1d0-ce6799d88483&pbi_source=linkShare)

![Dashboard Comportamento de Clientes - Banco Digital](https://github.com/user-attachments/assets/a555dcf9-3e1b-4c85-b70a-af6778cb16ce)

## A base

2.000 clientes, 5.345 ativações de produto e 25.000 transações ao longo de 2024 (com um resíduo de meses de 2023, que aparece no dashboard como o período de ramp-up da base). Os dados são sintéticos, gerados em Python com distribuição lognormal para os valores, mas o schema, as constraints e as queries são as mesmas que eu usaria numa base real.

## Como o projeto foi montado

**1. Extração e modelagem.** Os dados nasceram como CSV (clientes.csv, produtos_cliente.csv, transacoes.csv) e foram carregados num schema PostgreSQL com três tabelas: clientes (dimensão), produtos_cliente (ponte cliente-produto) e transacoes (fato). Chaves primárias, foreign keys e CHECK constraints garantem a integridade: segmento só pode ser Standard, Plus ou Premium, e tipo de transação é limitado a uma lista fechada de 10 categorias (PIX enviado e recebido, compra crédito e débito, TED, boleto, pagamento de fatura, investimento, recarga, saque).

**2. SQL.** Depois da carga, rodei limpeza (checagem de nulos, outliers, colunas derivadas como ano_mes) e 10 blocos de análise usando CTE, window functions (RANK, LAG, NTILE), PERCENTILE_CONT e FILTER. É onde saem os números de churn, ticket médio e MAU que alimentam o dashboard.

**3. Power BI.** O modelo semântico foi montado direto em cima das tabelas, com as medidas DAX principais (Total Clientes, Churn %, Volume Total, MAU, PIX %) e um tema customizado em tons de verde oliva.

## Estrutura do repositório

O repositório tem duas pastas. Em 02_sql/ ficam os quatro scripts: 01_criar_tabelas.sql (DDL, schema, PKs, FKs, CHECK, índices), 02_carregar_dados.sql (COPY dos CSV), 03_limpeza.sql (nulos, outliers, colunas derivadas) e 04_analises.sql (10 blocos de KPI). Em 06_prints/ fica estrutura_projeto.svg, o diagrama do modelo relacional.

Os prints da execução no PostgreSQL (carga e análise com window functions) e a base completa em CSV entram assim que eu rodar o projeto contra um Postgres real, os scripts em 02_sql/ já estão prontos para isso.

## O que o dashboard mostra

Churn de 12,5%, mais concentrado em clientes vindos de Redes Sociais e Parcerias (Indicação segue com a menor taxa). PIX é o meio mais usado, puxando quase metade do volume de transações. Cross-sell parado em 2,67 produtos por cliente, ainda dá pra empurrar mais Investimentos e Seguros no segmento Standard. MAU sobe de forma consistente ao longo de 2024, depois do ramp-up inicial da base em 2023.

## Rodando localmente

Os scripts rodam em sequência com psql: primeiro 02_sql/01_criar_tabelas.sql, depois 02_sql/02_carregar_dados.sql, 02_sql/03_limpeza.sql e por último 02_sql/04_analises.sql.

## Autor

Vitor Franca — engenheiro civil migrando para análise de dados.
