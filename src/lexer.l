%{
  #include <stdio.h>  
%}

%%

/* Espaços e /n */
{ESPACO}            { /* Ignora espaços e tabs */ }
"\n"                { linha_atual++; /* Conta quebras de linha */ }

/* Comentários */
"//".*              { printf("COMENTARIO_LINHA_IGNORADO\n"); }
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

%%

#ifndef yywrap
int yywrap(void) { return 1; }
#endif