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
- Identificar todos os **operadores** (aritméticos, lógicos e relacionais) e **delimitadores**
- Processar **comentários** de linha e de bloco sem emitir tokens
- **Rastrear o número de linhas** durante a análise via variável `linha_atual`
- Reportar **erros léxicos** com mensagens claras para qualquer caractere inválido encontrado

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
│   ├── quisort.edu      # Programa QuickSort na linguagem .edu
│   └── testes.edu       # Arquivo de teste de estruturas e erros léxicos
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

**Distribuição de linguagens no repositório:**

- Lex (`.l`): **96,2%**
- Shell (`.sh`): **3,8%**

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

O script `compilar.sh` automatiza todo o processo de build em dois passos:

```bash
# Passo 1: Flex gera o código C a partir das regras do lexer
flex -o src/lex.yy.c src/lexer.l

# Passo 2: GCC compila o código C gerado em executável
gcc src/lex.yy.c -o analisador_lexico
```

**Para executar:**

```bash
# Na raiz do repositório
chmod +x compilar.sh
./compilar.sh
```

Ao final, será exibida a mensagem `Compilacao concluida com sucesso!` e o executável `analisador_lexico` estará disponível na raiz do projeto.

---

## 6. Como Testar

O analisador lê o código-fonte pela **entrada padrão** (`stdin`). Use a redireção `<` para passar um arquivo:

```bash
# Testar com o QuickSort
./analisador_lexico < testes/quisort.edu

# Testar com o arquivo de testes gerais
./analisador_lexico < testes/testes.edu

# Testar com qualquer outro arquivo .edu
./analisador_lexico < caminho/para/programa.edu
```

Também é possível testar em modo interativo — o lexer lê do teclado e exibe os tokens em tempo real (finalize com `Ctrl+D`):

```bash
./analisador_lexico
```

---

## 7. A Linguagem `.edu`

A linguagem `.edu` é uma linguagem imperativa educacional com sintaxe em português. Ela suporta:

- Declaração de variáveis com tipos explícitos
- Estruturas de controle (`se/senao/fim_se`, `enquanto/fim_enquanto`, `repetir/ate`)
- Definição de `procedimento` e `funcao` com parâmetros por referência (`ref`)
- Tipo de retorno de funções declarado com o operador `->`
- Vetores (arrays) com sintaxe `Tipo[tamanho]` e acesso por `vetor[i]`
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
LETRA       [a-zA-Z]
ID          {LETRA}({LETRA}|{DIGITO}|_)*
INTEIRO     {DIGITO}+
REAL        {DIGITO}+"."{DIGITO}+
TEXTO       \"([^\\\"]|\\.)*\"
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
| `TEXTO` | `\"([^\\\"]|\\.)*\"` | String entre aspas duplas com suporte a sequências de escape |

### Seção 2 — Regras de Reconhecimento

Cada regra associa um padrão (expressão regular) a uma ação em C. O Flex aplica a primeira regra que corresponde ao texto atual, na ordem em que estão declaradas.

### Seção 3 — Código C Auxiliar

```c
#ifndef yywrap
int yywrap(void) { return 1; }  // Sinaliza fim da entrada para o Flex
#endif

int main(void) {
    yylex();   // Inicia a análise léxica
    return 0;
}
```

---

## 9. Tokens Reconhecidos

### 9.1 Espaços e Quebras de Linha

| Padrão | Ação |
|---|---|
| Espaços, tabs (`\t`) e `\r` | Ignorados silenciosamente |
| Quebra de linha (`\n`) | Incrementa `linha_atual` para rastreamento de posição |

### 9.2 Comentários

| Tipo | Sintaxe | Token emitido |
|---|---|---|
| Linha | `// texto até fim da linha` | `COMENTARIO_LINHA_IGNORADO` |
| Bloco | `/* texto em múltiplas linhas */` | `COMENTARIO_BLOCO_IGNORADO` |

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

### 9.4 Tipos Primitivos

> **Atenção:** Na linguagem `.edu`, os tipos começam com letra **maiúscula**, diferenciando-os de identificadores comuns.

| Lexema | Token |
|---|---|
| `Inteiro` | `TIPO_INTEIRO` |
| `Real` | `TIPO_REAL` |
| `Texto` | `TIPO_TEXTO` |
| `Booleano` | `TIPO_BOOLEANO` |
| `constante` | `CONSTANTE` |

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

### 9.9 Identificadores

Qualquer sequência que comece com uma letra e seja seguida de letras, dígitos ou underscores, **desde que não seja uma palavra reservada ou tipo**, é reconhecida como identificador.

**Padrão:** `{LETRA}({LETRA}|{DIGITO}|_)*`

**Exemplos válidos:** `x`, `soma`, `pivo`, `inicio_vetor`, `QuickSort`, `numeros`

**Token emitido:** `IDENTIFICADOR(nome)` — ex.: `IDENTIFICADOR(pivo)`

> **Importante:** As palavras reservadas são declaradas **antes** dos identificadores no arquivo `lexer.l`. Como o Flex segue a ordem de declaração, `se` será reconhecido como `SE` e nunca como `IDENTIFICADOR(se)`.

---

## 10. Tratamento de Erros Léxicos

Qualquer caractere que não se enquadre em nenhuma das regras anteriores é capturado pela **regra curinga** `.` (ponto), que corresponde a qualquer caractere individual não reconhecido:

```lex
.   { printf("Charactere Invalido.\n"); }
```

**Comportamento:** O analisador **não interrompe a execução** ao encontrar um erro. Ele emite a mensagem e **continua processando** o restante do arquivo, permitindo que múltiplos erros sejam identificados em uma única passagem.

**Exemplo prático:** O caractere `@` no arquivo `testes.edu` é propositalmente inválido e produz a saída:

```
Charactere Invalido.
```

---

## 11. Exemplos de Saída

### Entrada (`testes.edu`)

```
inicio
  Inteiro numero
  Texto palavra
  Real nota

  se Verdadeiro inicio
    enquanto Falso inicio
      numero
    fim_enquanto
  fim_se

  @
fim
```

### Saída esperada

```
INICIO
TIPO_INTEIRO
IDENTIFICADOR(numero)
TIPO_TEXTO
IDENTIFICADOR(palavra)
TIPO_REAL
IDENTIFICADOR(nota)
COMENTARIO_LINHA_IGNORADO
SE
LITERAL_BOOLEANO(Verdadeiro)
INICIO
ENQUANTO
LITERAL_BOOLEANO(Falso)
INICIO
IDENTIFICADOR(numero)
FIM_ENQUANTO
FIM_SE
Charactere Invalido.
FIM
```

---

## 12. Arquivos de Teste

### `testes/quisort.edu` — QuickSort

Implementação completa do algoritmo **QuickSort** na linguagem `.edu`. Exercita as principais construções da linguagem:

- `procedimento` com parâmetro por referência (`ref vetor: Inteiro[]`)
- `funcao` com tipo de retorno declarado via `->` (`-> Inteiro`)
- Acesso a elementos de vetor (`vetor[i]`, `vetor[j]`)
- Laço `enquanto / fim_enquanto` com condição relacional
- Condicional `se / fim_se` dentro de laço
- Chamadas recursivas (`QuickSort(vetor, inicio_vetor, pivo - 1)`)
- Comentários de linha (`//`) em múltiplos pontos
- Expressões aritméticas (`i + 1`, `pivo - 1`)

### `testes/testes.edu` — Testes Gerais

Arquivo de verificação geral do analisador. Contém:

- Declarações dos tipos `Inteiro`, `Texto` e `Real`
- Literais booleanos `Verdadeiro` e `Falso`
- Estruturas de controle aninhadas (`se` dentro de `enquanto`)
- Um caractere inválido (`@`) propositalmente inserido para validar o tratamento de erro léxico sem interrupção da análise

---

## 13. Referências

- [Manual do Flex — GNU Project](https://www.gnu.org/software/flex/manual/)
- [Compiladores: Princípios, Técnicas e Ferramentas — Aho, Lam, Sethi, Ullman](https://en.wikipedia.org/wiki/Compilers:_Principles,_Techniques,_and_Tools) *(Livro do Dragão)*
- Disciplina DIM0548 — Engenharia de Linguagens, UFRN

---

