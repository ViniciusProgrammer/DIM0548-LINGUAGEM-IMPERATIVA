# 📖 Documentação — Compilador da Linguagem Imperativa `.edu`

**Repositório:** DIM0548-LINGUAGEM-IMPERATIVA  
**Disciplina:** DIM0548 — Engenharia de Linguagens — UFRN  
**Tecnologias:** Flex · Bison · GCC · Make  

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Estrutura do Repositório](#2-estrutura-do-repositório)
3. [Pré-requisitos e Build](#3-pré-requisitos-e-build)
4. [Como Usar o Compilador](#4-como-usar-o-compilador)
5. [A Linguagem `.edu`](#5-a-linguagem-edu)
6. [Análise Léxica](#6-análise-léxica)
7. [Análise Sintática](#7-análise-sintática)
8. [Análise Semântica e Tabela de Símbolos](#8-análise-semântica-e-tabela-de-símbolos)
9. [Geração de Código C](#9-geração-de-código-c)
10. [Testes](#10-testes)
11. [Exemplos Completos](#11-exemplos-completos)
12. [Limitações Conhecidas](#12-limitações-conhecidas)
13. [Referências](#13-referências)

---

## 1. Visão Geral

Este projeto implementa um **compilador completo** para a linguagem imperativa educacional `.edu`, traduzindo programas escritos em português para um subconjunto restrito de C. O objetivo pedagógico é duplo: a linguagem `.edu` ensina lógica de programação a iniciantes em português; o compilador em si é o produto prático da disciplina de Engenharia de Linguagens.

O fluxo de compilação passa pelas quatro fases clássicas:

```
fonte.edu  →  [Léxico]  →  tokens
           →  [Sintático]  →  AST implícita
           →  [Semântico]  →  código C anotado
           →  [Geração]  →  saida.c
                             ↓
                           gcc → binário
```

O compilador retorna `0` em caso de sucesso e `1` quando há qualquer erro léxico, sintático ou semântico. O arquivo C de saída só é publicado quando todas as fases passam sem erros.

---

## 2. Estrutura do Repositório

```
DIM0548-LINGUAGEM-IMPERATIVA/
│
├── src/
│   ├── lexer.l              # Especificação Flex do analisador léxico
│   ├── parser.y             # Gramática Bison com ações semânticas e geração de código
│   ├── lex.yy.c             # Gerado pelo Flex (não editar)
│   ├── y.tab.c              # Gerado pelo Bison (não editar)
│   └── y.tab.h              # Cabeçalho de tokens gerado pelo Bison (não editar)
│
├── tabela/
│   ├── tabela_simbolos.h    # Interface da tabela de símbolos
│   └── tabela_simbolos.c    # Implementação: hash, escopos, tipos, parâmetros
│
├── lib/
│   ├── labels.h / labels.c  # Gerador de rótulos para goto/labels no C gerado
│   └── record.h / record.c  # Estrutura record (code + opt1) usada nas ações do parser
│
├── problemas/
│   ├── problema01.edu       # Expressão com número racional
│   ├── problema02.edu       # Contagem por intervalos
│   ├── problema03.edu       # Soma e produto de matrizes
│   ├── problema04.edu       # Tipo rational_t com operações
│   ├── problema05.edu       # QuickSort com passagem por referência
│   └── problema06.edu       # Árvore binária de busca com vetores paralelos
│
├── testes/
│   ├── testes.edu                  # Cobertura geral da sintaxe (positivo)
│   ├── registro.edu                # Tipos definidos pelo usuário (positivo)
│   ├── quicksort.edu               # QuickSort completo (positivo)
│   ├── recursos_secundarios.edu    # alias, enum, para (positivo)
│   ├── ref_escalar.edu             # Passagem por referência escalar (positivo)
│   ├── erro_lexico.edu             # Caractere inválido @ (negativo)
│   ├── erro_semantico.edu          # Atribuição de tipo incompatível (negativo)
│   ├── registroERRO.edu            # Campo inexistente em registro (negativo)
│   ├── quicksortERRO.edu           # Erros sintáticos no QuickSort (negativo)
│   ├── assinatura_ref_erro.edu     # Argumento ref não enderecável (negativo)
│   ├── chamada_assinatura_erro.edu # Tipo errado em chamada de função (negativo)
│   ├── constante_erro.edu          # Alteração de constante (negativo)
│   └── vetor_indice_erro.edu       # Índice literal fora dos limites (negativo)
│
├── makefile
├── compilar.sh
└── README.md
```

---

## 3. Pré-requisitos e Build

### Dependências

```bash
# Ubuntu / Debian
sudo apt update && sudo apt install flex bison gcc make -y

# Arch Linux
sudo pacman -S flex bison gcc make

# Fedora / RHEL
sudo dnf install flex bison gcc make
```

### Compilar o compilador

```bash
make              # gera ./compiler
```

O Makefile executa automaticamente:

1. `bison -d src/parser.y -o src/y.tab.c` — gera o parser e `y.tab.h`
2. `flex -o src/lex.yy.c src/lexer.l` — gera o scanner
3. `gcc` linkando `lex.yy.c`, `y.tab.c`, `tabela_simbolos.c`, `labels.c` e `record.c`

### Targets disponíveis

| Comando | Descrição |
|---|---|
| `make` | Compila o executável `./compiler` |
| `make problemas` | Compila os seis programas de avaliação em `saidas/` |
| `make test` | Executa testes positivos, negativos e QuickSort |
| `make rodar` | Executa todos os binários compilados com entradas de exemplo |
| `make clean` | Remove artefatos gerados (objetos, binários, C gerado) |
| `make clean_all` | Remove também a pasta `saidas/` |

---

## 4. Como Usar o Compilador

```bash
# Uso básico
./compiler <entrada.edu> <saida.c>

# Exemplo completo
./compiler testes/quicksort.edu /tmp/quicksort.c
gcc /tmp/quicksort.c -o /tmp/quicksort
/tmp/quicksort
```

**Saídas possíveis:**

```
[SUCESSO] Codigo C gerado em: saida.c
```

```
[FALHA] Erros encontrados: 1 lexico(s), 0 sintatico(s), 2 semantico(s).
```

O compilador nunca sobrescreve um arquivo C de saída com código inválido. Se houver qualquer erro, o arquivo de saída é removido.

---

## 5. A Linguagem `.edu`

### 5.1 Filosofia

A linguagem `.edu` foi projetada para o ensino introdutório de lógica de programação para o público brasileiro. Suas prioridades, em ordem, são: **legibilidade**, **facilidade de escrita**, **confiabilidade** e **custo de aprendizado reduzido**. A sintaxe é totalmente em português e estruturada por palavras-chave em vez de símbolos.

### 5.2 Tipos primitivos

| Palavra-chave | Tipo C equivalente | Descrição |
|---|---|---|
| `Inteiro` | `int` | Número inteiro |
| `Real` | `float` | Número de ponto flutuante |
| `Texto` | `char*` | Cadeia de caracteres |
| `Booleano` | `int` | Valor lógico (`Verdadeiro`/`Falso`) |
| `Vazio` | `void` | Ausência de retorno |

### 5.3 Literais

| Exemplo | Tipo inferido |
|---|---|
| `42` | `Inteiro` |
| `3.14` | `Real` |
| `"ola mundo"` | `Texto` |
| `Verdadeiro` | `Booleano` (vale `1`) |
| `Falso` | `Booleano` (vale `0`) |

### 5.4 Declaração de variáveis e constantes

```edu
nome: Tipo
nome: Tipo = expressão
Constante NOME: Tipo = expressão

// Vetores e matrizes
vetor: Inteiro[10]
matriz: Real[3][4]
```

Constantes são obrigatoriamente inicializadas na declaração e não podem ser alteradas posteriormente.

### 5.5 Tipos definidos pelo usuário

**Registros:**
```edu
tipo Pessoa inicio
    nome: Texto
    idade: Inteiro
fim
```

**Aliases:**
```edu
alias Numero = Inteiro
```

**Enumerações:**
```edu
enum Cor inicio
    VERMELHO,
    VERDE,
    AZUL
fim
```

### 5.6 Operadores

| Categoria | Operadores |
|---|---|
| Aritméticos | `+` `-` `*` `/` `%` |
| Relacionais | `==` `!=` `<` `>` `<=` `>=` |
| Lógicos | `&&` `\|\|` `!` |
| Atribuição | `=` `+=` `-=` `*=` `/=` |
| Concatenação | `+` (entre dois `Texto`) |

Regras de tipo para operadores:
- Operadores aritméticos exigem operandos numéricos (`Inteiro` ou `Real`).
- `Inteiro / Inteiro` produz `Inteiro` (divisão inteira preservada).
- Se qualquer operando for `Real`, o resultado é `Real`.
- `&&` e `||` exigem e produzem `Booleano`; implementam curto-circuito via semântica de C.
- `+` entre dois `Texto` gera concatenação com `edu_concat()` no C gerado.
- Atribuição é sempre um **comando**, nunca uma expressão — sem efeitos colaterais em expressões.

### 5.7 Estruturas de controle

**Condicional:**
```edu
se (condicao) inicio
    // ramo verdadeiro
fim_se

se (condicao) inicio
    // ramo verdadeiro
senao inicio
    // ramo falso
fim_se
```

**Laço com pré-teste:**
```edu
enquanto (condicao) inicio
    // corpo
fim_enquanto
```

**Laço com pós-teste:**
```edu
repetir
    // corpo
ate (condicao)
```

**Laço contado:**
```edu
para (i = 0; i < 10; i = i + 1) inicio
    // corpo
fim_para
```

### 5.8 Subprogramas

**Procedimento** (sem retorno):
```edu
procedimento NomeProc(param1: Tipo1, ref param2: Tipo2) inicio
    // corpo
fim
```

**Função** (com retorno):
```edu
funcao NomeFunc(param1: Tipo1) -> TipoRetorno inicio
    // corpo
    retorne expressão
fim
```

**Passagem por referência:** o modificador `ref` antes do nome do parâmetro indica passagem por referência. O compilador emite `*` na assinatura C, `&` na chamada e `(*var)` nos usos internos.

**Arrays como parâmetros:** declarados com `[]` após o tipo:
```edu
procedimento Trocar(ref vetor: Inteiro[], i: Inteiro, j: Inteiro) inicio
    aux: Inteiro = vetor[i]
    vetor[i] = vetor[j]
    vetor[j] = aux
fim
```

### 5.9 Entrada e saída

```edu
Escrever(expressao)           // imprime com quebra de linha
EscreverSemQuebra(expressao)  // imprime sem quebra
Ler(variavel)                 // lê da entrada padrão
```

### 5.10 Estrutura de um programa

Todo programa `.edu` termina obrigatoriamente com o procedimento `main`:

```edu
// Declarações de tipos (opcional)
tipo ...
alias ...
enum ...

// Subprogramas (opcional)
funcao ...
procedimento ...

// Programa principal (obrigatório)
procedimento main() inicio
    // corpo
fim
```

---

## 6. Análise Léxica

### 6.1 Arquivo: `src/lexer.l`

O analisador léxico é gerado pelo **Flex**. Ele rastreia linha e coluna para mensagens de erro precisas.

### 6.2 Definições de padrões

| Macro | Expressão regular | Descrição |
|---|---|---|
| `ESPACO` | `[ \t\r]+` | Espaços em branco |
| `DIGITO` | `[0-9]` | Dígito decimal |
| `LETRA` | `[a-zA-Z_]` | Letra ou underscore |
| `ID` | `{LETRA}({LETRA}\|{DIGITO})*` | Identificador |
| `INTEIRO` | `{DIGITO}+` | Literal inteiro |
| `REAL` | `{DIGITO}+"."{DIGITO}+` | Literal real |
| `TEXTO` | `\"([^\\\"\n]\|\\.)*\"` | String com escapes |

### 6.3 Comentários

```edu
// Comentário de linha

/* Comentário
   de bloco */
```

Ambos são silenciosamente descartados; quebras de linha dentro de blocos atualizam o contador de linhas.

### 6.4 Palavras reservadas

| Lexema | Token | Uso |
|---|---|---|
| `se` | `SE` | Condicional |
| `senao` | `SENAO` | Ramo alternativo |
| `fim_se` | `FIM_SE` | Fecha condicional |
| `enquanto` | `ENQUANTO` | Laço com pré-teste |
| `fim_enquanto` | `FIM_ENQUANTO` | Fecha laço |
| `para` | `PARA` | Laço contado |
| `fim_para` | `FIM_PARA` | Fecha laço contado |
| `repetir` | `REPETIR` | Laço com pós-teste |
| `ate` | `ATE` | Condição pós-teste |
| `inicio` | `INICIO` | Abre bloco |
| `fim` | `FIM` | Fecha bloco |
| `procedimento` | `PROCEDIMENTO` | Define procedimento |
| `funcao` | `FUNCAO` | Define função |
| `retorne` | `RETORNE` | Retorna valor |
| `ref` | `MODIFICADOR_REF` | Passagem por referência |
| `main` | `MAIN` | Programa principal |
| `Constante` | `CONSTANTE` | Declara constante |
| `tipo` | `TIPO` | Declara registro |
| `alias` | `ALIAS` | Declara alias de tipo |
| `enum` | `ENUM` | Declara enumeração |
| `Escrever` | `ESCREVER` | Saída com newline |
| `EscreverSemQuebra` | `ESCREVER_SEM_QUEBRA` | Saída sem newline |
| `Ler` | `LER` | Entrada padrão |

### 6.5 Tipos primitivos como tokens

Os nomes de tipos carregam seu valor de string para o parser:

| Lexema | Token |
|---|---|
| `Inteiro` | `TIPO_INTEIRO` |
| `Real` | `TIPO_REAL` |
| `Texto` | `TIPO_TEXTO` |
| `Booleano` | `TIPO_BOOLEANO` |

### 6.6 Operadores e delimitadores

| Lexema | Token |
|---|---|
| `==` | `OP_IGUAL` |
| `!=` | `OP_DIFERENTE` |
| `>=` | `OP_MAIOR_IGUAL` |
| `<=` | `OP_MENOR_IGUAL` |
| `&&` | `OP_LOGICO_E` |
| `\|\|` | `OP_LOGICO_OU` |
| `->` | `SETA_RETORNO` |
| `+=` | `OP_ATRIB_SOMA` |
| `-=` | `OP_ATRIB_SUB` |
| `*=` | `OP_ATRIB_MUL` |
| `/=` | `OP_ATRIB_DIV` |
| `+` `-` `*` `/` `%` | operadores aritméticos |
| `=` | `SINAL_IGUALDADE` |
| `>` `<` `!` | operadores relacionais/lógico |
| `;` `,` `:` `.` | delimitadores |
| `(` `)` `[` `]` | agrupadores |

**Ordem importa no Flex:** operadores compostos (`==`, `!=`, etc.) são declarados antes dos simples (`=`, `!`) para garantir o casamento mais longo.

### 6.7 Tratamento de erro léxico

```c
. {
    erros_lexicos++;
    fprintf(stderr, "[ERRO L%d:C%d] Caractere invalido: '%s'\n",
            linha_atual, coluna_atual, yytext);
    coluna_atual++;
}
```

O caractere inválido é descartado e a análise continua para localizar mais erros. O contador `erros_lexicos` impede que o código C seja gerado ao final.

**Exemplo:**
```
[ERRO L3:C5] Caractere invalido: '@'
```

---

## 7. Análise Sintática

### 7.1 Arquivo: `src/parser.y`

O parser LALR(1) é gerado pelo **Bison**. Cada produção gramatical carrega ações semânticas em C que produzem fragmentos de código C armazenados em registros `record { char* code; char* opt1; }`.

### 7.2 Gramática simplificada (EBNF)

```ebnf
program           = type_declarations subprograms main_program

type_declarations = { type_declaration }
type_declaration  = "tipo" ID "inicio" field_declarations "fim"
                  | "alias" ID "=" type
                  | "enum"  ID "inicio" enum_items "fim"

subprograms       = { subprogram }
subprogram        = sub_type ID "(" param_list_opt ")" return_type_opt block

sub_type          = "procedimento" | "funcao"
return_type_opt   = [ "->" type ]
param_list_opt    = [ param { "," param } ]
param             = [ "ref" ] ID ":" type [ "[]" ]

main_program      = "procedimento" "main" "(" ")" block

block             = "inicio" stmts "fim"
stmts             = { stmt [ ";" ] }

stmt              = decl | assign | call_stmt | if_stmt
                  | loop_stmt | for_stmt | return_stmt | io_stmt

decl              = ID ":" type [ array_decl ] [ "=" expr ]
                  | "Constante" ID ":" type "=" expr

assign            = var assign_op expr
assign_op         = "=" | "+=" | "-=" | "*=" | "/="

if_stmt           = "se" condition block_start stmts "fim_se"
                  | "se" condition block_start stmts "senao" block_start stmts "fim_se"

loop_stmt         = "enquanto" condition block_start stmts "fim_enquanto"
                  | "repetir" stmts "ate" condition

for_stmt          = "para" "(" for_assign ";" expr ";" for_assign ")" block_start stmts "fim_para"

return_stmt       = "retorne" expr
io_stmt           = "Escrever" "(" expr ")"
                  | "EscreverSemQuebra" "(" expr ")"
                  | "Ler" "(" var ")"

expr              = logical_or
logical_or        = logical_and { "||" logical_and }
logical_and       = equality { "&&" equality }
equality          = relational { ("==" | "!=") relational }
relational        = additive { ("<" | ">" | "<=" | ">=") additive }
additive          = multiplicative { ("+" | "-") multiplicative }
multiplicative    = unary { ("*" | "/" | "%") unary }
unary             = [ "!" | "-" | "+" ] primary
primary           = var | constant | call_expr | "(" expr ")"

var               = ID
                  | ID "[" expr "]"
                  | ID "[" expr "]" "[" expr "]"
                  | ID "." ID

call_expr         = ID "(" arg_list_opt ")"
constant          = LITERAL_INTEIRO | LITERAL_REAL | LITERAL_TEXTO | LITERAL_BOOLEANO
```

### 7.3 Precedência de operadores (menor para maior)

1. `||` — OU lógico
2. `&&` — E lógico
3. `==` `!=` — igualdade
4. `<` `>` `<=` `>=` — relacional
5. `+` `-` — aditivo
6. `*` `/` `%` — multiplicativo
7. `!` `-` (unário) — unário
8. Chamada de função, acesso a vetor/campo, parênteses

### 7.4 Tratamento de erro sintático

```c
void yyerror(const char *s) {
    erros_sintaticos++;
    fprintf(stderr, "[ERRO SINTATICO] Linha %d, Coluna %d: %s proximo a '%s'\n",
            linha_atual, coluna_atual, s, yytext);
}
```

**Exemplo:**
```
[ERRO SINTATICO] Linha 4, Coluna 12: syntax error, unexpected IDENTIFICADOR proximo a 'Inteiro'
```

---

## 8. Análise Semântica e Tabela de Símbolos

### 8.1 Arquivo: `tabela/tabela_simbolos.c`

A tabela de símbolos é uma **tabela hash** (`MAX_SYMBOLS = 1024`) com encadeamento para colisões. As chaves são compostas pelo formato `escopo::nome`, garantindo que símbolos homônimos em escopos diferentes não colidam.

### 8.2 Estrutura de escopos

Escopos são gerenciados por uma pilha (`scope_stack`, máximo 64 níveis). Ao entrar em um subprograma, empilha-se seu nome; ao sair, desempilha-se. O escopo `"global"` é empilhado na inicialização.

```c
void scope_push(const char * name, VarType ret_type);
void scope_pop();
ScopeEntry * scope_top();
```

A busca de símbolos percorre a pilha do topo para a base, implementando **escopo estático léxico**:

```c
Symbol * sym_lookup(const char * name);       // busca em todos os escopos
Symbol * sym_lookup_local(const char * name); // busca apenas no escopo atual
```

### 8.3 Estrutura do símbolo

```c
typedef struct Symbol {
    char key[256];            // "escopo::nome"
    char name[256];           // nome do identificador
    char scope[256];          // escopo onde foi declarado
    VarType type;             // tipo semântico (TYPE_INT, TYPE_FLOAT, ...)
    char declared_type[256];  // nome do tipo como declarado ("int", "float", "Pessoa"...)
    int is_function;          // é subprograma?
    int is_const;             // é constante?
    int is_initialized;       // foi inicializado?
    int is_ref;               // é parâmetro por referência?
    int is_array;             // é vetor/matriz?
    int dimensions;           // número de dimensões
    int array_sizes[8];       // tamanho de cada dimensão
    VarType return_type;      // tipo de retorno (se função)
    char return_declared_type[256];
    ParamInfo * params;       // lista de parâmetros (se função)
    int param_count;
    struct Symbol * next;     // encadeamento na hash
} Symbol;
```

### 8.4 Tipos semânticos

```c
typedef enum {
    TYPE_BOOL,
    TYPE_INT,
    TYPE_FLOAT,
    TYPE_STRING,
    TYPE_USER_DEFINED,
    TYPE_VOID,
    TYPE_UNKNOWN
} VarType;
```

### 8.5 Tipos definidos pelo usuário

Registros são armazenados em uma lista encadeada separada (`UserType`), com seus campos (`TypeField`). Aliases são armazenados em outra lista (`TypeAlias`). Consultas:

```c
UserType * user_type_lookup(const char * name);
TypeField * user_type_field_lookup(const char * type_name, const char * field_name);
const char * type_alias_lookup(const char * name);
```

`type_from_string()` resolve automaticamente aliases antes de retornar o `VarType`.

### 8.6 Verificações semânticas realizadas

| Verificação | Quando ocorre |
|---|---|
| Redeclaração de variável/função | `sym_insert` retorna `0` se já existe |
| Variável não declarada | `sym_lookup` retorna `NULL` |
| Tipo incompatível em atribuição | `declared_types_compatible()` |
| Operandos inválidos em operador | `is_numeric_type()` / `is_boolean_type()` |
| Alteração de constante | `sym->is_const` |
| Retorno em procedimento (void) | `scope_top()->return_type == TYPE_VOID` |
| Tipo de retorno incompatível | `declared_types_compatible()` |
| Campo inexistente em registro | `user_type_field_lookup()` retorna `NULL` |
| Acesso a campo em não-registro | `sym->type != TYPE_USER_DEFINED` |
| Índice de vetor não inteiro | `type_from_string(expr.opt1) != TYPE_INT` |
| Índice literal fora dos limites | comparação com `array_sizes[dim]` |
| Acesso como vetor em não-vetor | `sym->is_array == 0` |
| Argumento `ref` não enderecável | `sym_is_addressable_expression()` |
| Número errado de argumentos | contagem em `transform_call_args()` |
| Tipo errado de argumento | `declared_types_compatible()` por posição |
| Tipo recursivo em registro | nome do campo igual ao do tipo pai |
| Condição não booleana | `is_boolean_type()` em `se` e `enquanto` |

### 8.7 Compatibilidade de tipos

```c
int types_compatible(VarType t1, VarType t2);
int declared_types_compatible(const char * type1, const char * type2);
```

Regras:
- Tipos idênticos são sempre compatíveis.
- `Inteiro` e `Real` são compatíveis entre si (coerção numérica).
- Dois tipos `TYPE_USER_DEFINED` diferentes nunca são compatíveis.
- Aliases são resolvidos antes da comparação.

### 8.8 Erros semânticos

```c
void semantic_error(const char *format, ...) {
    erros_semanticos++;
    fprintf(stderr, "[ERRO SEMANTICO] ");
    ...
}
```

**Exemplos:**
```
[ERRO SEMANTICO] Linha 3: tipos incompativeis em 'numero'
[ERRO SEMANTICO] Linha 7: argumento 1 de 'Incrementar' deve ser variavel para ref
[ERRO SEMANTICO] Linha 5: campo 'idade' nao existe em 'Pessoa'
[ERRO SEMANTICO] Linha 2: constante 'LIMITE' nao pode ser alterada
```

---

## 9. Geração de Código C

### 9.1 Estratégia

A geração é **dirigida pela sintaxe**: cada produção da gramática Bison produz diretamente um fragmento de código C, armazenado no campo `code` do registro associado ao não-terminal. A concatenação dos fragmentos forma o código final.

### 9.2 Cabeçalho gerado automaticamente

Todo arquivo C gerado começa com:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static char *edu_concat(const char *a, const char *b) {
    size_t la = strlen(a), lb = strlen(b);
    char *out = malloc(la + lb + 1);
    if (!out) exit(1);
    memcpy(out, a, la);
    memcpy(out + la, b, lb + 1);
    return out;
}
```

`edu_concat` implementa a concatenação de `Texto + Texto`.

### 9.3 Estruturas de controle — tradução para labels e goto

O código gerado **não usa** `if`, `while` ou `for` do C. Todas as estruturas de controle são traduzidas para `goto` e labels, conforme exigido:

**`se/fim_se`:**
```c
if(!(condicao)) goto L1;
// corpo
L1:;
```

**`se/senao/fim_se`:**
```c
if(condicao) goto L1;
goto L2;
L1:;
// ramo verdadeiro
goto L3;
L2:;
// ramo falso
L3:;
```

**`enquanto/fim_enquanto`:**
```c
L1:;
if(!(condicao)) goto L2;
// corpo
goto L1;
L2:;
```

**`repetir/ate`:**
```c
L1:;
// corpo
if(!(condicao)) goto L1;
```

**`para`:**
```c
// init
L1:;
if(!(condicao)) goto L2;
// corpo
// incremento
goto L1;
L2:;
```

### 9.4 Passagem por referência

| Contexto | `.edu` | C gerado |
|---|---|---|
| Assinatura | `ref x: Inteiro` | `int *x` |
| Uso interno | `x = x + 1` | `(*x) = (*x) + 1` |
| Chamada | `f(var)` | `f(&var)` |
| Array como parâmetro | `ref v: Inteiro[]` | `int *v` (decay de array) |

### 9.5 Entrada e saída

```edu
Escrever(expr)           → printf("%d\n", (int)(expr));
                         → printf("%f\n", (float)(expr));
                         → printf("%s\n", expr);
EscreverSemQuebra(expr)  → printf("%d", (int)(expr));
Ler(var)                 → scanf("%d", &var);
```

O formato (`%d`, `%f`, `%s`) é escolhido em tempo de compilação com base no tipo inferido da expressão.

### 9.6 Registros e tipos definidos pelo usuário

```edu
tipo Pessoa inicio
    nome: Texto
    idade: Inteiro
fim
```

Gera:
```c
typedef struct {
    char* nome;
    int idade;
} Pessoa;
```

**Alias:**
```edu
alias Numero = Inteiro
```
Gera:
```c
typedef int Numero;
```

**Enum:**
```edu
enum Cor inicio VERMELHO, VERDE, AZUL fim
```
Gera:
```c
typedef enum {
    VERMELHO,
    VERDE,
    AZUL
} Cor;
```

### 9.7 Módulo de labels: `lib/labels.c`

```c
int new_label();        // retorna próximo inteiro (L1, L2, ...)
char * label_str(int n); // retorna "L42" para n=42
```

Labels são gerados na ordem de visita das produções, garantindo unicidade global no programa.

### 9.8 Módulo record: `lib/record.c`

```c
typedef struct record {
    char * code;   // fragmento de código C
    char * opt1;   // tipo inferido ou metadado auxiliar
} record;

record * createRecord(char * code, char * opt1);
void freeRecord(record * r);
```

Cada não-terminal que produz código carrega um `record *`. O campo `opt1` armazena o tipo declarado da expressão (ex: `"int"`, `"float"`, `"char*"`, `"Pessoa"`), usado nas verificações semânticas.

---

## 10. Testes

### 10.1 Testes positivos

Executados por `make test` (alvo `test-positivos`):

| Arquivo | O que testa |
|---|---|
| `testes/testes.edu` | Cobertura geral: todos os tipos, operadores, laços, funções |
| `testes/registro.edu` | Registros definidos pelo usuário, acesso a campos |
| `testes/quicksort.edu` | Recursão, arrays `ref`, QuickSort completo |
| `testes/recursos_secundarios.edu` | `alias`, `enum`, `para`, matrizes |
| `testes/ref_escalar.edu` | Passagem de escalar por referência |

### 10.2 Testes negativos

Executados por `make test` (alvo `test-negativos`). Cada arquivo **deve** fazer o compilador retornar código `1`:

| Arquivo | Erro esperado |
|---|---|
| `testes/erro_lexico.edu` | Caractere inválido `@` |
| `testes/erro_semantico.edu` | `numero = "texto"` (Inteiro ← Texto) |
| `testes/registroERRO.edu` | Acesso a campo `idade` não declarado em `Pessoa` |
| `testes/quicksortERRO.edu` | Múltiplos erros sintáticos |
| `testes/assinatura_ref_erro.edu` | `Incrementar(x + 1)` — expressão não enderecável para `ref` |
| `testes/chamada_assinatura_erro.edu` | `soma(1, "dois")` — tipo errado no argumento 2 |
| `testes/constante_erro.edu` | `LIMITE = 11` — alteração de constante |
| `testes/vetor_indice_erro.edu` | `numeros[2]` com vetor de tamanho `[2]` |

### 10.3 Teste integrador QuickSort

```bash
make test-quicksort
```

Compila `problemas/problema05.edu`, executa e verifica que a saída é `1 2 3 4 7 8 9 12 `.

### 10.4 Execução dos problemas

```bash
make rodar
```

Executa cada binário com entradas pré-definidas via pipe, produzindo saída visível no terminal.

---

## 11. Exemplos Completos

### 11.1 Olá, Mundo

```edu
procedimento main() inicio
    Escrever("Ola, Mundo!")
fim
```

### 11.2 Fatorial recursivo

```edu
funcao fatorial(n: Inteiro) -> Inteiro inicio
    se (n <= 1) inicio
        retorne 1
    fim_se
    retorne n * fatorial(n - 1)
fim

procedimento main() inicio
    Escrever(fatorial(10))
fim
```

### 11.3 QuickSort com passagem por referência

```edu
procedimento Trocar(ref vetor: Inteiro[], i: Inteiro, j: Inteiro) inicio
    aux: Inteiro = vetor[i]
    vetor[i] = vetor[j]
    vetor[j] = aux
fim

funcao Particionar(ref vetor: Inteiro[], ini: Inteiro, fim_v: Inteiro) -> Inteiro inicio
    pivo: Inteiro = vetor[fim_v]
    i: Inteiro = ini - 1
    j: Inteiro = ini
    enquanto (j < fim_v) inicio
        se (vetor[j] <= pivo) inicio
            i = i + 1
            Trocar(vetor, i, j)
        fim_se
        j = j + 1
    fim_enquanto
    Trocar(vetor, i + 1, fim_v)
    retorne i + 1
fim

procedimento QuickSort(ref vetor: Inteiro[], ini: Inteiro, fim_v: Inteiro) inicio
    se (ini < fim_v) inicio
        pivo: Inteiro = Particionar(vetor, ini, fim_v)
        QuickSort(vetor, ini, pivo - 1)
        QuickSort(vetor, pivo + 1, fim_v)
    fim_se
fim

procedimento main() inicio
    numeros: Inteiro[5]
    numeros[0] = 3
    numeros[1] = 1
    numeros[2] = 4
    numeros[3] = 1
    numeros[4] = 5
    QuickSort(numeros, 0, 4)
    cont: Inteiro = 0
    enquanto (cont < 5) inicio
        EscreverSemQuebra(numeros[cont])
        EscreverSemQuebra(" ")
        cont = cont + 1
    fim_enquanto
    Escrever("")
fim
```

### 11.4 Registro com função construtora

```edu
tipo Pessoa inicio
    nome: Texto
    idade: Inteiro
fim

funcao criar(nome: Texto, idade: Inteiro) -> Pessoa inicio
    p: Pessoa
    p.nome = nome
    p.idade = idade
    retorne p
fim

procedimento main() inicio
    aluno: Pessoa = criar("Ana", 20)
    Escrever(aluno.nome)
    Escrever(aluno.idade)
fim
```

### 11.5 alias, enum e para

```edu
alias Numero = Inteiro

enum Cor inicio
    VERMELHO,
    VERDE,
    AZUL
fim

procedimento main() inicio
    soma: Numero = 0
    i: Inteiro = 0
    para (i = 0; i < 5; i = i + 1) inicio
        soma = soma + i
    fim_para
    Escrever(soma)
fim
```

---

## 12. Limitações Conhecidas

As limitações abaixo refletem o escopo atual da implementação e são candidatas a trabalho futuro:

**Escopo de blocos:** A pilha de escopos é alterada apenas ao entrar/sair de subprogramas. Blocos de `se`, `senao` e laços não criam escopos próprios. Variáveis declaradas nesses blocos ficam no escopo da função.

**Tipo `Nulo`:** Especificado nas diretrizes do projeto, mas ainda não implementado como token, tipo semântico ou valor padrão de inicialização.

**Inicialização implícita:** Variáveis declaradas sem valor inicial tornam-se variáveis C não inicializadas, podendo conter valor indeterminado em tempo de execução.

**Matrizes em parâmetros:** Apenas matrizes unidimensionais (`[]`) são suportadas como parâmetro. Matrizes bidimensionais precisam ser linearizadas manualmente pelo programador.

**Conflitos Bison:** Há quatro conflitos shift/reduce relacionados ao terminador opcional `;`. Resolvidos por padrão pelo Bison (shift), sem impacto funcional nos programas testados.

**Verificação de retorno:** Não é verificado se funções retornam um valor em todos os caminhos de execução.

**Divisão por zero e overflow:** Não há verificação em tempo de execução. O programa será encerrado pelo sistema operacional com comportamento indefinido (herdado do C).

---

## 13. Referências

- AHO, Alfred V.; LAM, Monica S.; SETHI, Ravi; ULLMAN, Jeffrey D. **Compiladores: Princípios, Técnicas e Ferramentas**. 2ª ed. Pearson, 2008. *(Livro do Dragão)*
- SEBESTA, Robert W. **Conceitos de Linguagens de Programação**. 11ª ed. Bookman, 2018.
- [Manual do Bison — GNU Project](https://www.gnu.org/software/bison/manual/)
- [Manual do Flex — GNU Project](https://www.gnu.org/software/flex/manual/)
- Disciplina DIM0548 — Engenharia de Linguagens, UFRN

---

*Documentação gerada com base no estado do repositório em junho de 2026.*
