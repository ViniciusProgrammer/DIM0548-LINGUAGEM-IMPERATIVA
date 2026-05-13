#!/bin/bash

flex -o src/lex.yy.c src/lexer.l

gcc src/lex.yy.c src/main.c -o analisador_lexico