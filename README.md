## Descrição

Aplicação desktop desenvolvida em Flutter que realiza o cadastro de clientes utilizando banco de dados SQLite.

O banco mantém duas tabelas:  
- `clientes` com campos `nome` (texto) e `telefone` (numérico).  
- `log_operacoes` que registra as operações (Insert, Update, Delete) com data e hora.

Todas as validações (campos obrigatórios, campo numérico único e maior que zero) são implementadas diretamente no banco.

---

## Funcionalidades

- Inserir, editar, listar e excluir clientes.
- Validações garantidas no banco SQLite.
- Registro automático das operações no log.
- Interface simples com abas para cadastro e visualização.
- Banco pré-criado copiado do assets na primeira execução.

---

## Pré-requisitos

- Sistema Operacional Windows (Flutter Desktop)
- Flutter SDK instalado (para rodar código-fonte)
- Executável pré-compilado disponível para uso imediato
