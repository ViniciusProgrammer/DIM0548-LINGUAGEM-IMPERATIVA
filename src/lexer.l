%{
  #include <stdio.h>
  #include "y.tab.h" // Arquivo gerado pelo Bison com a lista de tokens

  int linha_atual  = 1;
  int coluna_atual = 1;

  /* Atualiza a coluna e retorna o token para o Bison */
  #define RETORNA(token) \
    do { \
      coluna_atual += yyleng; \
      return token; \
    } while(0)
%}

%option nounput noinput

 /* Definições */
ESPACO      [ \t\r]+
DIGITO      [0-9]
LETRA       [a-zA-Z]
ID          {LETRA}({LETRA}|{DIGITO}|_)*
INTEIRO     {DIGITO}+
REAL        {DIGITO}+"."{DIGITO}+
TEXTO       \"([^\\\"\n]|\\.)*\"

%%

 /* ---- Espaços ---- */
{ESPACO}            { coluna_atual += yyleng; }
"\n"                { linha_atual++; coluna_atual = 1; }

 /* ---- Comentários ---- */
\/\/.* { 
    coluna_atual += yyleng; 
}
\/\*([^*]|(\*+[^*\/]))*\*+\/ { 
    for(int i = 0; yytext[i] != '\0'; i++) {
        if(yytext[i] == '\n') {
            linha_atual++;
            coluna_atual = 1;
        } else {
            coluna_atual++;
        }
    }
}

 /* ---- Palavras Reservadas ---- */
"main"          { RETORNA(MAIN); }
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

 /* ---- Tipos Primitivos ---- */
"Inteiro"       { RETORNA(TIPO_INTEIRO); }
"Real"          { RETORNA(TIPO_REAL); }
"Texto"         { RETORNA(TIPO_TEXTO); }
"Booleano"      { RETORNA(TIPO_BOOLEANO); }
"Constante"     { RETORNA(CONSTANTE); }

 /* ---- Literais ---- */
"Verdadeiro"    { RETORNA(LITERAL_BOOLEANO); }
"Falso"         { RETORNA(LITERAL_BOOLEANO); }
{REAL}          { RETORNA(LITERAL_REAL); }
{INTEIRO}       { RETORNA(LITERAL_INTEIRO); }
{TEXTO}         { RETORNA(LITERAL_TEXTO); }

 /* ---- Operadores e Pontuação ---- */
"+"             { RETORNA(OP_SOMA); }
"-"             { RETORNA(OP_SUBTRACAO); }
"*"             { RETORNA(OP_MULTIPLICACAO); }
"/"             { RETORNA(OP_DIVISAO); }
"%"             { RETORNA(OP_MODULO); }
"="             { RETORNA(SINAL_IGUALDADE); }
">"             { RETORNA(OP_MAIOR); }
"<"             { RETORNA(OP_MENOR); }
"&&"            { RETORNA(OP_LOGICO_E); }
"||"            { RETORNA(OP_LOGICO_OU); }
"!"             { RETORNA(OP_LOGICO_NAO); }
"=="            { RETORNA(OP_IGUAL); }
"!="            { RETORNA(OP_DIFERENTE); }
">="            { RETORNA(OP_MAIOR_IGUAL); }
"<="            { RETORNA(OP_MENOR_IGUAL); }
"->"            { RETORNA(SETA_RETORNO); }
"+="            { RETORNA(OP_ATRIB_SOMA); }
"-="            { RETORNA(OP_ATRIB_SUB); }
"*="            { RETORNA(OP_ATRIB_MUL); }
"/="            { RETORNA(OP_ATRIB_DIV); }

 /* ---- Delimitadores ---- */
";"             { RETORNA(PONTO_E_VIRGULA); }
","             { RETORNA(VIRGULA); }
":"             { RETORNA(DOIS_PONTOS); }
"("             { RETORNA(ABRE_PARENTESES); }
")"             { RETORNA(FECHA_PARENTESES); }
"["             { RETORNA(ABRE_COLCHETES); }
"]"             { RETORNA(FECHA_COLCHETES); }
"{"             { RETORNA(ABRE_CHAVES); }
"}"             { RETORNA(FECHA_CHAVES); }

 /* ---- Identificadores ---- */
{ID}            { RETORNA(IDENTIFICADOR); }

 /* ---- Erro léxico ---- */
.               {
    fprintf(stderr, "[ERRO L%d:C%d] Caractere invalido: '%s'\n",
            linha_atual, coluna_atual, yytext);
    coluna_atual++;
}

%%