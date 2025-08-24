# 🛒 Projeto E-commerce — Desafio de Modelagem & SQL (MySQL 8+)

> **Status**: Concluído • **Banco**: `ecommerce` • **Linguagem**: SQL (MySQL 8+)

## 📋 Descrição do Desafio
Replique a modelagem do projeto lógico de banco de dados para o cenário de **E-commerce**, respeitando **PK/FK**, **constraints** e relacionamentos **EER**. Crie o **script SQL** do esquema, **insira dados de teste** e escreva **consultas avançadas** contemplando:

- Recuperações simples com `SELECT`
- Filtros com `WHERE`
- Expressões para **atributos derivados**
- Ordenações com `ORDER BY`
- Filtros aos grupos com `HAVING`
- **JOINs** entre múltiplas tabelas
- (Extra) CTEs, Views e Funções de Janela

### Regras de Refinamento
- **Cliente PF/PJ**: uma conta é **PF ou PJ**, **nunca ambos**.
- **Pagamento**: um cliente pode **cadastrar mais de uma forma** de pagamento.
- **Entrega**: deve ter **status** e **código de rastreio**.

### Perguntas de negócio (exemplos)
- Quantos pedidos foram feitos por cada cliente?
- Algum vendedor também é fornecedor?
- Relação de produtos, fornecedores e estoques;
- Relação de nomes de fornecedores e nomes de produtos;

---

## 🖼 Imagens (adicione as suas)
> Coloque suas imagens na pasta `imagens/` e elas serão exibidas aqui.

![Diagrama EER](imagens/diagrama.png)
![Consultas no Workbench](imagens/consultas.png)

---

## 🏗️ Esquema Lógico (resumo)

### Entidades principais
- **cliente** (`id_cliente`, `nome`, `tipo` = {PF,PJ}, `cpf`, `cnpj`, `email`, `endereco`, `cidade`, `pais`, `data_nascimento`)
- **categoria** (`id_categoria`, `nome`)
- **produto** (`id_produto`, `id_categoria`, `nome`, `descricao`, `quantidade_estoque`, `preco`)
- **vendedor** (`id_vendedor`, `nome`, `cnpj`, `avaliacao`)
- **fornecedor** (`id_fornecedor`, `razao_social`, `cnpj`, `estoque_produto`)
- **pedido** (`id_pedido`, `id_cliente`, `id_pagamento`, `id_entrega`, `data_pedido`, `status_venda`)
- **pedido_item** (PK composta: `id_pedido`, `id_produto`, `id_vendedor`; `quantidade`, `preco_unitario`, `desconto`)
- **entrega** (`id_entrega`, `status_entrega`, `codigo_rastreio`, `data_prevista`, `data_entrega`)
- **pagamento** (`id_pagamento`, `id_cliente`, `id_forma`, `valor_total`, `status_pagamento`, `data_pagamento`)
- **forma_pagamento** (`id_forma`, `nome`) — *dimensão*
- **cliente_forma_pagamento** (`id_cliente`, `id_forma`) — *N:N (cliente pode cadastrar várias formas)*
- **produto_vendedor** (`id_produto`, `id_vendedor`) — *catálogo do seller (N:N)*
- **vendedor_fornecedor** (`id_vendedor`, `id_fornecedor`) — *parceria (N:N)*

### Integridade adicional
- **Mutuamente exclusivo PF/PJ** via `CHECK`:
  ```sql
  CHECK (
    (tipo = 'PF' AND cpf  IS NOT NULL AND cnpj IS NULL) OR
    (tipo = 'PJ' AND cnpj IS NOT NULL AND cpf  IS NULL)
  )
  ```

---

## 🧩 Script SQL — Criação do Schema (DDL)

```sql
DROP DATABASE IF EXISTS ecommerce;
CREATE DATABASE ecommerce;
USE ecommerce;

-- CLIENTE (PF ou PJ)
CREATE TABLE cliente (
  id_cliente INT PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL,
  tipo ENUM('PF','PJ') NOT NULL,
  cpf  CHAR(11),
  cnpj CHAR(14),
  email VARCHAR(120),
  endereco VARCHAR(150),
  cidade VARCHAR(60),
  pais VARCHAR(60),
  data_nascimento DATE NOT NULL,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT ck_cliente_tipo CHECK (
    (tipo = 'PF' AND cpf  IS NOT NULL AND cnpj IS NULL) OR
    (tipo = 'PJ' AND cnpj IS NOT NULL AND cpf  IS NULL)
  ),
  CONSTRAINT uq_cliente_cpf  UNIQUE (cpf),
  CONSTRAINT uq_cliente_cnpj UNIQUE (cnpj)
);

CREATE TABLE categoria (
  id_categoria INT PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE produto (
  id_produto INT PRIMARY KEY AUTO_INCREMENT,
  id_categoria INT NOT NULL,
  nome VARCHAR(100) NOT NULL,
  descricao TEXT,
  quantidade_estoque INT NOT NULL DEFAULT 0 CHECK (quantidade_estoque >= 0),
  preco DECIMAL(10,2) NOT NULL CHECK (preco >= 0),
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria) ON UPDATE CASCADE
);

CREATE TABLE vendedor (
  id_vendedor INT PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL,
  cnpj CHAR(14) UNIQUE,
  endereco VARCHAR(100),
  telefone VARCHAR(20),
  avaliacao DECIMAL(2,1) CHECK (avaliacao >= 0 AND avaliacao <= 5)
);

CREATE TABLE fornecedor (
  id_fornecedor INT PRIMARY KEY AUTO_INCREMENT,
  razao_social VARCHAR(100) NOT NULL,
  cnpj CHAR(14) UNIQUE,
  estoque_produto INT DEFAULT 0 CHECK (estoque_produto >= 0)
);

-- N:N
CREATE TABLE vendedor_fornecedor (
  id_vendedor INT,
  id_fornecedor INT,
  PRIMARY KEY (id_vendedor, id_fornecedor),
  FOREIGN KEY (id_vendedor)  REFERENCES vendedor(id_vendedor)  ON DELETE CASCADE,
  FOREIGN KEY (id_fornecedor) REFERENCES fornecedor(id_fornecedor) ON DELETE CASCADE
);

CREATE TABLE produto_vendedor (
  id_produto INT,
  id_vendedor INT,
  PRIMARY KEY (id_produto, id_vendedor),
  FOREIGN KEY (id_produto)  REFERENCES produto(id_produto)  ON DELETE CASCADE,
  FOREIGN KEY (id_vendedor) REFERENCES vendedor(id_vendedor) ON DELETE CASCADE
);

-- Formas de pagamento (catálogo) + cadastro do cliente (N:N)
CREATE TABLE forma_pagamento (
  id_forma INT PRIMARY KEY AUTO_INCREMENT,
  nome ENUM('cartao_credito','cartao_debito','pix','boleto') UNIQUE NOT NULL
);

CREATE TABLE cliente_forma_pagamento (
  id_cliente INT,
  id_forma INT,
  PRIMARY KEY (id_cliente, id_forma),
  FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente) ON DELETE CASCADE,
  FOREIGN KEY (id_forma)   REFERENCES forma_pagamento(id_forma) ON DELETE CASCADE
);

CREATE TABLE pagamento (
  id_pagamento INT PRIMARY KEY AUTO_INCREMENT,
  id_cliente INT NOT NULL,
  id_forma INT NOT NULL,
  valor_total DECIMAL(10,2) NOT NULL CHECK (valor_total >= 0),
  status_pagamento ENUM('pendente','pago','cancelado') DEFAULT 'pendente',
  data_pagamento DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
  FOREIGN KEY (id_forma)   REFERENCES forma_pagamento(id_forma)
);

CREATE TABLE entrega (
  id_entrega INT PRIMARY KEY AUTO_INCREMENT,
  id_cliente INT NOT NULL,
  status_entrega ENUM('pendente','em_transporte','entregue','cancelada') DEFAULT 'pendente',
  codigo_rastreio VARCHAR(45),
  data_prevista DATE,
  data_entrega DATE,
  FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
);

CREATE TABLE pedido (
  id_pedido INT PRIMARY KEY AUTO_INCREMENT,
  id_cliente INT NOT NULL,
  id_pagamento INT,
  id_entrega INT,
  data_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
  status_venda ENUM('em_aberto','pago','enviado','concluido','cancelado') DEFAULT 'em_aberto',
  observacao VARCHAR(200),
  FOREIGN KEY (id_cliente)   REFERENCES cliente(id_cliente),
  FOREIGN KEY (id_pagamento) REFERENCES pagamento(id_pagamento),
  FOREIGN KEY (id_entrega)   REFERENCES entrega(id_entrega)
);

CREATE TABLE pedido_item (
  id_pedido INT,
  id_produto INT,
  id_vendedor INT,
  quantidade INT NOT NULL CHECK (quantidade > 0),
  preco_unitario DECIMAL(10,2) NOT NULL CHECK (preco_unitario >= 0),
  desconto DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (desconto >= 0),
  PRIMARY KEY (id_pedido, id_produto, id_vendedor),
  FOREIGN KEY (id_pedido)  REFERENCES pedido(id_pedido)   ON DELETE CASCADE,
  FOREIGN KEY (id_produto) REFERENCES produto(id_produto),
  FOREIGN KEY (id_vendedor) REFERENCES vendedor(id_vendedor)
);

-- Índices úteis
CREATE INDEX idx_pedido_data ON pedido (data_pedido);
CREATE INDEX idx_pagamento_status_forma ON pagamento (status_pagamento, id_forma);
CREATE INDEX idx_produto_nome ON produto (nome);
CREATE INDEX idx_entrega_status ON entrega (status_entrega);
```

---

## 🌱 Seeds (dados de teste)
> Opcional — simplificado para validar as consultas.

```sql
INSERT INTO categoria (nome) VALUES ('Eletrônicos'),('Casa'),('Esporte'),('Moda');

INSERT INTO forma_pagamento (nome) VALUES ('pix'),('cartao_credito'),('cartao_debito'),('boleto');

INSERT INTO cliente (nome, tipo, cpf, cnpj, email, cidade, pais, data_nascimento) VALUES
('Ana Lima','PF','12345678901',NULL,'ana@ex.com','São Paulo','Brasil','1990-05-10'),
('Bruno Souza','PF','22233344455',NULL,'bruno@ex.com','Rio de Janeiro','Brasil','1988-01-22'),
('Carla Ltda','PJ',NULL,'11111111000199','contato@carla.com','Belo Horizonte','Brasil','2000-01-01');

INSERT INTO cliente_forma_pagamento VALUES
(1,1),(1,2),(2,2),(2,3),(3,4);

INSERT INTO produto (id_categoria, nome, descricao, quantidade_estoque, preco) VALUES
(1,'Smartphone','Tela 6.1\"',100,1500.00),
(1,'Fone Bluetooth','ANC',200,200.00),
(2,'Cafeteira','110v',80,300.00);

INSERT INTO vendedor (nome, cnpj, avaliacao) VALUES
('Loja Alpha','55555555000110',4.6),
('Tech Store','66666666000120',4.8);

INSERT INTO fornecedor (razao_social, cnpj, estoque_produto) VALUES
('Distribuidora X','77777777000130',1000),
('Fábrica Y','88888888000140',500);

INSERT INTO vendedor_fornecedor VALUES (1,1),(2,1),(2,2);
INSERT INTO produto_vendedor VALUES (1,2),(2,2),(3,1);

-- Pagamentos/Entregas/Pedidos
INSERT INTO pagamento (id_cliente,id_forma,valor_total,status_pagamento) VALUES
(1,1,1900.00,'pago'),(2,2,450.00,'pago'),(3,4,300.00,'pendente');

INSERT INTO entrega (id_cliente,status_entrega,codigo_rastreio,data_prevista,data_entrega) VALUES
(1,'entregue','BR123','2025-05-17','2025-05-16'),
(2,'entregue','BR124','2025-05-19','2025-05-20'),
(3,'pendente','BR125','2025-06-09',NULL);

INSERT INTO pedido (id_cliente,id_pagamento,id_entrega,data_pedido,status_venda) VALUES
(1,1,1,'2025-05-10 09:50:00','concluido'),
(2,2,2,'2025-05-15 11:10:00','concluido'),
(3,3,3,'2025-06-01 08:55:00','em_aberto');

INSERT INTO pedido_item VALUES
(1,1,2,1,1500.00,0.00), -- smartphone
(1,2,2,2,200.00,0.00),  -- 2x fone
(2,3,1,1,300.00,0.00);  -- cafeteira
```

---

## 🔎 Consultas Avançadas (com respostas)

### 1) Recuperações simples (`SELECT`) + `ORDER BY`
```sql
-- Catálogo de produtos por preço decrescente
SELECT id_produto, nome, preco
FROM produto
ORDER BY preco DESC;
```

### 2) Filtros com `WHERE`
```sql
-- Pedidos concluídos de maio/2025
SELECT id_pedido, id_cliente, data_pedido, status_venda
FROM pedido
WHERE status_venda = 'concluido'
  AND data_pedido BETWEEN '2025-05-01' AND '2025-05-31';
```

### 3) Atributos derivados (expressões)
```sql
-- Valor total linha do item (quantidade * (preço - desconto))
SELECT id_pedido, id_produto,
       quantidade,
       preco_unitario, desconto,
       quantidade * (preco_unitario - desconto) AS valor_linha
FROM pedido_item;
```

### 4) `GROUP BY` + `HAVING` (responde: *quantos pedidos por cliente?*)
```sql
SELECT c.id_cliente, c.nome, COUNT(*) AS qtd_pedidos
FROM pedido p
JOIN cliente c ON c.id_cliente = p.id_cliente
GROUP BY c.id_cliente, c.nome
HAVING COUNT(*) >= 1   -- filtro sobre o grupo
ORDER BY qtd_pedidos DESC;
```

### 5) `JOINs` múltiplos (produtos × fornecedores × estoques)
```sql
SELECT f.razao_social AS fornecedor, pr.nome AS produto, f.estoque_produto
FROM fornecedor f
JOIN vendedor_fornecedor vf ON vf.id_fornecedor = f.id_fornecedor
JOIN vendedor v ON v.id_vendedor = vf.id_vendedor
JOIN produto_vendedor pv ON pv.id_vendedor = v.id_vendedor
JOIN produto pr ON pr.id_produto = pv.id_produto
ORDER BY fornecedor, produto;
```

### 6) *Algum vendedor também é fornecedor?* (match por CNPJ)
```sql
SELECT v.nome AS vendedor, f.razao_social AS fornecedor, v.cnpj
FROM vendedor v
JOIN fornecedor f ON f.cnpj = v.cnpj;
```

### 7) Relação nomes dos fornecedores × nomes dos produtos
```sql
SELECT DISTINCT f.razao_social AS fornecedor, p.nome AS produto
FROM fornecedor f
JOIN vendedor_fornecedor vf ON vf.id_fornecedor = f.id_fornecedor
JOIN vendedor v ON v.id_vendedor = vf.id_vendedor
JOIN produto_vendedor pv ON pv.id_vendedor = v.id_vendedor
JOIN produto p ON p.id_produto = pv.id_produto
ORDER BY fornecedor, produto;
```

### 8) Ticket médio por cliente (derivado + `CASE` de segmentação)
```sql
WITH itens AS (
  SELECT pi.id_pedido,
         pi.quantidade * (pi.preco_unitario - pi.desconto) AS valor_linha
  FROM pedido_item pi
),
pedidos AS (
  SELECT p.id_pedido, p.id_cliente, SUM(i.valor_linha) AS total_pedido
  FROM pedido p JOIN itens i USING (id_pedido)
  WHERE p.status_venda <> 'cancelado'
  GROUP BY p.id_pedido, p.id_cliente
)
SELECT c.id_cliente, c.nome,
       COUNT(*) AS pedidos,
       ROUND(SUM(total_pedido),2) AS gasto,
       ROUND(AVG(total_pedido),2) AS ticket_medio,
       CASE
         WHEN COUNT(*) >= 3 THEN 'VIP'
         WHEN COUNT(*) = 2 THEN 'Fidelizando'
         WHEN COUNT(*) = 1 THEN 'Novo'
         ELSE 'Sem compras'
       END AS perfil
FROM pedidos pd
JOIN cliente c ON c.id_cliente = pd.id_cliente
GROUP BY c.id_cliente, c.nome
ORDER BY gasto DESC;
```

### 9) Receitas por forma de pagamento (pivot com `CASE`)
```sql
SELECT
  ROUND(SUM(CASE WHEN f.nome='pix'             AND p.status_pagamento='pago' THEN p.valor_total ELSE 0 END),2) AS pix,
  ROUND(SUM(CASE WHEN f.nome='cartao_credito'  AND p.status_pagamento='pago' THEN p.valor_total ELSE 0 END),2) AS cartao_credito,
  ROUND(SUM(CASE WHEN f.nome='cartao_debito'   AND p.status_pagamento='pago' THEN p.valor_total ELSE 0 END),2) AS cartao_debito,
  ROUND(SUM(CASE WHEN f.nome='boleto'          AND p.status_pagamento='pago' THEN p.valor_total ELSE 0 END),2) AS boleto
FROM pagamento p
JOIN forma_pagamento f ON f.id_forma = p.id_forma;
```

### 10) SLA de entrega (classificação com `CASE`)
```sql
SELECT e.id_entrega, e.codigo_rastreio, e.status_entrega,
       e.data_prevista, e.data_entrega,
       DATEDIFF(e.data_entrega, e.data_prevista) AS atraso_dias,
       CASE
         WHEN e.data_entrega IS NULL THEN 'pendente'
         WHEN e.data_entrega <= e.data_prevista THEN 'no_prazo'
         ELSE 'atrasado'
       END AS classificacao
FROM entrega e
ORDER BY classificacao, e.id_entrega;
```

---

## ▶️ Como executar
1. Importe/cole o **DDL** (Criação do Schema) no MySQL Workbench ou CLI e execute.
2. Rode os **seeds** (inserts) se quiser dados de exemplo.
3. Execute as **consultas** desta seção para validar as regras do desafio.

---

## 📂 Estrutura sugerida do repositório
```
ecommerce-sql/
├─ imagens/
│  ├─ diagrama.png
│  └─ consultas.png
├─ schema.sql
├─ seeds.sql
├─ queries.sql
└─ README.md
```

---

## ✅ Checklist do desafio
- [x] Modelo lógico com PF/PJ exclusivos
- [x] Cadastro de múltiplas formas de pagamento por cliente
- [x] Entrega com status + rastreio
- [x] Script SQL do esquema
- [x] Seeds de dados para testes
- [x] Consultas usando SELECT, WHERE, expressões, ORDER BY, GROUP BY + HAVING, JOINs
- [x] Perguntas respondidas pelas queries

---

## 👤 Autor
Projeto para fins educacionais/portfólio. Sinta-se à vontade para clonar, testar e adaptar.
