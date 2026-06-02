#!/bin/bash
# compilar.sh — Script de build do analisador lexico da linguagem .edu
# Uso: chmod +x compilar.sh && ./compilar.sh

set -e  # Interrompe imediatamente se qualquer comando falhar

LEXER_SRC="src/lexer.l"
PARSER_SRC="src/parser.y"
LEXER_OUT="src/lex.yy.c"
PARSER_OUT_C="src/y.tab.c"
PARSER_OUT_H="src/y.tab.h"
EXECUTAVEL="analisador_sintatico"

echo "Gerando Parser (Bison)..."
# A flag -d gera o arquivo de cabeçalho (y.tab.h) que o Flex precisa para conhecer os tokens
bison -d "$PARSER_SRC" -o "$PARSER_OUT_C"

echo "Gerando Lexer (Flex)..."
flex -o "$LEXER_OUT" "$LEXER_SRC"

echo "Compilando com GCC..."
# -lfl: linka a biblioteca do Flex (necessaria em algumas distribuicoes Linux)
# -Wall: ativa todos os avisos de compilacao
gcc -Wall "$LEXER_OUT" "$PARSER_OUT_C" -o "$EXECUTAVEL" -lfl

echo "Compilacao concluida com sucesso! Executavel: ./$EXECUTAVEL"
echo ""
echo "Exemplos de uso:"
echo "  ./$EXECUTAVEL < testes/quicksort.edu"
echo "  ./$EXECUTAVEL < testes/quicksortERRO.edu"
echo "  ./$EXECUTAVEL < testes/testes.edu"
