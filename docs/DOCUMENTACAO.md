# 📖 Documentação — Analisador Léxico da Linguagem `.edu`

**Repositório:** [ViniciusProgrammer/DIM0548-LINGUAGEM-IMPERATIVA](https://github.com/ViniciusProgrammer/DIM0548-LINGUAGEM-IMPERATIVA)
**Disciplina:** DIM0548 — Engenharia de Linguagens
**Tecnologias:** Flex · GCC · Shell Script (Bash)

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
11. [Exemplos de Saída](#11-exemplos-de-saída)
12. [Arquivos de Teste](#12-arquivos-de-teste)
13. [Referências](#13-referências)

---

## 1. Visão Geral

Este projeto implementa um **analisador léxico** (*lexer* / *scanner*) para uma linguagem imperativa educacional chamada `.edu`. O analisador foi desenvolvido como trabalho prático da disciplina **DIM0548 — Engenharia de Linguagens** e representa a **primeira fase de um compilador**: a leitura do código-fonte para identificar e classificar unidades léxicas chamadas de **tokens**.

O lexer é capaz de:

- Reconhecer **palavras reservadas**, **tipos primitivos**, **literais** e **identificadores** da linguagem `.edu`
- Identificar todos os **operadores** (aritméticos, de atribuição composta, lógicos e relacionais) e **delimitadores**
- Processar **comentários** de linha e de bloco sem emitir tokens, **contando corretamente as quebras de linha internas** aos comentários de bloco
- **Rastrear linha e coluna** durante a análise via variáveis `linha_atual` e `coluna_atual`
- Reportar **erros léxicos** com posição exata (`[L:C]`) e continuar a análise
- Exibir um **sumário** ao final: total de tokens reconhecidos, linhas processadas e erros encontrados

---

## 2. Estrutura do Repositório

```
DIM0548-LINGUAGEM-IMPERATIVA/
│
├── src/
│   ├── lexer.l          # Especificação do analisador (Flex) — arquivo principal
│   └── lex.yy.c         # Código C gerado automaticamente pelo Flex (não editar)
│
├── docs/                # Documentação adicional
│
├── testes/
│   ├── quicksort.edu    # Programa QuickSort na linguagem .edu
│   └── testes.edu       # Arquivo de teste de estruturas, operadores e erros léxicos
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
| **GCC** | Compilador C que transforma o código gerado pelo Flex em executável binário |
| **Bash** | Automatiza o processo de build no script `compilar.sh` |

---

## 4. Pré-requisitos e Instalação

O projeto foi desenvolvido para **Linux**. É necessário ter o **Flex** e o **GCC** instalados.

**Ubuntu / Debian:**
```bash
sudo apt update && sudo apt install flex gcc -y
```

**Arch Linux:**
```bash
sudo pacman -S flex gcc
```

**Fedora / RHEL:**
```bash
sudo dnf install flex gcc
```

---

## 5. Como Compilar

O script `compilar.sh` automatiza todo o processo de build:

```bash
# Passo 1: Flex gera o código C a partir das regras do lexer
flex -o src/lex.yy.c src/lexer.l

# Passo 2: GCC compila o código C gerado em executável
# -lfl linka a biblioteca do Flex (necessária em algumas distribuições)
# -Wall ativa todos os avisos de compilação
gcc -Wall src/lex.yy.c -o analisador_lexico -lfl
```

**Para executar:**

```bash
chmod +x compilar.sh
./compilar.sh
```

---

## 6. Como Testar

O analisador lê o código-fonte pela **entrada padrão** (`stdin`):

```bash
./analisador_lexico < testes/quicksort.edu
./analisador_lexico < testes/testes.edu
```

Modo interativo (finalize com `Ctrl+D`):

```bash
./analisador_lexico
```

O código de saída é `0` se nenhum erro léxico foi encontrado e `1` caso contrário, permitindo uso em pipelines de CI:

```bash
./analisador_lexico < testes/testes.edu && echo "OK" || echo "Erros lexicos encontrados"
```

---

## 7. A Linguagem `.edu`

A linguagem `.edu` é uma linguagem imperativa educacional com sintaxe em português. Ela suporta:

- Declaração de variáveis com tipos explícitos
- Estruturas de controle (`se/senao/fim_se`, `enquanto/fim_enquanto`, `repetir/ate`)
- Definição de `procedimento` e `funcao` com parâmetros por referência (`ref`)
- Tipo de retorno de funções declarado com o operador `->`
- Instrução de retorno com `retorne`
- Vetores (arrays) com sintaxe `Tipo[tamanho]` e acesso por `vetor[i]`
- Literais booleanos (`Verdadeiro` / `Falso`)
- Declaração de constantes com `Constante`
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
  int linha_atual  = 1;   // Rastreia a linha atual no código-fonte
  int coluna_atual = 1;   // Rastreia a coluna atual na linha
  int total_tokens = 0;   // Contador de tokens reconhecidos com sucesso
  int total_erros  = 0;   // Contador de erros léxicos encontrados
%}

ESPACO      [ \t\r]+
DIGITO      [0-9]
LETRA       [a-zA-Z]
ID          {LETRA}({LETRA}|{DIGITO}|_)*
INTEIRO     {DIGITO}+
REAL        {DIGITO}+"."{DIGITO}+
TEXTO       \"([^\\\"\n]|\\.)*\"
```

**Macros de expressão regular definidas:**

| Macro | Padrão | Descrição |
|---|---|---|
| `ESPACO` | `[ \t\r]+` | Espaços, tabs e retorno de carro |
| `DIGITO` | `[0-9]` | Um dígito numérico |
| `LETRA` | `[a-zA-Z]` | Uma letra maiúscula ou minúscula |
| `ID` | `{LETRA}({LETRA}\|{DIGITO}\|_)*` | Identificador: começa com letra, seguido de letras, dígitos ou `_` |
| `INTEIRO` | `{DIGITO}+` | Um ou mais dígitos |
| `REAL` | `{DIGITO}+"."{DIGITO}+` | Número com ponto decimal obrigatório |
| `TEXTO` | `\"([^\\\"\n]\|\\.)* \"` | String entre aspas duplas; não permite quebra de linha literal |

> **Nota sobre `TEXTO`:** O padrão exclui `\n` literal dentro de strings (representado por `[^\\\"\n]`). Isso impede que uma aspa de fechamento esquecida "engula" linhas inteiras do arquivo, gerando mensagens de erro mais claras.

### Seção 2 — Regras de Reconhecimento

Cada regra associa um padrão (expressão regular) a uma ação em C. O Flex aplica a regra do **maximal munch** (casa sempre o padrão mais longo) e, em caso de empate de comprimento, a regra declarada primeiro. Por isso, operadores compostos (`==`, `!=`, `>=`, `<=`, `->`) são declarados **antes** de seus prefixos simples (`=`, `!`, `>`, `<`, `-`).

### Seção 3 — Código C Auxiliar

```c
#ifndef yywrap
int yywrap(void) { return 1; }
#endif

int main(void) {
    yylex();
    // Exibe sumário ao final
    printf("\n--- Analise concluida ---\n");
    printf("Linhas processadas : %d\n", linha_atual);
    printf("Tokens reconhecidos: %d\n", total_tokens);
    // ...
    return (total_erros > 0) ? 1 : 0;
}
```

---

## 9. Tokens Reconhecidos

Todos os tokens são exibidos com prefixo de posição no formato `[L<linha>:C<coluna>]`:

```
[L3:C5] IDENTIFICADOR(pivo)
[L3:C9] SINAL_IGUALDADE
```

### 9.1 Espaços e Quebras de Linha

| Padrão | Ação |
|---|---|
| Espaços, tabs (`\t`) e `\r` | Ignorados; `coluna_atual` avança |
| Quebra de linha (`\n`) | `linha_atual++`; `coluna_atual` volta para 1 |

### 9.2 Comentários

| Tipo | Sintaxe | Token emitido | Observação |
|---|---|---|---|
| Linha | `// texto até fim da linha` | Nenhum | `coluna_atual` avança |
| Bloco | `/* texto em múltiplas linhas */` | Nenhum | Newlines internos **incrementam** `linha_atual` |

> **Importante:** Comentários de bloco não emitem token, mas o lexer lê o conteúdo caractere a caractere para manter `linha_atual` correto. Tokens após um comentário de bloco multilinha reportam a linha exata.

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
| `retorne` | `RETORNE` | Instrução de retorno de valor (**forma canônica**) |
| `retornar` | `RETORNE` + aviso | **Depreciado** — emite aviso no `stderr`; use `retorne` |
| `ref` | `MODIFICADOR_REF` | Passagem de argumento por referência |

> **Sobre `retorne` vs `retornar`:** Ambas as formas produzem o mesmo token `RETORNE`, mas `retornar` gera um aviso de depreciação em `stderr`. A forma canônica da linguagem `.edu` é `retorne`. Código que usa `retornar` continua funcionando, mas deve ser migrado.

### 9.4 Tipos Primitivos

> **Convenção:** todos os tipos na linguagem `.edu` começam com letra **maiúscula**, diferenciando-os de identificadores comuns.

| Lexema | Token |
|---|---|
| `Inteiro` | `TIPO_INTEIRO` |
| `Real` | `TIPO_REAL` |
| `Texto` | `TIPO_TEXTO` |
| `Booleano` | `TIPO_BOOLEANO` |
| `Constante` | `CONSTANTE` (**forma canônica**) |
| `constante` | `CONSTANTE` + aviso | 

> **Sobre `Constante`:** A forma com inicial minúscula (`constante`) é aceita com aviso de depreciação em `stderr` para compatibilidade retroativa. A forma canônica é `Constante`, em linha com a convenção dos demais tipos.

### 9.5 Literais

| Categoria | Exemplos | Token emitido |
|---|---|---|
| Booleano verdadeiro | `Verdadeiro` | `LITERAL_BOOLEANO(Verdadeiro)` |
| Booleano falso | `Falso` | `LITERAL_BOOLEANO(Falso)` |
| Número real | `3.14`, `0.5`, `100.0` | `LITERAL_REAL(valor)` |
| Número inteiro | `10`, `100`, `42` | `LITERAL_INTEIRO(valor)` |
| String | `"olá mundo"` | `LITERAL_TEXTO(valor)` |

> **Prioridade:** A regra de `REAL` é declarada **antes** de `INTEIRO`, garantindo que `3.14` seja reconhecido como real e não como dois tokens separados por ponto.

> **Números negativos:** O lexer não reconhece literais negativos. `-3` é tokenizado como `OP_SUBTRACAO` + `LITERAL_INTEIRO(3)`. O parser é responsável por interpretar o sinal unário.

### 9.6 Operadores Aritméticos

| Lexema | Token |
|---|---|
| `+` | `OP_SOMA` |
| `-` | `OP_SUBTRACAO` |
| `*` | `OP_MULTIPLICACAO` |
| `/` | `OP_DIVISAO` |
| `%` | `OP_MODULO` |

### 9.7 Operadores de Atribuição Composta

| Lexema | Token | Equivalente |
|---|---|---|
| `+=` | `OP_ATRIB_SOMA` | `x = x + y` |
| `-=` | `OP_ATRIB_SUB` | `x = x - y` |
| `*=` | `OP_ATRIB_MUL` | `x = x * y` |
| `/=` | `OP_ATRIB_DIV` | `x = x / y` |

> **Nota:** Esses tokens são declarados **antes** de `+`, `-`, `*`, `/` e `=` no lexer, garantindo que `+=` nunca seja interpretado como `OP_SOMA` + `SINAL_IGUALDADE`.

### 9.8 Operadores Relacionais e Lógicos

> **Nota sobre ordem de declaração:** Operadores compostos (`==`, `!=`, `>=`, `<=`) são declarados antes de seus prefixos (`=`, `!`, `>`, `<`) para tornar a intenção explícita, mesmo que o Flex já resolva corretamente via maximal munch.

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

### 9.9 Delimitadores e Pontuação

| Lexema | Token | Uso na linguagem |
|---|---|---|
| `;` | `PONTO_E_VIRGULA` | Separador de instruções |
| `,` | `VIRGULA` | Separador de parâmetros |
| `:` | `DOIS_PONTOS` | Separador nome:tipo na declaração |
| `->` | `SETA_RETORNO` | Indica tipo de retorno de função |
| `(` | `ABRE_PARENTESES` | Início de lista de parâmetros |
| `)` | `FECHA_PARENTESES` | Fim de lista de parâmetros |
| `[` | `ABRE_COLCHETES` | Início de índice de vetor |
| `]` | `FECHA_COLCHETES` | Fim de índice de vetor |
| `{` | `ABRE_CHAVES` | Delimitador de bloco alternativo |
| `}` | `FECHA_CHAVES` | Delimitador de bloco alternativo |

> **Sobre `->` e `-`:** `->` é declarado antes de `-` no lexer. Escrever `- >` (com espaço entre os dois caracteres) produz `OP_SUBTRACAO` + `OP_MAIOR` — não `SETA_RETORNO`. A seta de retorno exige os dois caracteres contíguos.

### 9.10 Identificadores

Qualquer sequência que comece com uma letra e seja seguida de letras, dígitos ou underscores, **desde que não seja uma palavra reservada ou tipo**, é reconhecida como identificador.

**Padrão:** `{LETRA}({LETRA}|{DIGITO}|_)*`

**Exemplos válidos:** `x`, `soma`, `pivo`, `inicio_vetor`, `QuickSort`, `numeros`

**Token emitido:** `IDENTIFICADOR(nome)` — ex.: `[L5:C5] IDENTIFICADOR(pivo)`

> As palavras reservadas são declaradas **antes** dos identificadores. Como o Flex casa o padrão mais longo, `inicio_vetor` (14 chars) sempre vence `inicio` (6 chars), sendo reconhecido como `IDENTIFICADOR(inicio_vetor)`.

---

## 10. Tratamento de Erros Léxicos

Qualquer caractere que não se enquadre em nenhuma regra é capturado pela **regra curinga** `.`:

```lex
.   { fprintf(stderr, "[ERRO L%d:C%d] Caractere invalido: '%s'\n",
              linha_atual, coluna_atual, yytext);
      coluna_atual++;
      total_erros++;
    }
```

**Comportamento:**
- O analisador **não interrompe** ao encontrar um erro — continua processando o restante do arquivo
- A mensagem vai para `stderr`, separada da saída de tokens (`stdout`), permitindo redirecionamentos independentes
- `total_erros` é incrementado e refletido no código de saída (`return 1` se `total_erros > 0`)

**Exemplo:**

```
[ERRO L13:C3] Caractere invalido: '@'
```

---

## 11. Exemplos de Saída

### Entrada (`testes.edu` — trecho)

```
inicio
  Inteiro numero
  numero += 5
  @
fim
```

### Saída esperada (`stdout`)

```
[L1:C1] INICIO
[L2:C3] TIPO_INTEIRO
[L2:C11] IDENTIFICADOR(numero)
[L3:C3] IDENTIFICADOR(numero)
[L3:C10] OP_ATRIB_SOMA
[L3:C13] LITERAL_INTEIRO(5)
[L5:C1] FIM

--- Analise concluida ---
Linhas processadas : 5
Tokens reconhecidos: 7
Erros lexicos      : 0
```

### Saída de erro (`stderr`)

```
[ERRO L4:C3] Caractere invalido: '@'
```

---

## 12. Arquivos de Teste

### `testes/quicksort.edu` — QuickSort

Implementação completa do algoritmo **QuickSort** na linguagem `.edu`. Exercita:

- `procedimento` com parâmetro por referência (`ref vetor: Inteiro[]`)
- `funcao` com tipo de retorno via `->` (`-> Inteiro`)
- Instrução `retorne` (forma canônica)
- Acesso a vetores (`vetor[i]`, `vetor[j]`)
- Laço `enquanto / fim_enquanto` com condição relacional
- Condicional `se / fim_se` dentro de laço
- Chamadas recursivas
- Expressões aritméticas (`i + 1`, `pivo - 1`)

### `testes/testes.edu` — Testes Gerais

Arquivo de verificação abrangente. Contém:

- Todos os tipos primitivos incluindo `Constante`
- Literais inteiro, real, texto e booleano
- Operadores aritméticos incluindo `%` (módulo)
- Operadores de atribuição composta (`+=`, `-=`, `*=`, `/=`)
- Operadores relacionais e lógicos
- Estruturas de controle aninhadas
- Laço `repetir / ate`
- Comentário de bloco multilinha (para validar contagem de linhas)
- Caractere inválido `@` para validar continuidade após erro léxico

---

## 13. Referências

- [Manual do Flex — GNU Project](https://www.gnu.org/software/flex/manual/)
- [Compiladores: Princípios, Técnicas e Ferramentas — Aho, Lam, Sethi, Ullman](https://en.wikipedia.org/wiki/Compilers:_Principles,_Techniques,_and_Tools) *(Livro do Dragão)*
- Disciplina DIM0548 — Engenharia de Linguagens, UFRN - 2026

---
