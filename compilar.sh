#!/bin/bash

flex -o src/lex.yy.c src/lexer.l

gcc src/lex.yy.c -o analisador_lexico

echo "3. Compilacao concluida com sucesso!"