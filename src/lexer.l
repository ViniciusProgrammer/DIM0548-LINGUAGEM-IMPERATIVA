%{
  #include <stdio.h>  

  int linha_atual = 1;
%}

 /* Definições */
ESPACO      [ \t\r]+
DIGITO      [0-9]
LETRA       [a-zA-Z]
ID          {LETRA}({LETRA}|{DIGITO}|_)*
INTEIRO     {DIGITO}+
REAL        {DIGITO}+"."{DIGITO}+
TEXTO       \"([^\\\"]|\\.)*\"

%%

 /* Espaços e /n */
{ESPACO}            { /* Ignora espaços e tabs */ }
"\n"                { linha_atual++; /* Conta quebras de linha */ }

 /* Comentários */
\/\/.* { printf("COMENTARIO_LINHA_IGNORADO\n"); }
"/*"([^*]|(\*+[^*/]))*\*+"/" { printf("COMENTARIO_BLOCO_IGNORADO\n"); }

 /* Palavras Reservadas */
"se"                { printf("SE\n"); }
"senao"             { printf("SENAO\n"); }
"fim_se"            { printf("FIM_SE\n"); }
"enquanto"          { printf("ENQUANTO\n"); }
"fim_enquanto"      { printf("FIM_ENQUANTO\n"); }
"repetir"           { printf("REPETIR\n"); }
"ate"               { printf("ATE\n"); }
"inicio"            { printf("INICIO\n"); }
"fim"               { printf("FIM\n"); }
"procedimento"      { printf("PROCEDIMENTO\n"); }
"funcao"            { printf("FUNCAO\n"); }
"retorne"           { printf("RETORNE\n"); }
"ref"               { printf("MODIFICADOR_REF\n"); }

 /* Tipos Primitivos */
"Inteiro"           { printf("TIPO_INTEIRO\n"); }
"Real"              { printf("TIPO_REAL\n"); }
"Texto"             { printf("TIPO_TEXTO\n"); }
"Booleano"          { printf("TIPO_BOOLEANO\n"); }
"constante"         { printf("CONSTANTE\n"); }

 /* Literais */
"Verdadeiro"        { printf("LITERAL_BOOLEANO(Verdadeiro)\n"); }
"Falso"             { printf("LITERAL_BOOLEANO(Falso)\n"); }
{REAL}              { printf("LITERAL_REAL(%s)\n", yytext); }
{INTEIRO}           { printf("LITERAL_INTEIRO(%s)\n", yytext); }
{TEXTO}             { printf("LITERAL_TEXTO(%s)\n", yytext); }

 /* Operadores e Pontuação */
"+"                 { printf("OP_SOMA\n"); }
"-"                 { printf("OP_SUBTRACAO\n"); }
"*"                 { printf("OP_MULTIPLICACAO\n"); }
"/"                 { printf("OP_DIVISAO\n"); }
"="                 { printf("SINAL_IGUALDADE\n"); }
"=="                { printf("OP_IGUAL\n"); }
"&&"                { printf("OP_LOGICO_E\n"); }
"||"                { printf("OP_LOGICO_OU\n"); }
"!"                 { printf("OP_LOGICO_NAO\n"); }
"!="                { printf("OP_DIFERENTE\n"); }
">"                 { printf("OP_MAIOR\n"); }
"<"                 { printf("OP_MENOR\n"); }
">="                { printf("OP_MAIOR_IGUAL\n"); }
"<="                { printf("OP_MENOR_IGUAL\n"); }
";"                 { printf("PONTO_E_VIRGULA\n"); }
","                 { printf("VIRGULA\n"); }
":"                 { printf("DOIS_PONTOS\n"); }
"->"                { printf("SETA_RETORNO\n"); }
"("                 { printf("ABRE_PARENTESES\n"); }
")"                 { printf("FECHA_PARENTESES\n"); }
"["                 { printf("ABRE_COLCHETES\n"); }
"]"                 { printf("FECHA_COLCHETES\n"); }
"{"                 { printf("ABRE_CHAVES\n"); }
"}"                 { printf("FECHA_CHAVES\n"); }

 /* Identificadores */
{ID}                { printf("IDENTIFICADOR(%s)\n", yytext); }

 /* Charactere Invalido */
.                   {printf("Charactere Invalido.\n");}

%%

#ifndef yywrap
int yywrap(void) { return 1; }
#endif

int main(void) {
    yylex();
    return 0;
}