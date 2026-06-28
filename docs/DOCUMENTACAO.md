# 📖 Documentação — Analisador Léxico da Linguagem `.edu`

**Repositório:** [ViniciusProgrammer/DIM0548-LINGUAGEM-IMPERATIVA](https://github.com/ViniciusProgrammer/DIM0548-LINGUAGEM-IMPERATIVA)
**Disciplina:** DIM0548 — Engenharia de Linguagens
**Tecnologias:** Flex · Bison · GCC · Shell Script (Bash)

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Estrutura do Repositório](#2-estrutura-do-repositório)
3. [Tecnologias](#3-tecnologias)
4. [Pré-requisitos e Instalação](#4-pré-requisitos-e-instalação)
5. [Como Compilar](#5-como-compilar)
6. [Como Testar](#6-como-testar)
7. [A Linguagem `.edu`](#7-a-linguagem-edu)
8. [Especificação do Analisador Léxico](#8-especificação-do-analisador-léxico)
9. [Tokens Reconhecidos](#9-tokens-reconhecidos)
10. [Tratamento de Erros Léxicos](#10-tratamento-de-erros-léxicos)
11. [Especificação do Analisador Sintático](#11-especificação-do-analisador-sintático)
12. [Tratamento de Erros Sintáticos](#12-tratamento-de-erros-sintáticos)
13. [Exemplos de Saída](#13-exemplos-de-saída)
14. [Arquivos de Teste](#14-arquivos-de-teste)
15. [Referências](#15-referências)

---

## 1. Visão Geral

Este projeto implementa um compilador para uma linguagem imperativa educacional chamada `.edu`. O projeto foi desenvolvido como trabalho prático da disciplina **DIM0548 — Engenharia de Linguagens**.

- **Fase 1 (Léxica):** Lê o código-fonte e agrupa os caracteres em unidades lógicas chamadas **tokens** (palavras reservadas, identificadores, operadores).
- **Fase 2 (Sintática):** Recebe esses tokens e verifica se eles formam frases válidas de acordo com a **gramática** da linguagem, garantindo a ordem estrutural (ex: um `se` deve ter um `fim_se`).
- **Fase 3 (Semântica):** Registra identificadores e realiza verificações de tipos e escopos.
- **Fase 4 (Geração):** Traduz o programa `.edu` para o subconjunto de C definido no problema 8.

---

## 2. Estrutura do Repositório

```
DIM0548-LINGUAGEM-IMPERATIVA/
│
├── src/
│   ├── lexer.l          # Especificação do analisador léxico (Flex)
│   ├── parser.y         # Especificação do analisador sintático (Bison)
│   ├── lex.yy.c         # Código gerado pelo Flex (não editar)
│   ├── y.tab.c          # Código C gerado pelo Bison (não editar)
│   └── y.tab.h          # Cabeçalho gerado pelo Bison com a lista de tokens
│
├── docs/                # Documentação adicional
│
├── testes/
│   ├── quicksort.edu       # Programa QuickSort válido
│   ├── quicksortERRO.edu   # Programa com erros sintáticos para validação
│   └── testes.edu          # Arquivo de teste de estruturas gerais
│
├── compilar.sh          # Script de build automatizado
├── .gitignore
└── README.md
```

---

## 3. Tecnologias

| Ferramenta | Função |
|---|---|
| **Flex** | Gerador de analisadores léxicos a partir de regras definidas no arquivo `.l` |
| **Bison** |	Gerador do analisador sintático (LALR) a partir de regras gramaticais `.y` |
| **GCC** | Compilador C que transforma o código gerado pelo Flex em executável binário |
| **Bash** | Automatiza o processo de build no script `compilar.sh` |

**Distribuição de linguagens no repositório:**

- Yacc (`.y`): **51,4%**
- Lex (`.l`): **38,0%**
- Shell (`.sh`): **10,6%**

---

## 4. Pré-requisitos e Instalação

O projeto foi desenvolvido para **Linux**. É necessário ter o **Flex** e o **GCC** instalados.

**Ubuntu / Debian:**
```bash
sudo apt update && sudo apt install flex bison gcc -y
```

**Arch Linux:**
```bash
sudo pacman -S flex bison gcc
```

**Fedora / RHEL:**
```bash
sudo dnf install flex bison gcc
```

---

## 5. Como Compilar

O script `compilar.sh` automatiza todo o processo de build integrando Flex e Bison:

```bash
# Na raiz do repositório, dê permissão de execução (apenas a primeira vez):
chmod +x compilar.sh

# Execute o script:
./compilar.sh
```

O que o script faz:
1. Roda o `bison -d` para gerar o parser e a lista de tokens (`y.tab.h`).
2. Roda o `flex` para gerar o scanner.
3. Usa o `gcc` para juntar o lexer, o parser e os módulos auxiliares no executável `compiler`.

---

## 6. Como Testar

O compilador recebe o arquivo de entrada e o caminho do arquivo C de saída como argumentos:

```bash
# Código válido
./compiler testes/quicksort.edu /tmp/quicksort.c
gcc /tmp/quicksort.c -o /tmp/quicksort

# Código propositalmente inválido
./compiler testes/quicksortERRO.edu /tmp/quicksortERRO.c

# Estruturas gerais
./compiler testes/testes.edu /tmp/testes.c
gcc /tmp/testes.c -o /tmp/testes
```

Para compilar os seis problemas de avaliação:

```bash
make problemas
```

---

## 7. A Linguagem `.edu`

A linguagem `.edu` é uma linguagem imperativa educacional com sintaxe em português. Ela suporta:

- Declaração de variáveis com tipos explícitos
- Estruturas de controle (`se/senao/fim_se`, `enquanto/fim_enquanto`, `repetir/ate`)
- Definição de `procedimento` e `funcao` com parâmetros por referência (`ref`)
- Tipo de retorno de funções declarado com o operador `->`
- Vetores (arrays) com sintaxe `nome: Tipo[tamanho]` e acesso por `vetor[i]`
- Literais booleanos (`Verdadeiro` / `Falso`)
- Comentários de linha (`//`) e de bloco (`/* */`)

**Exemplo de código `.edu`:**

```
// Procedimento de troca
procedimento Trocar (ref vetor: Inteiro[], i: Inteiro, j: Inteiro) inicio
    aux: Inteiro = vetor[i]
    vetor[i] = vetor[j]
    vetor[j] = aux
fim
```

---

## 8. Especificação do Analisador Léxico

O arquivo `src/lexer.l` é organizado em três seções, conforme o padrão Flex:

### Seção 1 — Definições e Variáveis Globais

```lex
%{
  #include <stdio.h>
  int linha_atual = 1;    // Contador de linhas — rastreia a posição no código
%}

ESPACO      [ \t\r]+
DIGITO      [0-9]
LETRA       [a-zA-Z_]
ID          {LETRA}({LETRA}|{DIGITO})*
INTEIRO     {DIGITO}+
REAL        {DIGITO}+"."{DIGITO}+
TEXTO       \"([^\\\"]|\\.)*\"
```

**Macros de expressão regular definidas:**

| Macro | Padrão | Descrição |
|---|---|---|
| `ESPACO` | `[ \t\r]+` | Espaços, tabs e retorno de carro |
| `DIGITO` | `[0-9]` | Um dígito numérico |
| `LETRA` | `[a-zA-Z_]` | Uma letra ASCII ou `_` |
| `ID` | `{LETRA}({LETRA}\|{DIGITO})*` | Identificador: começa com letra ou `_`, seguido de letras, dígitos ou `_` |
| `INTEIRO` | `{DIGITO}+` | Um ou mais dígitos |
| `REAL` | `{DIGITO}+"."{DIGITO}+` | Número com ponto decimal obrigatório |
| `TEXTO` | `\"([^\\\"]\\.)*\"` | String entre aspas duplas com suporte a sequências de escape |

### Seção 2 — Regras de Reconhecimento

Cada regra associa um padrão (expressão regular) a uma ação em C. O Flex aplica a primeira regra que corresponde ao texto atual, na ordem em que estão declaradas.

### Seção 3 — Código C Auxiliar

Ao final do arquivo, `yywrap` informa ao Flex que a entrada terminou:

```c
int yywrap(void) { return 1; }
```

---

## 9. Tokens Reconhecidos

### 9.1 Espaços e Quebras de Linha

| Padrão | Ação |
|---|---|
| Espaços, tabs (`\t`) e `\r` | Ignorados silenciosamente |
| Quebra de linha (`\n`) | Incrementa `linha_atual` para rastreamento de posição |

### 9.2 Comentários

| Tipo | Sintaxe | Ação |
|---|---|---|
| Linha | `// texto até fim da linha` | Ignorado |
| Bloco | `/* texto em múltiplas linhas */` | Ignorado |

### 9.3 Palavras Reservadas

| Lexema | Token | Descrição |
|---|---|---|
| `se` | `SE` | Início de condicional |
| `senao` | `SENAO` | Alternativa da condicional |
| `fim_se` | `FIM_SE` | Encerramento do bloco `se` |
| `enquanto` | `ENQUANTO` | Início do laço while |
| `fim_enquanto` | `FIM_ENQUANTO` | Encerramento do laço while |
| `repetir` | `REPETIR` | Início do laço do-while |
| `ate` | `ATE` | Condição de parada do `repetir` |
| `inicio` | `INICIO` | Abertura de bloco de código |
| `fim` | `FIM` | Fechamento de bloco de código |
| `procedimento` | `PROCEDIMENTO` | Declaração de procedimento (sem retorno) |
| `funcao` | `FUNCAO` | Declaração de função (com retorno) |
| `retorne` | `RETORNE` | Instrução de retorno de valor |
| `ref` | `MODIFICADOR_REF` | Passagem de argumento por referência |
| `main` | `MAIN` | Procedimento principal |

### 9.4 Tipos Primitivos

> **Atenção:** Na linguagem `.edu`, os tipos começam com letra **maiúscula**, diferenciando-os de identificadores comuns.

| Lexema | Token |
|---|---|
| `Inteiro` | `TIPO_INTEIRO` |
| `Real` | `TIPO_REAL` |
| `Texto` | `TIPO_TEXTO` |
| `Booleano` | `TIPO_BOOLEANO` |
| `Constante` | `CONSTANTE` |

### 9.5 Literais

| Categoria | Exemplos | Token emitido |
|---|---|---|
| Booleano verdadeiro | `Verdadeiro` | `LITERAL_BOOLEANO(Verdadeiro)` |
| Booleano falso | `Falso` | `LITERAL_BOOLEANO(Falso)` |
| Número real | `3.14`, `0.5`, `100.0` | `LITERAL_REAL(valor)` |
| Número inteiro | `10`, `100`, `42` | `LITERAL_INTEIRO(valor)` |
| String | `"olá mundo"` | `LITERAL_TEXTO(valor)` |

> **Prioridade:** A regra de `REAL` é declarada **antes** de `INTEIRO` no lexer, garantindo que `3.14` seja reconhecido como real, e não como dois tokens inteiros separados por ponto.

### 9.6 Operadores Aritméticos

| Lexema | Token |
|---|---|
| `+` | `OP_SOMA` |
| `-` | `OP_SUBTRACAO` |
| `*` | `OP_MULTIPLICACAO` |
| `/` | `OP_DIVISAO` |
| `%` | `OP_MODULO` |

### 9.7 Operadores Relacionais e Lógicos

| Lexema | Token |
|---|---|
| `=` | `SINAL_IGUALDADE` |
| `==` | `OP_IGUAL` |
| `!=` | `OP_DIFERENTE` |
| `>` | `OP_MAIOR` |
| `<` | `OP_MENOR` |
| `>=` | `OP_MAIOR_IGUAL` |
| `<=` | `OP_MENOR_IGUAL` |
| `&&` | `OP_LOGICO_E` |
| `\|\|` | `OP_LOGICO_OU` |
| `!` | `OP_LOGICO_NAO` |

### 9.8 Delimitadores e Pontuação

| Lexema | Token | Uso na linguagem |
|---|---|---|
| `;` | `PONTO_E_VIRGULA` | Terminador opcional de instruções |
| `,` | `VIRGULA` | Separador de parâmetros |
| `:` | `DOIS_PONTOS` | Separador nome:tipo na declaração |
| `->` | `SETA_RETORNO` | Indica tipo de retorno de função |
| `(` | `ABRE_PARENTESES` | Início de lista de parâmetros |
| `)` | `FECHA_PARENTESES` | Fim de lista de parâmetros |
| `[` | `ABRE_COLCHETES` | Início de índice de vetor |
| `]` | `FECHA_COLCHETES` | Fim de índice de vetor |

### 9.9 Identificadores

Qualquer sequência que comece com uma letra ASCII ou `_` e seja seguida de letras, dígitos ou underscores, **desde que não seja uma palavra reservada ou tipo**, é reconhecida como identificador.

**Padrão:** `{LETRA}({LETRA}|{DIGITO})*`

**Exemplos válidos:** `x`, `soma`, `pivo`, `inicio_vetor`, `QuickSort`, `numeros`

**Token emitido:** `IDENTIFICADOR(nome)` — ex.: `IDENTIFICADOR(pivo)`

> **Importante:** As palavras reservadas são declaradas **antes** dos identificadores no arquivo `lexer.l`. Como o Flex segue a ordem de declaração, `se` será reconhecido como `SE` e nunca como `IDENTIFICADOR(se)`.

---

## 10. Tratamento de Erros Léxicos

Qualquer caractere que não se enquadre em nenhuma das regras anteriores é capturado pela **regra curinga** `.` (ponto), que corresponde a qualquer caractere individual não reconhecido:

```lex
. {
    fprintf(stderr, "[ERRO L%d:C%d] Caractere invalido: '%s'\n",
            linha_atual, coluna_atual, yytext);
    coluna_atual++;
}
```

**Comportamento:** O analisador **não interrompe a execução** ao encontrar um erro. Ele emite a mensagem e **continua processando** o restante do arquivo, permitindo que múltiplos erros sejam identificados em uma única passagem.

**Exemplo prático:** Um caractere `@` fora de um texto ou comentário produz uma mensagem com linha e coluna:

```
[ERRO L3:C5] Caractere invalido: '@'
```

---

## 11 Especificação do Analisador Sintático

O arquivo `src/parser.y` converte a gramática EBNF da linguagem `.edu` em regras BNF legíveis pelo Bison (usando recursão à esquerda). A análise é feita no modelo Bottom-Up (LALR).

As principais estruturas validadas pelo analisador incluem:

### 11.1 Estrutura do Programa

Um programa válido exige uma lista opcional de subprogramas (procedimentos/funções) seguida obrigatoriamente pelo método principal:
```
program : subprograms main_program ;
main_program : PROCEDIMENTO MAIN ABRE_PARENTESES FECHA_PARENTESES INICIO stmts FIM ;
```

## 11.2 Declarações e Atribuições

Valida declarações de variáveis (simples ou vetores) e operações de atribuição:
``` 
decl : IDENTIFICADOR DOIS_PONTOS type array_decl_opt assign_opt ;
assign : var SINAL_IGUALDADE expr ;
```

## 11.3 Estruturas de Fluxo

Garante o fechamento correto dos blocos e expressões condicionais internas:
```
if_stmt : SE condition INICIO stmts FIM_SE
        | SE condition INICIO stmts SENAO INICIO stmts FIM_SE ;
loop_stmt : ENQUANTO condition INICIO stmts FIM_ENQUANTO ;
condition : ABRE_PARENTESES expr FECHA_PARENTESES ;
```

## 11.4 Precedência Matemática

As regras de expressão (`expr`, `term`, `factor`) estão estruturadas hierarquicamente para garantir que operações como multiplicação sejam processadas sintaticamente antes da soma, suportando também o agrupamento por parênteses.

---

## 12 Tratamento de Erros Sintáticos

Quando o Bison encontra um token em uma ordem que viola as regras gramaticais (ex: um `+` sem número depois, ou um bloco `se` sem `fim_se`), ele aciona automaticamente a função `yyerror`.

A nossa implementação personalizada desta função imprime o erro detalhado cruzando dados com o Flex:
```
void yyerror(const char *s) {
    fprintf(stderr, "[ERRO SINTATICO] Linha %d, Coluna %d: %s proximo a '%s'\n", 
            linha_atual, coluna_atual, s, yytext);
}
```

---

## 13. Exemplos de Saída

### Entrada (`exemplo.edu`)

```edu
procedimento main() inicio
    numero: Inteiro = 42

    se (numero > 0) inicio
        Escrever(numero)
    senao inicio
        Escrever("zero ou negativo")
    fim_se
fim
```

### Compilação

```bash
./compiler exemplo.edu exemplo.c
gcc exemplo.c -o exemplo
./exemplo
```

### Saída esperada

```text
[SUCESSO] Codigo C gerado em: exemplo.c
42
```

---

## 14. Arquivos de Teste

- `testes/quicksort.edu`: Implementação completa e válida do algoritmo QuickSort. Exercita recursividade, laços, condicionais e manipulação de vetores.

- `testes/quicksortERRO.edu`: Variante do código acima contendo erros sintáticos deliberados, usado para testar a captura de exceções do Bison.

- `testes/testes.edu`: Avaliação geral dos tipos, operações, laços e entrada/saída.

---

## 15. Referências

- [Manual do Bison — GNU Project](https://www.gnu.org/software/bison/manual/)
- [Manual do Flex — GNU Project](https://www.gnu.org/software/flex/manual/)
- [Compiladores: Princípios, Técnicas e Ferramentas — Aho, Lam, Sethi, Ullman](https://en.wikipedia.org/wiki/Compilers:_Principles,_Techniques,_and_Tools) *(Livro do Dragão)*
- Disciplina DIM0548 — Engenharia de Linguagens, UFRN

---
