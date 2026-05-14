%{
  #include <stdio.h>

  int linha_atual  = 1;
  int coluna_atual = 1;
  int total_tokens = 0;
  int total_erros  = 0;

  #define ATUALIZA_COLUNA() coluna_atual += yyleng
  /* Emite token com posição e incrementa contador */
  #define TOKEN(nome, fmt, ...) \
    do { \
      printf("[L%d:C%d] " nome fmt "\n", linha_atual, coluna_atual, ##__VA_ARGS__); \
      coluna_atual += yyleng; \
      total_tokens++; \
    } while(0)
%}

ESPACO      [ \t\r]+
DIGITO      [0-9]
LETRA       [a-zA-Z]
ID          {LETRA}({LETRA}|{DIGITO}|_)*
INTEIRO     {DIGITO}+
REAL        {DIGITO}+"."{DIGITO}+
TEXTO       \"([^\\\"\n]|\\.)*\"

%%

{ESPACO}            { coluna_atual += yyleng; }
"\n"                { linha_atual++; coluna_atual = 1; }


\/\/.* {
    coluna_atual += yyleng;
}
"/*" {
    int c, prev = 0;
    coluna_atual += 2;
    while ((c = input()) != EOF) {
        if (c == '\n') { linha_atual++; coluna_atual = 1; }
        else            { coluna_atual++; }
        if (prev == '*' && c == '/') break;
        prev = c;
    }
}

"se"            { TOKEN("SE", ""); }
"senao"         { TOKEN("SENAO", ""); }
"fim_se"        { TOKEN("FIM_SE", ""); }
"enquanto"      { TOKEN("ENQUANTO", ""); }
"fim_enquanto"  { TOKEN("FIM_ENQUANTO", ""); }
"repetir"       { TOKEN("REPETIR", ""); }
"ate"           { TOKEN("ATE", ""); }
"inicio"        { TOKEN("INICIO", ""); }
"fim"           { TOKEN("FIM", ""); }
"procedimento"  { TOKEN("PROCEDIMENTO", ""); }
"funcao"        { TOKEN("FUNCAO", ""); }

"retorne"       { TOKEN("RETORNE", ""); }
"retornar"      {
    fprintf(stderr, "[AVISO L%d:C%d] 'retornar' e forma deprecada; use 'retorne'\n",
            linha_atual, coluna_atual);
    TOKEN("RETORNE", " /* depreciado: retornar */");
}

"ref"           { TOKEN("MODIFICADOR_REF", ""); }

"Inteiro"       { TOKEN("TIPO_INTEIRO", ""); }
"Real"          { TOKEN("TIPO_REAL", ""); }
"Texto"         { TOKEN("TIPO_TEXTO", ""); }
"Booleano"      { TOKEN("TIPO_BOOLEANO", ""); }

"Constante"     { TOKEN("CONSTANTE", ""); }
"constante"     {
    fprintf(stderr, "[AVISO L%d:C%d] Prefira 'Constante' (com maiuscula) para consistencia com outros tipos\n",
            linha_atual, coluna_atual);
    TOKEN("CONSTANTE", " /* convencao: use Constante */");
}

"Verdadeiro"    { TOKEN("LITERAL_BOOLEANO", "(%s)", yytext); }
"Falso"         { TOKEN("LITERAL_BOOLEANO", "(%s)", yytext); }
{REAL}          { TOKEN("LITERAL_REAL",     "(%s)", yytext); }
{INTEIRO}       { TOKEN("LITERAL_INTEIRO",  "(%s)", yytext); }
{TEXTO}         { TOKEN("LITERAL_TEXTO",    "(%s)", yytext); }

"=="            { TOKEN("OP_IGUAL", ""); }
"!="            { TOKEN("OP_DIFERENTE", ""); }
">="            { TOKEN("OP_MAIOR_IGUAL", ""); }
"<="            { TOKEN("OP_MENOR_IGUAL", ""); }
"->"            { TOKEN("SETA_RETORNO", ""); }

"+="            { TOKEN("OP_ATRIB_SOMA", ""); }
"-="            { TOKEN("OP_ATRIB_SUB", ""); }
"*="            { TOKEN("OP_ATRIB_MUL", ""); }
"/="            { TOKEN("OP_ATRIB_DIV", ""); }

"+"             { TOKEN("OP_SOMA", ""); }
"-"             { TOKEN("OP_SUBTRACAO", ""); }
"*"             { TOKEN("OP_MULTIPLICACAO", ""); }
"/"             { TOKEN("OP_DIVISAO", ""); }
"%"             { TOKEN("OP_MODULO", ""); }   /* existia no original mas não documentado */
"="             { TOKEN("SINAL_IGUALDADE", ""); }
">"             { TOKEN("OP_MAIOR", ""); }
"<"             { TOKEN("OP_MENOR", ""); }
"&&"            { TOKEN("OP_LOGICO_E", ""); }
"||"            { TOKEN("OP_LOGICO_OU", ""); }
"!"             { TOKEN("OP_LOGICO_NAO", ""); }

";"             { TOKEN("PONTO_E_VIRGULA", ""); }
","             { TOKEN("VIRGULA", ""); }
":"             { TOKEN("DOIS_PONTOS", ""); }
"("             { TOKEN("ABRE_PARENTESES", ""); }
")"             { TOKEN("FECHA_PARENTESES", ""); }
"["             { TOKEN("ABRE_COLCHETES", ""); }
"]"             { TOKEN("FECHA_COLCHETES", ""); }
"{"             { TOKEN("ABRE_CHAVES", ""); }
"}"             { TOKEN("FECHA_CHAVES", ""); }

{ID}            { TOKEN("IDENTIFICADOR", "(%s)", yytext); }

.               {
    fprintf(stderr, "[ERRO L%d:C%d] Caractere invalido: '%s'\n",
            linha_atual, coluna_atual, yytext);
    coluna_atual++;
    total_erros++;
}

%%

#ifndef yywrap
int yywrap(void) { return 1; }
#endif

int main(void) {
    yylex();

    printf("\n--- Analise concluida ---\n");
    printf("Linhas processadas : %d\n", linha_atual);
    printf("Tokens reconhecidos: %d\n", total_tokens);
    if (total_erros > 0)
        fprintf(stderr, "Erros lexicos      : %d\n", total_erros);
    else
        printf("Erros lexicos      : 0\n");

    return (total_erros > 0) ? 1 : 0;
}
