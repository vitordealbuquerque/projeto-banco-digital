# Análise de Comportamento de Clientes: Criando um Dashboard de Banco Digital do Zero

## Requisitos e Configurações do Projeto

### 1. Pré-requisitos de Software (Ambiente Local)

- PostgreSQL 15 ou superior
- - Power BI Desktop
  - - Python 3 (usado para gerar a base sintética)
    - - Dados utilizados: base sintética gerada em Python, disponível em 03_dados/ (clientes.csv, produtos_cliente.csv, transacoes.csv)
     
      - ### 2. Fundamentos das Tecnologias
     
      - - PostgreSQL - Conceitos Fundamentais (schema, constraints, CTE, window functions)
        - - Power BI - Conceitos Fundamentais (modelo semântico, medidas DAX, relacionamentos)
          - - Modelagem Relacional - Fundamentos (tabela dimensão, tabela fato, chaves primária e estrangeira)
            - - Dataset - Informações: 2.000 clientes, 5.345 ativações de produto e 25.000 transações ao longo de 2024
             
              - ## Principais Conceitos de Dados Utilizados
             
              - **Schema**
              - Um schema é um namespace dentro do banco de dados que agrupa tabelas relacionadas. Neste projeto, todas as tabelas vivem no schema banco_digital.
             
              - **Tabela dimensão**
              - É a tabela que descreve quem ou o que, no projeto, clientes é a dimensão: idade, segmento, canal de aquisição, status.
             
              - **Tabela fato**
              - É a tabela que registra eventos, geralmente em grande volume. transacoes é a fato do projeto: cada linha é uma transação financeira.
             
              - **PK (Primary Key)**
              - PK é a chave primária de uma tabela, um identificador único para cada registro. cliente_id é a PK de clientes.
             
              - **FK (Foreign Key)**
              - FK é a chave estrangeira, o campo que referencia a PK de outra tabela e garante a integridade entre elas. cliente_id em transacoes é FK para clientes.
             
              - **CHECK constraint**
              - É uma regra aplicada direto na coluna do banco que rejeita valores fora de uma lista ou intervalo definido. No projeto, garante que segmento só aceite Standard, Plus ou Premium.
             
              - **CTE (Common Table Expression)**
              - Uma CTE é uma tabela temporária criada dentro de uma query usando WITH, usada para organizar consultas complexas em blocos legíveis.
             
              - **Window Functions**
              - São funções que calculam um valor sobre um conjunto de linhas relacionado à linha atual, sem agrupar o resultado. No projeto, usei RANK, LAG e NTILE para ranquear clientes, comparar meses e criar faixas.
             
              - **PERCENTILE_CONT**
              - Função que calcula um percentil contínuo sobre um conjunto de valores, usada para entender a distribuição do ticket médio.
             
              - **FILTER (cláusula SQL)**
              - Permite aplicar uma condição dentro de uma função de agregação, calculando, por exemplo, uma soma condicional sem precisar de subquery separada.
             
              - **Churn**
              - É a taxa de clientes que deixaram de usar o produto num período. No projeto, churn é medido pela proporção de clientes com status Churned.
             
              - **MAU (Monthly Active Users)**
              - Número de clientes distintos que fizeram ao menos uma transação num determinado mês.
             
              - **Ticket médio**
              - Valor médio das transações de um cliente ou grupo de clientes.
             
              - **Cross-sell**
              - Estratégia de vender produtos adicionais para quem já é cliente. No projeto, medido pela média de produtos ativos por cliente.
             
              - **Medida DAX**
              - No Power BI, uma medida é um cálculo definido em DAX (linguagem de fórmulas do Power BI) que agrega dados sob demanda, como Churn % = DIVIDE([Clientes Churned], [Total Clientes]).
             
              - **Modelo semântico**
              - É a camada do Power BI onde ficam as tabelas, relacionamentos e medidas, a base sobre a qual os gráficos do dashboard são construídos.
             
              - ---

              Vitor Franca
              
