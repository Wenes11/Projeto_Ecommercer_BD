DESCRIBE cliente;
DESCRIBE produto;
DESCRIBE pedido;
-- Selecionar colunas certas da tabela cliente
SELECT nome, cpf, cidade FROM cliente;

-- Se não existir "cidade", use "endereco" ou o campo correspondente
SELECT nome, cpf, endereco FROM cliente;

-- Ordenar produtos (pela coluna correta, ex.: preco ou estoque)
SELECT * FROM produto ORDER BY preco DESC;

-- Ordenar pedidos pela quantidade
SELECT * FROM pedido ORDER BY quantidade DESC;
