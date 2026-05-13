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
"entao"             { printf("ENTAO\n"); }
"senao"             { printf("SENAO\n"); }
"fim_se"            { printf("FIM_SE\n"); }
"enquanto"          { printf("ENQUANTO\n"); }
"faca"              { printf("FACA\n"); }
"fim_enquanto"      { printf("FIM_ENQUANTO\n"); }
"repetir"           { printf("REPETIR\n"); }
"ate"               { printf("ATE\n"); }
"inicio"            { printf("INICIO\n"); }
"fim"               { printf("FIM\n"); }
"procedimento"      { printf("PROCEDIMENTO\n"); }
"funcao"            { printf("FUNCAO\n"); }
"retorne"           { printf("RETORNE\n"); }
.                   {printf("Charactere Invalido.\n");}

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

 /* Identificadores */
{ID}                { printf("IDENTIFICADOR(%s)\n", yytext); }


%%

#ifndef yywrap
int yywrap(void) { return 1; }
#endif

int main(void) {
    yylex();
    return 0;
}