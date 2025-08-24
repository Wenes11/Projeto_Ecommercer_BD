-- =============================================================
-- E‑COMMERCE (MySQL 8+) — SCHEMA PROFISSIONAL + DADOS + QUERIES
-- Inclui: PK/FK, índices, CHECK, ENUM, views, CTEs, janelas,
-- HAVING, CASE, parâmetros simulados e procedure de exemplo.
-- =============================================================

-- ⚠️ Execução segura para recomeçar do zero
DROP DATABASE IF EXISTS ecommerce;
CREATE DATABASE ecommerce;
USE ecommerce;

-- =============================================================
-- 1) TABELAS BASE
-- =============================================================

-- CLIENTE
CREATE TABLE cliente (
    id_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    cpf CHAR(11) UNIQUE,
    email VARCHAR(120),
    endereco VARCHAR(150),
    cidade VARCHAR(60),
    pais VARCHAR(60),
    data_nascimento DATE NOT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- CATEGORIA DE PRODUTO (dimensão simples)
CREATE TABLE categoria (
    id_categoria INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(60) NOT NULL UNIQUE
);

-- PRODUTO
CREATE TABLE produto (
    id_produto INT PRIMARY KEY AUTO_INCREMENT,
    id_categoria INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    quantidade_estoque INT NOT NULL DEFAULT 0 CHECK (quantidade_estoque >= 0),
    preco DECIMAL(10,2) NOT NULL CHECK (preco >= 0),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_produto_categoria FOREIGN KEY (id_categoria)
      REFERENCES categoria(id_categoria)
      ON UPDATE CASCADE
);

-- VENDEDOR (seller/loja do marketplace)
CREATE TABLE vendedor (
    id_vendedor INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    cnpj CHAR(14) UNIQUE,
    endereco VARCHAR(100),
    telefone VARCHAR(20),
    avaliacao DECIMAL(2,1) CHECK (avaliacao >= 0 AND avaliacao <= 5)
);

-- FORNECEDOR (B2B)
CREATE TABLE fornecedor (
    id_fornecedor INT PRIMARY KEY AUTO_INCREMENT,
    razao_social VARCHAR(100) NOT NULL,
    cnpj CHAR(14) UNIQUE,
    estoque_produto INT DEFAULT 0 CHECK (estoque_produto >= 0)
);

-- Relacionamento Vendedor <-> Fornecedor (N:N)
CREATE TABLE vendedor_fornecedor (
    id_vendedor INT,
    id_fornecedor INT,
    PRIMARY KEY (id_vendedor, id_fornecedor),
    FOREIGN KEY (id_vendedor) REFERENCES vendedor(id_vendedor)
      ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor(id_fornecedor)
      ON UPDATE CASCADE ON DELETE CASCADE
);

-- Relacionamento Produto <-> Vendedor (N:N) — catálogo do seller
CREATE TABLE produto_vendedor (
    id_produto INT,
    id_vendedor INT,
    PRIMARY KEY (id_produto, id_vendedor),
    FOREIGN KEY (id_produto) REFERENCES produto(id_produto)
      ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (id_vendedor) REFERENCES vendedor(id_vendedor)
      ON UPDATE CASCADE ON DELETE CASCADE
);

-- PAGAMENTO
CREATE TABLE pagamento (
    id_pagamento INT PRIMARY KEY AUTO_INCREMENT,
    id_cliente INT NOT NULL,
    valor_total DECIMAL(10,2) NOT NULL CHECK (valor_total >= 0),
    forma_pagamento ENUM('cartao_credito','cartao_debito','pix','boleto') NOT NULL,
    status_pagamento ENUM('pendente','pago','cancelado') DEFAULT 'pendente',
    data_pagamento DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
      ON UPDATE CASCADE
);

-- ENTREGA
CREATE TABLE entrega (
    id_entrega INT PRIMARY KEY AUTO_INCREMENT,
    id_cliente INT NOT NULL,
    status_entrega ENUM('pendente','em_transporte','entregue','cancelada') DEFAULT 'pendente',
    codigo_rastreio VARCHAR(45),
    data_prevista DATE,
    data_entrega DATE,
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
      ON UPDATE CASCADE
);

-- PEDIDO (cabeçalho)
CREATE TABLE pedido (
    id_pedido INT PRIMARY KEY AUTO_INCREMENT,
    id_cliente INT NOT NULL,
    id_pagamento INT,
    id_entrega INT,
    data_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
    status_venda ENUM('em_aberto','pago','enviado','concluido','cancelado') DEFAULT 'em_aberto',
    observacao VARCHAR(200),
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
      ON UPDATE CASCADE,
    FOREIGN KEY (id_pagamento) REFERENCES pagamento(id_pagamento)
      ON UPDATE CASCADE,
    FOREIGN KEY (id_entrega) REFERENCES entrega(id_entrega)
      ON UPDATE CASCADE
);

-- ITENS DO PEDIDO (fato de vendas)
CREATE TABLE pedido_item (
    id_pedido INT,
    id_produto INT,
    id_vendedor INT,
    quantidade INT NOT NULL CHECK (quantidade > 0),
    preco_unitario DECIMAL(10,2) NOT NULL CHECK (preco_unitario >= 0),
    desconto DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (desconto >= 0),
    PRIMARY KEY (id_pedido, id_produto, id_vendedor),
    FOREIGN KEY (id_pedido) REFERENCES pedido(id_pedido)
      ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (id_produto) REFERENCES produto(id_produto)
      ON UPDATE CASCADE,
    FOREIGN KEY (id_vendedor) REFERENCES vendedor(id_vendedor)
      ON UPDATE CASCADE
);

-- =============================================================
-- 2) ÍNDICES ÚTEIS (além dos criados pelas FKs)
-- =============================================================
CREATE INDEX idx_pedido_data ON pedido (data_pedido);
CREATE INDEX idx_pagamento_status_forma ON pagamento (status_pagamento, forma_pagamento);
CREATE INDEX idx_produto_nome ON produto (nome);
CREATE INDEX idx_entrega_status ON entrega (status_entrega);

-- =============================================================
-- 3) DADOS DE EXEMPLO
-- =============================================================
INSERT INTO cliente (nome, cpf, email, cidade, pais, data_nascimento) VALUES
 ('Ana Lima','12345678901','ana@ex.com','São Paulo','Brasil','1990-05-10'),
 ('Bruno Souza','22233344455','bruno@ex.com','Rio de Janeiro','Brasil','1988-01-22'),
 ('Carla Alves','77788899900','carla@ex.com','Belo Horizonte','Brasil','1995-09-14'),
 ('Diego Rocha','11122233344','diego@ex.com','Curitiba','Brasil','1992-12-02'),
 ('Eva Moraes','55566677788','eva@ex.com','Porto Alegre','Brasil','1986-03-30');

INSERT INTO categoria (nome) VALUES
 ('Eletrônicos'), ('Casa'), ('Esporte'), ('Moda');

INSERT INTO produto (id_categoria, nome, descricao, quantidade_estoque, preco) VALUES
 (1,'Smartphone','Tela 6.1"',100,1500.00),
 (1,'Fone Bluetooth','Cancelamento de ruído',200,200.00),
 (2,'Cafeteira','Café expresso 110v',80,300.00),
 (3,'Bicicleta','Aro 29',40,2500.00),
 (4,'Camiseta','100% algodão',300,50.00),
 (1,'Notebook','14" 16GB RAM',50,3500.00);

INSERT INTO vendedor (nome, cnpj, avaliacao) VALUES
 ('Loja Alpha','11111111111111',4.6),
 ('Tech Store','22222222222222',4.8),
 ('Esporte Mais','33333333333333',4.2);

INSERT INTO fornecedor (razao_social, cnpj, estoque_produto) VALUES
 ('Distribuidora X','44444444444444',1000),
 ('Fábrica Y','55555555555555',500);

INSERT INTO vendedor_fornecedor VALUES
 (1,1),(2,1),(3,2);

INSERT INTO produto_vendedor VALUES
 (1,1),(1,2), -- Smartphone por Alpha e Tech Store
 (2,2),       -- Fone por Tech Store
 (3,1),       -- Cafeteira por Alpha
 (4,3),       -- Bicicleta por Esporte Mais
 (5,1),       -- Camiseta por Alpha
 (6,2);       -- Notebook por Tech Store

-- Pagamentos
INSERT INTO pagamento (id_cliente, valor_total, forma_pagamento, status_pagamento, data_pagamento) VALUES
 (1,1900.00,'pix','pago','2025-05-10 10:00:00'),
 (2,450.00,'cartao_credito','pago','2025-05-15 11:30:00'),
 (3,2500.00,'boleto','pago','2025-06-01 09:00:00'),
 (1,3500.00,'cartao_credito','pendente','2025-06-05 12:15:00'),
 (4,300.00,'pix','cancelado','2025-06-10 15:45:00'),
 (5,1500.00,'cartao_debito','pago','2025-07-01 14:05:00');

-- Entregas
INSERT INTO entrega (id_cliente, status_entrega, codigo_rastreio, data_prevista, data_entrega) VALUES
 (1,'entregue','BR123','2025-05-17','2025-05-16'),
 (2,'entregue','BR124','2025-05-19','2025-05-20'),
 (3,'entregue','BR125','2025-06-09','2025-06-10'),
 (1,'pendente','BR126','2025-06-12',NULL),
 (4,'cancelada','BR127','2025-06-17',NULL),
 (5,'em_transporte','BR128','2025-07-08',NULL);

-- Pedidos (ligando a pagamento/entrega)
INSERT INTO pedido (id_cliente, id_pagamento, id_entrega, data_pedido, status_venda) VALUES
 (1,1,1,'2025-05-10 09:50:00','concluido'),
 (2,2,2,'2025-05-15 11:10:00','concluido'),
 (3,3,3,'2025-06-01 08:55:00','concluido'),
 (1,4,4,'2025-06-05 12:00:00','em_aberto'),
 (4,5,5,'2025-06-10 15:30:00','cancelado'),
 (5,6,6,'2025-07-01 13:55:00','enviado');

-- Itens dos pedidos (com vendedor por linha)
INSERT INTO pedido_item VALUES
 -- Pedido 1 (Ana) — total 1900
 (1,1,2,1,1500.00,0.00),  -- Smartphone, Tech Store
 (1,2,2,2,200.00,0.00),   -- 2x Fone, Tech Store
 -- Pedido 2 (Bruno) — total 450
 (2,3,1,1,300.00,0.00),   -- Cafeteira, Alpha
 (2,5,1,3,50.00,0.00),    -- 3x Camiseta, Alpha
 -- Pedido 3 (Carla) — total 2500
 (3,4,3,1,2500.00,0.00),  -- Bicicleta, Esporte Mais
 -- Pedido 4 (Ana) — total 3500 (pendente)
 (4,6,2,1,3500.00,0.00),  -- Notebook, Tech Store
 -- Pedido 5 (Diego) — cancelado 300
 (5,5,1,2,50.00,0.00),    -- 2x Camiseta, Alpha
 (5,2,2,1,200.00,0.00),   -- 1x Fone, Tech Store
 -- Pedido 6 (Eva) — total 1500 (em transporte)
 (6,1,2,1,1500.00,0.00);  -- Smartphone, Tech Store

-- =============================================================
-- 4) VIEWS ÚTEIS PARA ANÁLISE
-- =============================================================
-- Detalhe de itens com valor calculado
CREATE OR REPLACE VIEW v_itens AS
SELECT 
  pi.id_pedido,
  pi.id_produto,
  pi.id_vendedor,
  p.nome  AS produto,
  v.nome  AS vendedor,
  pi.quantidade,
  pi.preco_unitario,
  pi.desconto,
  (pi.quantidade * (pi.preco_unitario - pi.desconto)) AS valor_linha
FROM pedido_item pi
JOIN produto p   ON p.id_produto   = pi.id_produto
JOIN vendedor v  ON v.id_vendedor  = pi.id_vendedor;

-- Resumo de pedidos (valor total e nº de itens)
CREATE OR REPLACE VIEW v_pedidos_resumo AS
SELECT 
  pd.id_pedido,
  pd.id_cliente,
  pd.data_pedido,
  pd.status_venda,
  COUNT(*) AS itens,
  SUM(vi.valor_linha) AS valor_total_pedido
FROM pedido pd
JOIN v_itens vi ON vi.id_pedido = pd.id_pedido
GROUP BY pd.id_pedido, pd.id_cliente, pd.data_pedido, pd.status_venda;

-- Métricas por cliente (R,F,M + segmentação)
CREATE OR REPLACE VIEW v_clientes_metricas AS
SELECT 
  c.id_cliente,
  c.nome,
  MAX(pd.data_pedido) AS ultima_compra,
  DATEDIFF(CURRENT_DATE, MAX(pd.data_pedido)) AS recencia_dias,
  COUNT(DISTINCT pd.id_pedido) AS frequencia,
  ROUND(COALESCE(SUM(vr.valor_total_pedido),0),2) AS total_gasto,
  CASE 
    WHEN COUNT(DISTINCT pd.id_pedido) >= 3 THEN 'Frequente'
    WHEN COUNT(DISTINCT pd.id_pedido) = 2 THEN 'Ocasional'
    WHEN COUNT(DISTINCT pd.id_pedido) = 1 THEN 'Novo'
    ELSE 'Sem compras'
  END AS segmento
FROM cliente c
LEFT JOIN pedido pd ON pd.id_cliente = c.id_cliente AND pd.status_venda <> 'cancelado'
LEFT JOIN v_pedidos_resumo vr ON vr.id_pedido = pd.id_pedido
GROUP BY c.id_cliente, c.nome;

-- =============================================================
-- 5) CONSULTAS AVANÇADAS (exemplos prontos)
-- =============================================================

-- Q1) Faturamento por mês (últimos 3 meses como exemplo) — filtros por período
WITH base AS (
  SELECT p.data_pedido, vr.valor_total_pedido
  FROM v_pedidos_resumo vr
  JOIN pedido p ON p.id_pedido = vr.id_pedido
  WHERE p.status_venda IN ('pago','enviado','concluido')
    AND p.data_pedido BETWEEN '2025-05-01' AND '2025-07-31'
)
SELECT DATE_FORMAT(data_pedido,'%Y-%m') AS mes,
       SUM(valor_total_pedido) AS faturamento
FROM base
GROUP BY mes
ORDER BY mes;

-- Q2) Ranking de vendedores por receita (ignora cancelados) — janela
SELECT v.id_vendedor, v.nome,
       ROUND(SUM(vi.valor_linha),2) AS receita,
       RANK() OVER (ORDER BY SUM(vi.valor_linha) DESC) AS posicao
FROM v_itens vi
JOIN vendedor v USING (id_vendedor)
JOIN pedido p USING (id_pedido)
WHERE p.status_venda <> 'cancelado'
GROUP BY v.id_vendedor, v.nome;

-- Q3) Produtos com baixa performance — HAVING com filtros
SELECT pr.id_produto, pr.nome,
       SUM(vi.quantidade) AS qtd_vendida,
       ROUND(SUM(vi.valor_linha),2) AS receita
FROM v_itens vi
JOIN produto pr USING (id_produto)
JOIN pedido p USING (id_pedido)
WHERE p.status_venda <> 'cancelado'
GROUP BY pr.id_produto, pr.nome
HAVING SUM(vi.quantidade) < 3 OR SUM(vi.valor_linha) < 500
ORDER BY receita ASC;

-- Q4) Ticket médio por cliente + segmentação com CASE
SELECT c.id_cliente, c.nome,
       COUNT(DISTINCT p.id_pedido) AS pedidos,
       ROUND(SUM(vr.valor_total_pedido),2) AS gasto,
       ROUND(AVG(vr.valor_total_pedido),2) AS ticket_medio,
       CASE 
         WHEN COUNT(DISTINCT p.id_pedido) >= 3 THEN 'VIP'
         WHEN COUNT(DISTINCT p.id_pedido) = 2 THEN 'Fidelizando'
         WHEN COUNT(DISTINCT p.id_pedido) = 1 THEN 'Novo'
         ELSE 'Sem compras'
       END AS perfil
FROM cliente c
LEFT JOIN pedido p ON p.id_cliente = c.id_cliente AND p.status_venda <> 'cancelado'
LEFT JOIN v_pedidos_resumo vr ON vr.id_pedido = p.id_pedido
GROUP BY c.id_cliente, c.nome
ORDER BY gasto DESC;

-- Q5) SLA de entrega — atraso x dentro do prazo
SELECT e.id_entrega, p.id_pedido, e.status_entrega, e.data_prevista, e.data_entrega,
       DATEDIFF(e.data_entrega, e.data_prevista) AS atraso_dias,
       CASE 
         WHEN e.data_entrega IS NULL THEN 'pendente'
         WHEN e.data_entrega <= e.data_prevista THEN 'no_prazo'
         ELSE 'atrasado'
       END AS classificacao
FROM entrega e
JOIN pedido p ON p.id_entrega = e.id_entrega
ORDER BY classificacao, e.id_entrega;

-- Q6) Receita por forma de pagamento (pago) — pivot com CASE
SELECT 
  ROUND(SUM(CASE WHEN forma_pagamento='pix' AND status_pagamento='pago' THEN valor_total ELSE 0 END),2) AS pix,
  ROUND(SUM(CASE WHEN forma_pagamento='cartao_credito' AND status_pagamento='pago' THEN valor_total ELSE 0 END),2) AS cartao_credito,
  ROUND(SUM(CASE WHEN forma_pagamento='cartao_debito' AND status_pagamento='pago' THEN valor_total ELSE 0 END),2) AS cartao_debito,
  ROUND(SUM(CASE WHEN forma_pagamento='boleto' AND status_pagamento='pago' THEN valor_total ELSE 0 END),2) AS boleto
FROM pagamento;

-- Q7) Busca de catálogo com filtros (LIKE/IN/PRICE)
SELECT p.id_produto, p.nome, c.nome AS categoria, p.preco
FROM produto p
JOIN categoria c ON c.id_categoria = p.id_categoria
WHERE c.nome IN ('Eletrônicos')
  AND p.nome LIKE '%fone%'
  AND p.preco BETWEEN 100 AND 300
ORDER BY p.preco;

-- Q8) Participação por vendedor no total (% do faturamento) — CTE + subquery
WITH receita_total AS (
  SELECT SUM(vi.valor_linha) AS total
  FROM v_itens vi JOIN pedido p USING (id_pedido)
  WHERE p.status_venda <> 'cancelado'
)
SELECT v.nome,
       ROUND(SUM(vi.valor_linha),2) AS receita,
       ROUND(100 * SUM(vi.valor_linha) / (SELECT total FROM receita_total),2) AS pct_total
FROM v_itens vi
JOIN vendedor v USING (id_vendedor)
JOIN pedido p USING (id_pedido)
WHERE p.status_venda <> 'cancelado'
GROUP BY v.nome
ORDER BY receita DESC;

-- Q9) Parâmetros simulados via CTE (período + vendedor opcional)
WITH params AS (
  SELECT DATE('2025-05-01') AS data_ini, DATE('2025-06-30') AS data_fim, NULL AS vendedor_id
), base AS (
  SELECT vi.*, p.data_pedido
  FROM v_itens vi JOIN pedido p USING (id_pedido)
  WHERE p.data_pedido BETWEEN (SELECT data_ini FROM params) AND (SELECT data_fim FROM params)
    AND ( (SELECT vendedor_id FROM params) IS NULL OR vi.id_vendedor = (SELECT vendedor_id FROM params) )
)
SELECT id_vendedor, SUM(valor_linha) AS receita_periodo
FROM base
GROUP BY id_vendedor
ORDER BY receita_periodo DESC;

-- Q10) Clientes com risco de churn (recência > 120 dias e já compraram)
SELECT *
FROM v_clientes_metricas
WHERE recencia_dias > 120 AND total_gasto > 0
ORDER BY recencia_dias DESC;

-- =============================================================
-- 6) PROCEDURE EXEMPLO (relatório por período e vendedor opcional)
-- =============================================================
DELIMITER $$
CREATE PROCEDURE sp_vendas_periodo (
  IN p_data_ini DATE,
  IN p_data_fim DATE,
  IN p_vendedor INT
)
BEGIN
  SELECT v.nome AS vendedor,
         DATE_FORMAT(p.data_pedido,'%Y-%m') AS mes,
         ROUND(SUM(vi.valor_linha),2) AS receita
  FROM v_itens vi
  JOIN pedido p USING (id_pedido)
  JOIN vendedor v USING (id_vendedor)
  WHERE p.data_pedido BETWEEN p_data_ini AND p_data_fim
    AND p.status_venda <> 'cancelado'
    AND (p_vendedor IS NULL OR v.id_vendedor = p_vendedor)
  GROUP BY v.nome, mes
  ORDER BY v.nome, mes;
END $$
DELIMITER ;

-- Exemplo de chamada:
-- CALL sp_vendas_periodo('2025-05-01','2025-07-31', NULL);
