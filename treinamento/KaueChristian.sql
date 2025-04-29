
-- Sequências criadas para ter autoincremento nos triggers.
CREATE SEQUENCE GEN_TABELA_PRODUTO_CODIGO;

CREATE SEQUENCE GEN_TABELA_CLIENTE_CODIGO;

CREATE SEQUENCE GEN_TABELA_VENDAS_NUMERO;

create sequence gen_tabela_usuario_id;


-- Domínios
CREATE DOMAIN DM_BOOLEAN AS CHAR(1)
CHECK (VALUE IN ('S', 'N'));

CREATE DOMAIN DM_CODIGO AS INTEGER
CHECK (VALUE >= 0);

-- Criação das tabelas
CREATE TABLE TABELA_PRODUTO (
    CODIGO DM_CODIGO PRIMARY KEY,
    DESCRICAO VARCHAR(100) NOT NULL,
    PRECO_CUSTO NUMERIC(10,2),
    PRECO_VENDA NUMERIC(10,2),
    ESTOQUE INTEGER,
    CATEGORIA VARCHAR(50),
    DATA_CADASTRO DATE DEFAULT CURRENT_DATE,
    ATIVO DM_BOOLEAN DEFAULT 'S'
);

CREATE TABLE TABELA_CLIENTE( 
    CODIGO DM_CODIGO PRIMARY KEY,
    NOME VARCHAR(100) NOT NULL,
    CPF_CNPJ VARCHAR(14) UNIQUE,
    DATA_NASCIMENTO DATE,
    EMAIL VARCHAR(100),
    DATA_CADASTRO DATE DEFAULT CURRENT_DATE,
    ATIVO DM_BOOLEAN DEFAULT 'S'
);

CREATE TABLE TABELA_VENDAS ( 
    NUMERO DM_CODIGO, 
    DATA_VENDA TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CLIENTE_CODIGO DM_CODIGO,  
    VALOR_TOTAL NUMERIC(10,2),
    PRIMARY KEY (NUMERO, DATA_VENDA), 
    FOREIGN KEY(CLIENTE_CODIGO) REFERENCES TABELA_CLIENTE(CODIGO) 
);

CREATE TABLE TABELA_ITEM_VENDA(
    VENDA_NUMERO DM_CODIGO,
    VENDA_DATA TIMESTAMP,
    PRODUTO_CODIGO DM_CODIGO,
    QUANTIDADE INTEGER,
    PRECO_UNITARIO NUMERIC(10,2),
    PRIMARY KEY (VENDA_NUMERO, VENDA_DATA, PRODUTO_CODIGO),
    FOREIGN KEY (VENDA_NUMERO, VENDA_DATA) REFERENCES TABELA_VENDAS(NUMERO, DATA_VENDA),
    FOREIGN KEY (PRODUTO_CODIGO) REFERENCES TABELA_PRODUTO(CODIGO)
);

create table tabela_usuario (
    id DM_CODIGO primary key,
    nome_usuario varchar(50) unique not null,
    senha varchar(50) not null,
    email varchar(100),
    data_cadastro date default CURRENT_DATE,
    ativo DM_BOOLEAN default 'S'
);


-- Trigger para a tabela de produtos

CREATE TRIGGER TRG_BI_TABELA_PRODUTO FOR TABELA_PRODUTO
ACTIVE BEFORE INSERT POSITION 0
AS 
BEGIN
    IF (NEW.CODIGO IS NULL) THEN 
        NEW.CODIGO = NEXT VALUE FOR GEN_TABELA_PRODUTO_CODIGO;
END; 

-- Trigger para a tabela de clientes
CREATE TRIGGER TRG_BI_TABELA_CLIENTE FOR TABELA_CLIENTE
ACTIVE BEFORE INSERT POSITION 0
AS 
BEGIN
    IF (NEW.CODIGO IS NULL) THEN 
        NEW.CODIGO = NEXT VALUE FOR GEN_TABELA_CLIENTE_CODIGO;
END;

-- Trigger para a tabela de vendas
CREATE TRIGGER TRG_BI_TABELA_VENDAS FOR TABELA_VENDAS
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
    IF (NEW.NUMERO IS NULL) THEN 
        NEW.NUMERO = NEXT VALUE FOR GEN_TABELA_VENDAS_NUMERO;
END;

create trigger TRG_BI_TABELA_USUARIO for tabela_usuario
active before insert position 0
as
begin
  if (new.id is null) then 
    new.id = next value for gen tabela usuario_id;
END;

-- Exceção para preço de venda inválido
CREATE EXCEPTION EX_PRECO_INVALIDO 'O preço de venda deve ser maior que o preço de custo.';

-- Exceção para quantidade inválida no estoque
CREATE EXCEPTION EX_QUANTIDADE_INVALIDA 'A quantidade informada deve ser maior que zero.';

-- Exceção para produto não encontrado
CREATE EXCEPTION EX_PRODUTO_NAO_ENCONTRADO 'O produto informado não foi encontrado no banco de dados.';

-- Exceção para estoque insuficiente
CREATE EXCEPTION EX_ESTOQUE_INSUFICIENTE 'Não há estoque suficiente para essa operação.';

-- Exceção para cliente não encontrado
CREATE EXCEPTION EX_CLIENTE_NAO_ENCONTRADO 'O cliente informado não possui vendas registradas.';

-- PROCEDURES

CREATE PROCEDURE ADD_PRODUTO (
    DESCRICAO VARCHAR(100),
    PRECO_CUSTO NUMERIC(10,2),
    PRECO_VENDA NUMERIC(10,2),
    CATEGORIA VARCHAR(50)
)
AS
BEGIN
-- Verifica se o preço de venda é inválido
IF (PRECO_VENDA <= PRECO_CUSTO) THEN
BEGIN
    EXCEPTION EX_PRECO_INVALIDO;
END

-- Insere o produto e retorna o CODIGO gerado (opcional)
  INSERT INTO TABELA_PRODUTO 
    (DESCRICAO, PRECO_CUSTO, PRECO_VENDA, CATEGORIA, ESTOQUE)
  VALUES (:DESCRICAO, :PRECO_CUSTO, :PRECO_VENDA, :CATEGORIA, 0);
END;

CREATE PROCEDURE ATUALIZAR_ESTOQUE (
    PRODUTO_CODIGO DM_CODIGO,
    QUANTIDADE INTEGER)
AS
DECLARE VARIABLE ESTOQUE_ATUAL INTEGER;
BEGIN
  -- Verifica se a quantidade informada é válida
  IF (QUANTIDADE <= 0) THEN
  BEGIN
    EXCEPTION EX_QUANTIDADE_INVALIDA;
  END

  -- Obtém o estoque atual do produto
  SELECT ESTOQUE 
  FROM TABELA_PRODUTO 
  WHERE CODIGO = :PRODUTO_CODIGO
  INTO :ESTOQUE_ATUAL;

  -- Verifica se o produto existe
  IF (ESTOQUE_ATUAL IS NULL) THEN
  BEGIN
    EXCEPTION EX_PRODUTO_NAO_ENCONTRADO;
  END

  -- Verifica se há estoque suficiente
  IF (ESTOQUE_ATUAL < QUANTIDADE) THEN
  BEGIN
    EXCEPTION EX_ESTOQUE_INSUFICIENTE;
  END

  -- Atualiza o estoque
  UPDATE TABELA_PRODUTO
  SET ESTOQUE = ESTOQUE - :QUANTIDADE
  WHERE CODIGO = :PRODUTO_CODIGO;

END;

CREATE PROCEDURE CALCULAR_TOTAL_VENDAS_CLIENTE (
    CLIENTE_CODIGO DM_CODIGO)
RETURNS (TOTAL NUMERIC(10,2))
AS
BEGIN
  -- Inicializa o total como 0 para evitar valores nulos
  TOTAL = 0;

  -- Calcula o total das vendas do cliente
  SELECT COALESCE(SUM(VALOR_TOTAL), 0) 
  FROM TABELA_VENDAS
  WHERE CLIENTE_CODIGO = :CLIENTE_CODIGO
  INTO :TOTAL;

  -- Retorna o resultado
  SUSPEND;
END;

-- Scripts para injetar dados nas tabelas

EXECUTE BLOCK AS
  DECLARE VARIABLE I INTEGER;
BEGIN
  I = 1;
  WHILE (I <= 40) DO
  BEGIN
    INSERT INTO TABELA_PRODUTO (DESCRICAO, PRECO_CUSTO, PRECO_VENDA, ESTOQUE, CATEGORIA)
    VALUES ('Produto ' || :I, 10.00 + :I, 15.00 + :I, 100 + :I, 'Categoria A');
    I = I + 1;
  END
END;


execute block as
    declare variable I integer;
begin
    I = 1;
    while (I <= 40) do
    begin
        insert into tabela_cliente(nome, cpf_cnpj, data_nascimento, email)
        values ('Cliente' || :I, lpad(:I, 14, '0'), date '1980-01-01' + (:I-1), 'cliente' || :I || '@emailfalso.com');
        I = I + 1;
    end
end;

execute block as
    declare variable num integer = 1001;
begin
  while (num <= 1040) do
  begin
    insert into tabela_vendas(NUMERO, DATA_VENDA, CLIENTE_CODIGO, VALOR_TOTAL)
    values (:num, '2025-04-02 12:00:00', :num - 1000, 100.00 + ((:num - 1000) * 10));
    num = num + 1;
  end 
end;


execute block as
  declare variable i integer= 1;
begin
  while (i <= 40) do
  begin
    insert into tabela_item_venda (VENDA_NUMERO, VENDA_DATA, PRODUTO_CODIGO, QUANTIDADE, PRECO_UNITARIO)
      values (1000 + :i, '2025-04-02 12:00:00', :i, 2, 15.00 + :i);
    i = i + 1;
  end
end;

delete from tabela_item_venda where venda_numero in (2, 4, 6, 8, 10);

delete from tabela_produto where codigo in (2, 4, 6, 8, 10);

delete from tabela_vendas where numero in (1, 3, 5, 7, 9, 11);

delete from tabela_cliente where codigo in (5, 10, 15, 20, 25);

UPDATE TABELA_PRODUTO
SET DESCRICAO = DESCRICAO || ' - Atualizado'
WHERE CODIGO IN (1,3,5,7,9,11,13,15,17,19);

UPDATE TABELA_CLIENTE
SET EMAIL = 'atualizado_' || EMAIL
WHERE CODIGO IN (1,3,5,7,9,11,13,15,17,19);

UPDATE TABELA_VENDAS
SET VALOR_TOTAL = VALOR_TOTAL + 50
WHERE NUMERO IN (1001,1003,1005,1007,1009,1011,1013,1015,1017,1019);

UPDATE TABELA_ITEM_VENDA
SET QUANTIDADE = QUANTIDADE + 1
WHERE PRODUTO_CODIGO IN (1,3,5,7,9,11,13,15,17,19);


select v.numero, v.data_venda, c.nome, v.valor_total
from tabela_vendas v
inner join tabela_cliente c on v.cliente_codigo = c.codigo;

select c.codigo, c.nome, v.numero, v.valor_total
from tabela_cliente c
left join tabela_vendas v on c.codigo = v.cliente_codigo;

select c.codigo, c.nome, v.numero, v.valor_total
from tabela_cliente c
right join tabela_vendas v on c.codigo = v.cliente_codigo;

select c.codigo, c.nome, v.numero, v.valor_total
from tabela_cliente c
left join tabela_vendas v on c.codigo = v.cliente_codigo
union
select c.codigo, c.nome, v.numero, v.valor_total
from tabela_cliente c
right join tabela_vendas v on c.codigo = v.cliente_codigo;

