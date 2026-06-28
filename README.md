# DIM0548-LINGUAGEM-IMPERATIVA

Compilador da linguagem imperativa educacional `.edu`. O projeto usa Flex, Bison e GCC para validar léxico, sintaxe e semântica, gerar C e compilar os programas dos problemas.

## Pré-requisitos

```bash
sudo apt update
sudo apt install flex bison gcc make
```

## Build e Testes

```bash
make              # gera ./compiler
make problemas    # compila os seis programas em problemas/
make test         # executa testes positivos, negativos e QuickSort
make rodar        # executa os binarios gerados dos problemas
make clean        # remove artefatos gerados
```

O compilador recebe entrada e saida C:

```bash
./compiler testes/quicksort.edu /tmp/quicksort.c
gcc /tmp/quicksort.c -o /tmp/quicksort
```

O retorno e `0` em sucesso e `1` quando ha erro lexico, sintatico ou semantico. O arquivo C de saida so e publicado quando todas as analises passam.

## Recursos Implementados

- Seis problemas compilaveis via `make problemas`.
- Testes automatizados positivos e negativos via `make test`.
- Assinaturas completas de subprogramas: quantidade, ordem e tipos dos argumentos.
- Parametros `ref` com geracao de ponteiros, enderecos e desreferencias em C.
- QuickSort no problema 5, validando recursao, vetor como parametro e passagem por referencia.
- Verificacao estatica de operadores, atribuicoes, condicoes, indices, retornos e chamadas.
- Divisao com tipo coerente: `Inteiro / Inteiro` permanece inteiro; operacao com `Real` resulta em real.
- Concatenacao textual com `+` entre dois `Texto`.
- Constantes imutaveis e obrigatoriamente inicializadas.
- Vetores e matrizes com multiplas dimensoes, validacao de tipo de indice e checagem estatica de literais fora dos limites.
- Recursos secundarios: `para`, `alias` e `enum`.

## Sintaxe Adicional

```edu
alias Numero = Inteiro

enum Cor inicio
    VERMELHO,
    VERDE,
    AZUL
fim

procedimento main() inicio
    matriz: Numero[2][3]
    i: Inteiro = 0

    para (i = 0; i < 3; i = i + 1) inicio
        matriz[0][i] = i
    fim_para
fim
```

## Testes Negativos

A pasta `testes/` inclui casos que devem falhar, como erro lexico, erro sintatico, campo inexistente em registro, chamada com tipo errado, argumento `ref` nao enderecavel, alteracao de constante e indice literal fora do limite.
