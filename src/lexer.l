%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include "y.tab.h"

  int linha_atual  = 1;
  int coluna_atual = 1;

  /* Retorna token simples (sem valor semântico) e atualiza coluna */
  #define RETORNA(token) \
    do { \
      coluna_atual += yyleng; \
      return token; \
    } while(0)

  /* Retorna token com valor de string (para IDENTIFICADOR, literais e tipos) */
  #define RETORNA_STR(token) \
    do { \
      yylval.sValue = strdup(yytext); \
      coluna_atual += yyleng; \
      return token; \
    } while(0)
%}

%option nounput noinput

 /* ── Definições ── */
ESPACO      [ \t\r]+
DIGITO      [0-9]
LETRA       [a-zA-Z_]
ID          {LETRA}({LETRA}|{DIGITO})*
INTEIRO     {DIGITO}+
REAL        {DIGITO}+"."{DIGITO}+
TEXTO       \"([^\\\"\n]|\\.)*\"

%%

 /* ── Espaços ── */
{ESPACO}    { coluna_atual += yyleng; }
"\n"        { linha_atual++; coluna_atual = 1; }

 /* ── Comentários de linha ── */
\/\/.*      { coluna_atual += yyleng; }

 /* ── Comentários de bloco ── */
\/\*([^*]|(\*+[^*/]))*\*+\/ {
    for (int i = 0; yytext[i] != '\0'; i++) {
        if (yytext[i] == '\n') { linha_atual++; coluna_atual = 1; }
        else coluna_atual++;
    }
}

 /* ── Palavras Reservadas ── */
"main"          { RETORNA(MAIN); }
"EscreverSemQuebra" { RETORNA(ESCREVER_SEM_QUEBRA); }
"Escrever"      { RETORNA(ESCREVER); }
"Ler"           { RETORNA(LER); }
"se"            { RETORNA(SE); }
"senao"         { RETORNA(SENAO); }
"fim_se"        { RETORNA(FIM_SE); }
"enquanto"      { RETORNA(ENQUANTO); }
"fim_enquanto"  { RETORNA(FIM_ENQUANTO); }
"repetir"       { RETORNA(REPETIR); }
"ate"           { RETORNA(ATE); }
"inicio"        { RETORNA(INICIO); }
"fim"           { RETORNA(FIM); }
"procedimento"  { RETORNA(PROCEDIMENTO); }
"funcao"        { RETORNA(FUNCAO); }
"retorne"       { RETORNA(RETORNE); }
"ref"           { RETORNA(MODIFICADOR_REF); }
"Constante"     { RETORNA(CONSTANTE); }

 /* ── Tipos Primitivos (carregam valor para o parser usar) ── */
"Inteiro"       { RETORNA_STR(TIPO_INTEIRO); }
"Real"          { RETORNA_STR(TIPO_REAL); }
"Texto"         { RETORNA_STR(TIPO_TEXTO); }
"Booleano"      { RETORNA_STR(TIPO_BOOLEANO); }

 /* ── Literais (carregam valor) ── */
"Verdadeiro"    { yylval.sValue = strdup("1"); coluna_atual += yyleng; return LITERAL_BOOLEANO; }
"Falso"         { yylval.sValue = strdup("0"); coluna_atual += yyleng; return LITERAL_BOOLEANO; }
{REAL}          { RETORNA_STR(LITERAL_REAL); }
{INTEIRO}       { RETORNA_STR(LITERAL_INTEIRO); }
{TEXTO}         { RETORNA_STR(LITERAL_TEXTO); }

 /* ── Operadores compostos ANTES dos simples (ordem importa no flex) ── */
"=="            { RETORNA(OP_IGUAL); }
"!="            { RETORNA(OP_DIFERENTE); }
">="            { RETORNA(OP_MAIOR_IGUAL); }
"<="            { RETORNA(OP_MENOR_IGUAL); }
"&&"            { RETORNA(OP_LOGICO_E); }
"||"            { RETORNA(OP_LOGICO_OU); }
"->"            { RETORNA(SETA_RETORNO); }
"+="            { RETORNA(OP_ATRIB_SOMA); }
"-="            { RETORNA(OP_ATRIB_SUB); }
"*="            { RETORNA(OP_ATRIB_MUL); }
"/="            { RETORNA(OP_ATRIB_DIV); }

 /* ── Operadores simples ── */
"+"             { RETORNA(OP_SOMA); }
"-"             { RETORNA(OP_SUBTRACAO); }
"*"             { RETORNA(OP_MULTIPLICACAO); }
"/"             { RETORNA(OP_DIVISAO); }
"%"             { RETORNA(OP_MODULO); }
"="             { RETORNA(SINAL_IGUALDADE); }
">"             { RETORNA(OP_MAIOR); }
"<"             { RETORNA(OP_MENOR); }
"!"             { RETORNA(OP_LOGICO_NAO); }

 /* ── Delimitadores ── */
";"             { RETORNA(PONTO_E_VIRGULA); }
","             { RETORNA(VIRGULA); }
":"             { RETORNA(DOIS_PONTOS); }
"("             { RETORNA(ABRE_PARENTESES); }
")"             { RETORNA(FECHA_PARENTESES); }
"["             { RETORNA(ABRE_COLCHETES); }
"]"             { RETORNA(FECHA_COLCHETES); }
"."             { RETORNA(PONTO); }
 /* ── Identificadores (carregam valor) — APÓS todas as palavras reservadas ── */
{ID}            { RETORNA_STR(IDENTIFICADOR); }

 /* ── Erro léxico ── */
.               {
    fprintf(stderr, "[ERRO L%d:C%d] Caractere invalido: '%s'\n",
            linha_atual, coluna_atual, yytext);
    coluna_atual++;
}

%%

int yywrap(void) { return 1; }
