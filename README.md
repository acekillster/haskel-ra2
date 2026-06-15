# haskel-ra2

# Sistema de Inventario em Haskell

Instituicao: PucPR
Disciplina: Programacao Logica e Funcional
Professor: Frank alcantra

Pietro de Souza Mastantuono

https://onlinegdb.com/JWSRiUiKd

---

## Sobre o trabalho

Este trabalho consiste no desenvolvimento de um sistema de gerenciamento de inventario em Haskell utilizando conceitos de programacao funcional, manipulacao de estado, persistencia em arquivo e operacoes de entrada e saida (IO).

O sistema funciona inteiramente pelo terminal e permite adicionar, remover, atualizar e consultar itens do inventario. Todas as operacoes realizadas sao registradas em um arquivo de auditoria e o estado do inventario e salvo automaticamente para manter os dados entre diferentes execucoes do programa.

A logica do sistema foi separada das operacoes de IO, utilizando funcoes puras para a manipulacao do inventario e funcoes impuras apenas para leitura, escrita e interacao com o usuario.

---

## Funcionalidades

O sistema possui as seguintes funcionalidades:

- adicionar itens no inventario
- remover quantidade de itens
- atualizar informacoes de um item
- listar todos os itens cadastrados
- consultar historico de um item
- gerar relatorio baseado nos logs
- salvar automaticamente o estado do inventario
- registrar auditoria de sucesso e falha
- carregar os dados automaticamente ao iniciar

---

## Estrutura dos dados

O sistema utiliza os seguintes tipos:

### Item

Representa um item do inventario contendo:

- itemID
- nome
- quantidade
- categoria

### Inventario

Utiliza um `Map String Item` para armazenar os itens utilizando o ID como chave.

### AcaoLog

Representa o tipo de operacao realizada:

- Add
- Remove
- Update
- QueryFail

### StatusLog

Representa o resultado da operacao:

- Sucesso
- Falha String

### LogEntry

Representa uma entrada de auditoria contendo:

- horario da operacao
- acao realizada
- detalhes
- status da operacao

Todos os tipos utilizados derivam `Show` e `Read`, permitindo serializacao e desserializacao dos arquivos.

---

## Persistencia dos dados

O sistema utiliza dois arquivos:

### Inventario.dat

Armazena o estado atual do inventario.

Este arquivo e sobrescrito automaticamente a cada operacao realizada com sucesso.

### Auditoria.log

Armazena todas as operacoes executadas no sistema.

Todas as tentativas de operacao sao registradas, incluindo sucessos e falhas.

O arquivo funciona em modo append-only.

Ao iniciar o programa, os arquivos sao carregados automaticamente. Caso nao existam, o sistema inicia com inventario e log vazios utilizando tratamento de excecao com `catch`.

---

## Comandos disponiveis

### adicionar item

```txt
add id nome quantidade categoria
```

Exemplo:

```txt
add 100 teclado 10 perifericos
```

### remover item

```txt
remove id quantidade
```

Exemplo:

```txt
remove 100 5
```

### atualizar item

```txt
update id nome quantidade categoria
```

Exemplo:

```txt
update 100 teclado_rgb 20 perifericos
```

### listar inventario

```txt
list
```

### consultar historico de um item

```txt
history id
```

Exemplo:

```txt
history 100
```

### gerar relatorio

```txt
report
```

### popular inventario com itens de teste

```txt
seed
```

### ajuda

```txt
help
```

### encerrar programa

```txt
quit
```

---

## Como executar

### OnlineGDB

1. Abrir o ambiente OnlineGDB.
2. Selecionar a linguagem Haskell.
3. Copiar o codigo para o arquivo `Main.hs`.
4. Executar o programa.
5. Utilizar os comandos diretamente pelo terminal.

### Replit

1. Abrir o ambiente configurado para Haskell.
2. Colar o codigo no arquivo `Main.hs`.
3. Executar o programa.
4. Utilizar os comandos pelo terminal.

---

## Funcoes de analise implementadas

O sistema possui funcoes puras de analise dos logs:

### historicoPorItem

Retorna todas as operacoes realizadas para um item especifico.

### logsDeErro

Retorna apenas operacoes com falha registradas no log.

### itemMaisMovimentado

Retorna o item que mais recebeu movimentacoes no sistema.

### report

Executa os relatorios e apresenta os dados diretamente no terminal.

---

## Dados minimos para teste

O sistema possui um comando chamado `seed`, utilizado para inserir automaticamente mais de 10 itens distintos no inventario para facilitar testes e validacao do sistema.

Exemplo:

```txt
seed
```

---

## Cenarios de teste realizados

### Cenario 1 - Persistencia de estado

Foi iniciado o programa sem arquivos de dados existentes.

Em seguida, foram adicionados itens ao inventario:

```txt
add 100 teclado 10 perifericos
add 101 mouse 20 perifericos
add 102 monitor 5 video
```

O programa foi encerrado utilizando:

```txt
quit
```

Foi verificada a criacao dos arquivos:

- Inventario.dat
- Auditoria.log

O programa foi iniciado novamente e executado:

```txt
list
```

Resultado:

Os itens permaneceram salvos corretamente, comprovando a persistencia do estado entre execucoes.

---

### Cenario 2 - Erro de logica (estoque insuficiente)

Foi adicionado o item:

```txt
add 200 teclado 10 perifericos
```

Depois foi realizada uma tentativa de remover quantidade superior ao estoque:

```txt
remove 200 15
```

Resultado:

O sistema exibiu mensagem de erro de estoque insuficiente.

O inventario permaneceu inalterado com 10 unidades.

O erro foi registrado corretamente no arquivo `Auditoria.log`.

---

### Cenario 3 - Geracao de relatorio de erros

Depois da tentativa de remocao invalida, foi executado:

```txt
report
```

Resultado:

O sistema exibiu corretamente o relatorio de erros registrados, incluindo a tentativa de remocao com estoque insuficiente.

---

## Organizacao do repositorio

O repositorio contem os seguintes arquivos:

```txt
Main.hs
README.md
Inventario.dat
Auditoria.log
```

---

## Consideracoes finais

O sistema foi desenvolvido utilizando conceitos de programacao funcional em Haskell, mantendo separacao entre logica pura e operacoes de entrada e saida.

As funcionalidades de persistencia, auditoria, tratamento de erro, relatorios e manipulacao do inventario foram implementadas conforme os requisitos do trabalho.

prints que provam a execução:
<img width="510" height="497" alt="image" src="https://github.com/user-attachments/assets/91288376-8e60-479b-b7a7-89cbccf2ca42" />
<img width="535" height="469" alt="image" src="https://github.com/user-attachments/assets/bcdf2ec3-4bd1-4f21-be6b-d42c0d395937" />
<img width="742" height="536" alt="image" src="https://github.com/user-attachments/assets/864dd9ac-f705-4d98-8692-753b4561d3d8" />
<img width="755" height="848" alt="image" src="https://github.com/user-attachments/assets/1d2add48-2de9-4b42-ad6a-1b3dd185bcbe" />



