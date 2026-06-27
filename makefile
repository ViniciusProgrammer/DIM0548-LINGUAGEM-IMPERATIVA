CC     = gcc
CFLAGS = -Wall -Wno-unused-function -Wno-discarded-qualifiers

COMPILER = ./compiler

LEXER_SRC  = src/lexer.l
PARSER_SRC = src/parser.y
LEXER_OUT  = src/lex.yy.c
PARSER_OUT = src/y.tab.c

TABELA_SRC = tabela/tabela_simbolos.c
LABELS_SRC = lib/labels.c
RECORD_SRC = lib/record.c

# ── Build do compilador ──────────────────────────────────────────
all: compiler

compiler: $(LEXER_OUT) $(PARSER_OUT)
	$(CC) $(CFLAGS) \
	    $(LEXER_OUT) $(PARSER_OUT) \
	    $(TABELA_SRC) $(LABELS_SRC) $(RECORD_SRC) \
	    -o compiler

$(LEXER_OUT): $(LEXER_SRC)
	flex -o $(LEXER_OUT) $(LEXER_SRC)

$(PARSER_OUT): $(PARSER_SRC)
	bison -d $(PARSER_SRC) -o $(PARSER_OUT)

# ── Compilar todos os problemas ──────────────────────────────────
problemas: compiler p1 p2 p3 p4 p5 p6

p1: problemas/problema01.edu
	@echo "\n=== Compilando Problema 1 ==="
	$(COMPILER) problemas/problema01.edu saidas/p1.c
	$(CC) saidas/p1.c -o saidas/p1

p2: problemas/problema02.edu
	@echo "\n=== Compilando Problema 2 ==="
	$(COMPILER) problemas/problema02.edu saidas/p2.c
	$(CC) saidas/p2.c -o saidas/p2

p3: compiler problemas/problema03.edu | saidas/
	@echo "\n=== Compilando Problema 3 ==="
	$(COMPILER) problemas/problema03.edu saidas/p3.c
	$(CC) saidas/p3.c -o saidas/p3

p4: problemas/problema4.edu
	@echo "\n=== Compilando Problema 4 ==="
	$(COMPILER) problemas/problema4.edu saidas/p4.c
	$(CC) saidas/p4.c -o saidas/p4

p5: problemas/problema5.edu
	@echo "\n=== Compilando Problema 5 ==="
	$(COMPILER) problemas/problema5.edu saidas/p5.c
	$(CC) saidas/p5.c -o saidas/p5

p6: problemas/problema6.edu
	@echo "\n=== Compilando Problema 6 ==="
	$(COMPILER) problemas/problema6.edu saidas/p6.c
	$(CC) saidas/p6.c -o saidas/p6

# ── Rodar todos os problemas ─────────────────────────────────────
rodar: problemas
	@echo "\n=============================="
	@echo "=== Rodando Problema 1      ==="
	@echo "=============================="
	saidas/p1

	@echo "\n=============================="
	@echo "=== Rodando Problema 2      ==="
	@echo "=============================="
	@echo "10 30 60 80 -1" | saidas/p2

	@echo "\n=============================="
	@echo "=== Rodando Problema 3      ==="
	@echo "=============================="
	@echo "2 2 1 2 3 4 2 2 1 2 3 4" | saidas/p3

	@echo "\n=============================="
	@echo "=== Rodando Problema 4      ==="
	@echo "=============================="
	saidas/p4

	@echo "\n=============================="
	@echo "=== Rodando Problema 5      ==="
	@echo "=============================="
	@echo "12 8" | saidas/p5

	@echo "\n=============================="
	@echo "=== Rodando Problema 6      ==="
	@echo "=============================="
	@echo "5 10 5 15 3 12" | saidas/p6

# ── Limpeza ──────────────────────────────────────────────────────
clean:
	rm -rf src/lex.yy.c src/y.tab.* compiler saidas/*.c saidas/p* y.output

clean_all: clean
	rm -rf saidas/

# ── Criar pasta saidas se nao existir ────────────────────────────
saidas/:
	mkdir -p saidas

.PHONY: all compiler problemas p1 p2 p3 p4 p5 p6 rodar clean clean_all
