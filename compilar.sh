#!/bin/bash
# compilar.sh — Script de build do analisador lexico da linguagem .edu
# Uso: chmod +x compilar.sh && ./compilar.sh

set -e  # Interrompe imediatamente se qualquer comando falhar

LEXER_SRC="src/lexer.l"
LEXER_OUT="src/lex.yy.c"
EXECUTAVEL="analisador_lexico"

echo "Gerando codigo C a partir das regras Flex..."
flex -o "$LEXER_OUT" "$LEXER_SRC"

echo "Compilando com GCC..."
# -lfl: linka a biblioteca do Flex (necessaria em algumas distribuicoes Linux)
# -Wall: ativa todos os avisos de compilacao
gcc -Wall "$LEXER_OUT" -o "$EXECUTAVEL" -lfl

echo "Compilacao concluida com sucesso! Executavel: ./$EXECUTAVEL"
echo ""
echo "Exemplos de uso:"
echo "  ./$EXECUTAVEL < testes/quicksort.edu"
echo "  ./$EXECUTAVEL < testes/testes.edu"
