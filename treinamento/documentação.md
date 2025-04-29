## Visão Geral

Este arquivo SQL define a estrutura de um banco de dados para um sistema de vendas. Ele inclui:

- Criação de sequências para autoincremento.
    
- Definição de domínios personalizados.
    
- Criação de tabelas para produtos, clientes, vendas e usuários.
    

## Estruturas Definidas

### 1. Sequências para Autoincremento

Foram criadas sequências para garantir que os campos chave primária possuam valores únicos automaticamente:

- `GEN_TABELA_PRODUTO_CODIGO`
    
- `GEN_TABELA_CLIENTE_CODIGO`
    
- `GEN_TABELA_VENDAS_NUMERO`
    
- `GEN_TABELA_USUARIO_ID`
    

### 2. Domínios Personalizados

Os domínios são utilizados para padronizar tipos de dados:

- `DM_BOOLEAN`: Aceita apenas os valores 'S' (Sim) ou 'N' (Não).
    
- `DM_CODIGO`: Representa um identificador numérico inteiro maior ou igual a zero.
    

### 3. Tabelas Criadas

#### **TABELA_PRODUTO**

Guarda informações sobre produtos, incluindo preço, estoque e categoria.

Campos principais:

- `CODIGO`: Identificador único.
    
- `DESCRICAO`: Nome do produto.
    
- `PRECO_CUSTO` e `PRECO_VENDA`: Valores financeiros.
    
- `ESTOQUE`: Quantidade em estoque.
    
- `CATEGORIA`: Classificação do produto.
    
- `DATA_CADASTRO`: Data de inclusão.
    
- `ATIVO`: Indica se o produto está ativo.
    

#### **TABELA_CLIENTE**

Armazena informações dos clientes.

Campos principais:

- `CODIGO`: Identificador único.
    
- `NOME`: Nome do cliente.
    
- `CPF_CNPJ`: Documento único.
    
- `DATA_NASCIMENTO`: Data de nascimento.
    
- `EMAIL`: Contato eletrônico.
    
- `DATA_CADASTRO`: Data de registro.
    
- `ATIVO`: Indica se o cliente está ativo.
    

#### **TABELA_VENDAS**

Registra as vendas realizadas.

Campos principais:

- `NUMERO`: Identificador único.
    
- `CLIENTE_CODIGO`: Referência ao cliente que realizou a compra.
    
- `DATA_VENDA`: Data da transação.
    
- `VALOR_TOTAL`: Valor final da venda.
    

#### **TABELA_USUARIO**

Armazena informações sobre os usuários do sistema.

Campos principais:

- `ID`: Identificador único.
    
- `NOME`: Nome do usuário.
    
- `EMAIL`: Endereço de e-mail.
    
- `SENHA`: Senha protegida para acesso ao sistema.
    

## Conclusão

Este arquivo SQL estrutura um banco de dados voltado para um sistema de vendas, garantindo a padronização dos dados e a integridade referencial. Cada tabela foi projetada para armazenar informações essenciais, enquanto os domínios e sequências facilitam a gestão dos dados.