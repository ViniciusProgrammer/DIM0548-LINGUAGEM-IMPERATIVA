%{
#include <stdio.h>
#include <stdlib.h>

/* Funcoes e variaveis exportadas pelo Flex */
extern int yylex();
extern int linha_atual;
extern int coluna_atual;
extern char* yytext;

/* Funcao de tratamento de erro do Bison */
void yyerror(const char *s);
%}

/* Declaracao de todos os Tokens */
%token SE SENAO FIM_SE ENQUANTO FIM_ENQUANTO REPETIR ATE INICIO FIM
%token PROCEDIMENTO FUNCAO RETORNE MODIFICADOR_REF MAIN
%token TIPO_INTEIRO TIPO_REAL TIPO_TEXTO TIPO_BOOLEANO CONSTANTE
%token LITERAL_BOOLEANO LITERAL_REAL LITERAL_INTEIRO LITERAL_TEXTO
%token OP_SOMA OP_SUBTRACAO OP_MULTIPLICACAO OP_DIVISAO OP_MODULO
%token SINAL_IGUALDADE OP_MAIOR OP_MENOR OP_LOGICO_E OP_LOGICO_OU
%token OP_LOGICO_NAO OP_IGUAL OP_DIFERENTE OP_MAIOR_IGUAL OP_MENOR_IGUAL
%token SETA_RETORNO OP_ATRIB_SOMA OP_ATRIB_SUB OP_ATRIB_MUL OP_ATRIB_DIV
%token PONTO_E_VIRGULA VIRGULA DOIS_PONTOS
%token ABRE_PARENTESES FECHA_PARENTESES ABRE_COLCHETES FECHA_COLCHETES ABRE_CHAVES FECHA_CHAVES
%token IDENTIFICADOR

/* O simbolo inicial da gramatica */
%start program

%%

/* <program> -> { <subprogram> } <main_program> */
program
    : subprograms main_program
    ;

subprograms
    : /* vazio */
    | subprograms subprogram
    ;

/* <main_program> -> procedimento main ( ) inicio <stmts> fim */
main_program
    : PROCEDIMENTO MAIN ABRE_PARENTESES FECHA_PARENTESES INICIO stmts FIM
    ;

/* <subprogram> -> <sub_type> <id> ( [ <param_list> ] ) [ -> <type> ] inicio <stmts> fim */
subprogram
    : sub_type IDENTIFICADOR ABRE_PARENTESES param_list_opt FECHA_PARENTESES return_type_opt INICIO stmts FIM
    ;

sub_type
    : PROCEDIMENTO 
    | FUNCAO
    ;

return_type_opt
    : /* vazio */
    | SETA_RETORNO type
    ;

param_list_opt
    : /* vazio */
    | param_list
    ;

/* <param_list> -> <param> { , <param> } */
param_list
    : param
    | param_list VIRGULA param
    ;

/* <param> -> [ ref ] <id> : <type> [ '[' ']' ] */
param
    : ref_opt IDENTIFICADOR DOIS_PONTOS type array_opt
    ;

ref_opt
    : /* vazio */
    | MODIFICADOR_REF
    ;

array_opt
    : /* vazio */
    | ABRE_COLCHETES FECHA_COLCHETES
    ;

/* <type> -> Inteiro | Real | Texto | Booleano */
type
    : TIPO_INTEIRO 
    | TIPO_REAL 
    | TIPO_TEXTO 
    | TIPO_BOOLEANO
    ;

/* <stmts> -> { <stmt> } */
stmts
    : /* vazio */
    | stmts stmt
    ;

/* <stmt> -> <decl> | <assign> | <call_stmt> | <if_stmt> | <loop_stmt> | <return_stmt> */
stmt
    : decl
    | assign
    | call_stmt
    | if_stmt
    | loop_stmt
    | return_stmt
    ;

/* <decl> -> <id> : <type> [ '[' <constant> ']' ] [ = <expr> ] */
decl
    : IDENTIFICADOR DOIS_PONTOS type array_decl_opt assign_opt
    ;

array_decl_opt
    : /* vazio */
    | ABRE_COLCHETES constant FECHA_COLCHETES
    ;

assign_opt
    : /* vazio */
    | SINAL_IGUALDADE expr
    ;

/* <assign> -> <var> = <expr> */
assign
    : var SINAL_IGUALDADE expr
    ;

/* <call_stmt> -> <id> ( [ <arg_list> ] ) */
call_stmt
    : IDENTIFICADOR ABRE_PARENTESES arg_list_opt FECHA_PARENTESES
    ;

arg_list_opt
    : /* vazio */
    | arg_list
    ;

/* <arg_list> -> <expr> { , <expr> } */
arg_list
    : expr
    | arg_list VIRGULA expr
    ;

/* <if_stmt> -> se ( <expr> ) inicio <stmts> [ senao inicio <stmts> fim ] fim_se */
if_stmt
    : SE ABRE_PARENTESES expr FECHA_PARENTESES INICIO stmts else_opt FIM_SE
    ;

else_opt
    : /* vazio */
    | SENAO INICIO stmts FIM
    ;

/* <loop_stmt> -> enquanto ( <expr> ) inicio <stmts> fim_enquanto */
loop_stmt
    : ENQUANTO ABRE_PARENTESES expr FECHA_PARENTESES INICIO stmts FIM_ENQUANTO
    ;

/* <return_stmt> -> retornar ( <expr> ) */
return_stmt
    : RETORNE ABRE_PARENTESES expr FECHA_PARENTESES
    ;

/* <expr> -> <term> { (+ | - | < | > | <= | >= | == | !=) <term> } */
expr
    : term
    | expr op_rel_arit term
    ;

op_rel_arit
    : OP_SOMA | OP_SUBTRACAO 
    | OP_MENOR | OP_MAIOR | OP_MENOR_IGUAL | OP_MAIOR_IGUAL 
    | OP_IGUAL | OP_DIFERENTE | OP_LOGICO_E | OP_LOGICO_OU
    ;

/* <term> -> <factor> { (* | /) <factor> } */
term
    : factor
    | term op_mult factor
    ;

op_mult
    : OP_MULTIPLICACAO | OP_DIVISAO | OP_MODULO
    ;

/* <factor> -> <var> | <constant> | <call_stmt> | ( <expr> ) */
factor
    : var
    | constant
    | call_stmt
    | ABRE_PARENTESES expr FECHA_PARENTESES
    ;

/* <var> -> <id> [ '[' <expr> ']' ] */
var
    : IDENTIFICADOR
    | IDENTIFICADOR ABRE_COLCHETES expr FECHA_COLCHETES
    ;

/* <constant> -> LITERAL_INTEIRO | LITERAL_REAL | LITERAL_TEXTO | LITERAL_BOOLEANO */
constant
    : LITERAL_INTEIRO
    | LITERAL_REAL
    | LITERAL_TEXTO
    | LITERAL_BOOLEANO
    ;

%%

/* Tratamento de erro padrao do Bison */
void yyerror(const char *s) {
    fprintf(stderr, "[ERRO SINTATICO] Linha %d, Coluna %d: %s proximo a '%s'\n", 
            linha_atual, coluna_atual, s, yytext);
}

int main(void) {
    printf("Iniciando analise sintatica...\n");
    
    if (yyparse() == 0) {
        printf("\n[SUCESSO] Analise sintatica concluida!\n");
    } else {
        printf("\n[FALHA] Foram encontrados erros sintaticos no codigo.\n");
    }
    
    return 0;
}