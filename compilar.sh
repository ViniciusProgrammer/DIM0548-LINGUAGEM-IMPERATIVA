#!/bin/bash
# compilar.sh — Script de build do compilador da linguagem .edu
# Uso: chmod +x compilar.sh && ./compilar.sh

set -e

LEXER_SRC="src/lexer.l"
PARSER_SRC="src/parser.y"
LEXER_OUT="src/lex.yy.c"
PARSER_OUT_C="src/y.tab.c"
PARSER_OUT_H="src/y.tab.h"
EXECUTAVEL="compiler"

TABELA_SRC="tabela/tabela_simbolos.c"
LABELS_SRC="lib/labels.c"
RECORD_SRC="lib/record.c"

echo "Gerando Parser (Bison)..."
bison -d "$PARSER_SRC" -o "$PARSER_OUT_C"

echo "Gerando Lexer (Flex)..."
flex -o "$LEXER_OUT" "$LEXER_SRC"

echo "Compilando com GCC..."
gcc -Wall -Wno-discarded-qualifiers \
    "$LEXER_OUT" \
    "$PARSER_OUT_C" \
    "$TABELA_SRC" \
    "$LABELS_SRC" \
    "$RECORD_SRC" \
    -o "$EXECUTAVEL"

echo "Compilacao concluida! Executavel: ./$EXECUTAVEL"
echo ""
echo "Exemplos de uso:"
echo "  ./$EXECUTAVEL testes/quicksort.edu saida.c"
echo "  ./$EXECUTAVEL testes/testes.edu saida.c"
echo ""
echo "Para compilar e rodar o codigo gerado:"
echo "  gcc saida.c -o prog && ./prog"